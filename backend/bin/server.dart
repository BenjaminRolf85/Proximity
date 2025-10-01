import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';
import '../lib/database/database.dart';
import '../lib/services/auth_service.dart';
import '../lib/services/proximity_service.dart';
import '../lib/services/message_service.dart';
import '../lib/services/websocket_service.dart';
import '../lib/middleware/auth_middleware.dart';
import '../lib/routes/auth_routes.dart';
import '../lib/routes/proximity_routes.dart';
import '../lib/routes/message_routes.dart';

void main() async {
  final uuid = const Uuid();

  // Load environment variables
  // Railway uses PGHOST, PGPORT, etc. - support both formats
  final dbHost = Platform.environment['PGHOST'] ?? Platform.environment['DB_HOST'] ?? 'localhost';
  final dbPort = int.parse(Platform.environment['PGPORT'] ?? Platform.environment['DB_PORT'] ?? '5432');
  final dbName = Platform.environment['PGDATABASE'] ?? Platform.environment['DB_NAME'] ?? 'proximity_social';
  final dbUser = Platform.environment['PGUSER'] ?? Platform.environment['DB_USER'] ?? 'postgres';
  final dbPassword = Platform.environment['PGPASSWORD'] ?? Platform.environment['DB_PASSWORD'] ?? 'postgres';
  final serverPort = int.parse(Platform.environment['PORT'] ?? '8080');
  final serverHost = Platform.environment['HOST'] ?? '0.0.0.0';
  final jwtSecret = Platform.environment['JWT_SECRET'] ?? 'development_secret_key_min_32_chars';

  print('🚀 Starting Proximity Social Backend...');

  // Connect to database
  print('📊 Connecting to PostgreSQL...');
  final database = await Database.connect(
    host: dbHost,
    port: dbPort,
    database: dbName,
    username: dbUser,
    password: dbPassword,
  );

  // Initialize database schema
  print('🔧 Initializing database schema...');
  await database.initialize();

  // Initialize services
  final authService = AuthService(database.connection, jwtSecret);
  final proximityService = ProximityService(database.connection);
  final messageService = MessageService(database.connection);
  final wsService = WebSocketService();

  // Setup routes
  final app = Router();

  // Health check
  app.get('/health', (Request request) {
    return Response.ok('OK');
  });

  // Mount API routes
  app.mount('/auth/', AuthRoutes(authService).router.call);
  app.mount('/proximity/', ProximityRoutes(proximityService).router.call);
  app.mount('/messages/', MessageRoutes(messageService, proximityService).router.call);

  // WebSocket endpoint
  app.get('/ws', webSocketHandler((WebSocketChannel webSocket) {
    final connectionId = uuid.v4();
    String? userId;

    webSocket.stream.listen(
      (message) {
        try {
          final data = message as String;
          final json = jsonDecode(data) as Map<String, dynamic>;

          final type = json['type'] as String;

          if (type == 'authenticate') {
            userId = json['userId'] as String;
            wsService.registerConnection(connectionId, userId!, webSocket);
          } else if (type == 'location_update' && userId != null) {
            // Broadcast location update to nearby users
            wsService.broadcastToAll(WebSocketMessage(
              type: WebSocketEventType.locationUpdate,
              data: {
                'userId': userId,
                'latitude': json['latitude'],
                'longitude': json['longitude'],
              },
            ));
          }
        } catch (e) {
          print('WebSocket error: $e');
        }
      },
      onDone: () {
        wsService.removeConnection(connectionId);
      },
      onError: (error) {
        print('WebSocket error: $error');
        wsService.removeConnection(connectionId);
      },
    );
  }));

  // Middleware pipeline
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addMiddleware(authMiddleware(authService))
      .addHandler(app.call);

  // Start server
  final server = await io.serve(handler, serverHost, serverPort);
  
  print('');
  print('✅ Server running on http://${server.address.host}:${server.port}');
  print('📡 WebSocket available at ws://${server.address.host}:${server.port}/ws');
  print('🌍 Active connections: ${wsService.activeUserCount}');
  print('');
  print('API Endpoints:');
  print('  POST   /auth/register');
  print('  POST   /auth/login');
  print('  GET    /auth/me');
  print('  PATCH  /auth/me');
  print('  POST   /proximity/location');
  print('  GET    /proximity/nearby');
  print('  POST   /messages/send');
  print('  POST   /messages/broadcast');
  print('  GET    /health');
  print('');
  print('Press Ctrl+C to stop');

  // Cleanup on exit
  ProcessSignal.sigint.watch().listen((_) async {
    print('\n🛑 Shutting down...');
    await database.close();
    await server.close();
    exit(0);
  });
}

Middleware _corsMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
        });
      }

      final response = await handler(request);
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
      });
    };
  };
}

