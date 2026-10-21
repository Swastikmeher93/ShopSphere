import 'dart:convert';

import 'package:sqflite/sqflite.dart';

class LocalCartSnapshot {
  const LocalCartSnapshot({required this.cartId, required this.items});

  final int? cartId;
  final List<Map<String, dynamic>> items;
}

/// Stores a separate cart for each signed-in user on this device.
class LocalCartDatabase {
  LocalCartDatabase._();

  static final LocalCartDatabase instance = LocalCartDatabase._();
  static const _databaseName = 'shopesphere.db';
  static const _databaseVersion = 1;

  Future<Database>? _databaseFuture;

  Future<Database> get _database =>
      _databaseFuture ??= _openDatabase();

  Future<Database> _openDatabase() async {
    final path = await getDatabasesPath();
    return openDatabase(
      '$path/$_databaseName',
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE carts (
            user_id INTEGER PRIMARY KEY,
            cart_id INTEGER,
            initialized INTEGER NOT NULL DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE cart_items (
            user_id INTEGER NOT NULL,
            product_id INTEGER NOT NULL,
            quantity INTEGER NOT NULL,
            product_json TEXT NOT NULL,
            PRIMARY KEY (user_id, product_id),
            FOREIGN KEY (user_id) REFERENCES carts(user_id) ON DELETE CASCADE
          )
        ''');
      },
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<LocalCartSnapshot?> readCart(int userId) async {
    final db = await _database;
    final carts = await db.query(
      'carts',
      columns: ['cart_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (carts.isEmpty) return null;

    final rows = await db.query(
      'cart_items',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return LocalCartSnapshot(
      cartId: (carts.first['cart_id'] as num?)?.toInt(),
      items: rows.map((row) {
        return {
          'quantity': row['quantity'],
          'product': jsonDecode(row['product_json'] as String),
        };
      }).toList(growable: false),
    );
  }

  Future<void> writeCart({
    required int userId,
    required int? cartId,
    required Iterable<Map<String, dynamic>> items,
  }) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.insert(
        'carts',
        {'user_id': userId, 'cart_id': cartId, 'initialized': 1},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.delete('cart_items', where: 'user_id = ?', whereArgs: [userId]);
      final batch = txn.batch();
      for (final item in items) {
        final product = item['product'] as Map<String, dynamic>;
        batch.insert('cart_items', {
          'user_id': userId,
          'product_id': product['id'],
          'quantity': item['quantity'],
          'product_json': jsonEncode(product),
        });
      }
      await batch.commit(noResult: true);
    });
  }
}
