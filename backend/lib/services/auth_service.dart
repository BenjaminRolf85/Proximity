import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';

class AuthService {
  final Connection _db;
  final String _jwtSecret;
  final _uuid = const Uuid();

  AuthService(this._db, this._jwtSecret);

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    // Check if user exists
    final existing = await _db.execute(
      Sql.named('SELECT id FROM users WHERE email = @email'),
      parameters: {'email': TypedValue(Type.text, email)},
    );

    if (existing.isNotEmpty) {
      throw Exception('User with this email already exists');
    }

    // Create user
    final userId = _uuid.v4();
    final passwordHash = _hashPassword(password);

    await _db.execute(
      Sql.named('''
      INSERT INTO users (id, email, password_hash, name, created_at)
      VALUES (@id, @email, @password_hash, @name, NOW())
      '''),
      parameters: {
        'id': TypedValue(Type.uuid, userId),
        'email': TypedValue(Type.text, email),
        'password_hash': TypedValue(Type.text, passwordHash),
        'name': TypedValue(Type.text, name),
      },
    );

    // Fetch the created user
    final result = await _db.execute(
      Sql.named('SELECT * FROM users WHERE id = @id'),
      parameters: {'id': TypedValue(Type.uuid, userId)},
    );

    final user = User.fromDb(result.first.toColumnMap());
    final token = _generateToken(userId);

    return {
      'user': user.toJson(),
      'token': token,
    };
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final passwordHash = _hashPassword(password);

    final result = await _db.execute(
      Sql.named('''
      SELECT * FROM users 
      WHERE email = @email AND password_hash = @password_hash
      '''),
      parameters: {
        'email': TypedValue(Type.text, email),
        'password_hash': TypedValue(Type.text, passwordHash),
      },
    );

    if (result.isEmpty) {
      throw Exception('Invalid email or password');
    }

    final user = User.fromDb(result.first.toColumnMap());
    final token = _generateToken(user.id);

    // Update last seen
    await _db.execute(
      Sql.named('UPDATE users SET last_seen = NOW() WHERE id = @id'),
      parameters: {'id': TypedValue(Type.uuid, user.id)},
    );

    return {
      'user': user.toJson(),
      'token': token,
    };
  }

  String _generateToken(String userId) {
    final jwt = JWT(
      {
        'userId': userId,
        'iat': DateTime.now().millisecondsSinceEpoch,
      },
      issuer: 'proximity_social',
    );

    return jwt.sign(SecretKey(_jwtSecret), expiresIn: const Duration(days: 30));
  }

  Future<String?> verifyToken(String token) async {
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      return jwt.payload['userId'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<User?> getUserById(String userId) async {
    final result = await _db.execute(
      Sql.named('SELECT * FROM users WHERE id = @id'),
      parameters: {'id': TypedValue(Type.uuid, userId)},
    );

    if (result.isEmpty) return null;
    return User.fromDb(result.first.toColumnMap());
  }

  Future<void> updateUser({
    required String userId,
    String? name,
    String? avatarUrl,
    String? bio,
  }) async {
    final updates = <String>[];
    final params = <String, TypedValue>{'id': TypedValue(Type.uuid, userId)};

    if (name != null) {
      updates.add('name = @name');
      params['name'] = TypedValue(Type.text, name);
    }
    if (avatarUrl != null) {
      updates.add('avatar_url = @avatar_url');
      params['avatar_url'] = TypedValue(Type.text, avatarUrl);
    }
    if (bio != null) {
      updates.add('bio = @bio');
      params['bio'] = TypedValue(Type.text, bio);
    }

    if (updates.isEmpty) return;

    await _db.execute(
      Sql.named('UPDATE users SET ${updates.join(', ')} WHERE id = @id'),
      parameters: params,
    );
  }
}

