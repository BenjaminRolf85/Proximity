import 'package:postgres/postgres.dart';

class Database {
  final Connection _connection;

  Database(this._connection);

  static Future<Database> connect({
    required String host,
    required int port,
    required String database,
    required String username,
    required String password,
  }) async {
    final connection = await Connection.open(
      Endpoint(
        host: host,
        database: database,
        port: port,
        username: username,
        password: password,
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );

    return Database(connection);
  }

  Future<void> initialize() async {
    // Create extensions
    await _connection.execute('CREATE EXTENSION IF NOT EXISTS postgis;');
    await _connection.execute('CREATE EXTENSION IF NOT EXISTS "uuid-ossp";');

    // Create users table
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        name VARCHAR(255) NOT NULL,
        avatar_url TEXT,
        bio TEXT,
        created_at TIMESTAMP NOT NULL DEFAULT NOW(),
        last_seen TIMESTAMP
      );
    ''');

    // Create user_locations table with PostGIS
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS user_locations (
        user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
        location GEOGRAPHY(POINT, 4326) NOT NULL,
        accuracy DOUBLE PRECISION,
        updated_at TIMESTAMP NOT NULL DEFAULT NOW()
      );
    ''');

    // Create spatial index for efficient proximity queries
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_user_locations_geography 
      ON user_locations USING GIST(location);
    ''');

    // Create messages table
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        from_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        to_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        text TEXT NOT NULL,
        type VARCHAR(50) NOT NULL DEFAULT 'text',
        created_at TIMESTAMP NOT NULL DEFAULT NOW(),
        is_read BOOLEAN NOT NULL DEFAULT FALSE
      );
    ''');

    // Create indexes for messages
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_messages_from_user 
      ON messages(from_user_id);
    ''');
    
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_messages_to_user 
      ON messages(to_user_id);
    ''');

    // Create groups table
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS groups (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        name VARCHAR(255) NOT NULL,
        type VARCHAR(50) NOT NULL,
        owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        created_at TIMESTAMP NOT NULL DEFAULT NOW()
      );
    ''');

    // Create user_groups junction table
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS user_groups (
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
        joined_at TIMESTAMP NOT NULL DEFAULT NOW(),
        PRIMARY KEY (user_id, group_id)
      );
    ''');

    print('✅ Database initialized successfully');
  }

  Connection get connection => _connection;

  Future<void> close() async {
    await _connection.close();
  }
}

