import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_vec/sqlite3_vec.dart';
import 'package:test/test.dart';

Uint8List f32(List<double> values) {
  final v = Float32List.fromList(values);
  return v.buffer.asUint8List(v.offsetInBytes, v.lengthInBytes);
}

void main() {
  setUpAll(loadSqliteVec);

  late Database db;

  setUp(() {
    db = sqlite3.openInMemory();
    db.execute(
      'CREATE VIRTUAL TABLE items USING vec0('
      'embedding float[4] distance_metric=cosine)',
    );
  });

  tearDown(() => db.close());

  test('扩展已注册，版本号可读', () {
    final version = db.select('SELECT vec_version() AS v').single['v'];
    expect(version, startsWith('v0.1.9'));
  });

  test('KNN 按距离排序，rowid 由调用方指定', () {
    final rows = [
      (1, f32([1, 0, 0, 0])),
      (2, f32([0, 1, 0, 0])),
      (3, f32([0.9, 0.1, 0, 0])),
    ];
    final stmt = db.prepare(
      'INSERT INTO items(rowid, embedding) VALUES (?, ?)',
    );
    for (final (rowid, vector) in rows) {
      stmt.execute([rowid, vector]);
    }
    stmt.close();

    final hits = db.select(
      'SELECT rowid, distance FROM items '
      'WHERE embedding MATCH ? AND k = 2 ORDER BY distance',
      [
        f32([1, 0, 0, 0]),
      ],
    );
    expect([for (final r in hits) r['rowid']], [1, 3]);
    expect(hits.first['distance'] as double, closeTo(0, 1e-6));
  });

  test('删除后不再命中', () {
    db.execute('INSERT INTO items(rowid, embedding) VALUES (1, ?)', [
      f32([1, 0, 0, 0]),
    ]);
    db.execute('DELETE FROM items WHERE rowid = 1');
    final hits = db.select(
      'SELECT rowid FROM items WHERE embedding MATCH ? AND k = 1',
      [
        f32([1, 0, 0, 0]),
      ],
    );
    expect(hits, isEmpty);
  });

  test('维度不符直接报错，不是静默截断', () {
    expect(
      () => db.execute('INSERT INTO items(rowid, embedding) VALUES (1, ?)', [
        f32([1, 0]),
      ]),
      throwsA(isA<SqliteException>()),
    );
  });

  test('vec0 表在扩展注册后可以正常 DROP', () {
    db.execute('DROP TABLE items');
    final left = db.select(
      "SELECT name FROM sqlite_master WHERE name LIKE 'items%'",
    );
    expect(left, isEmpty, reason: 'xDestroy 一并清掉了影子表');
  });

  test('loadSqliteVec 可重复调用', () {
    expect(loadSqliteVec, returnsNormally);
    expect(sqlite3.loadSqliteVec, returnsNormally);
  });
}
