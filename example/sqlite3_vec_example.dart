import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_vec/sqlite3_vec.dart';

Uint8List f32(List<double> values) {
  final v = Float32List.fromList(values);
  return v.buffer.asUint8List(v.offsetInBytes, v.lengthInBytes);
}

void main() {
  // sqlite3_auto_extension is process-level state: register before opening the
  // database you want vec0 on.
  loadSqliteVec();

  final db = sqlite3.openInMemory();
  print('sqlite-vec ${db.select('SELECT vec_version() AS v').single['v']}');

  // The vector column's dimension and metric are fixed at CREATE time.
  db.execute(
    'CREATE VIRTUAL TABLE notes USING vec0('
    'embedding float[4] distance_metric=cosine)',
  );

  // rowid is yours to choose, so it can point back into your own table.
  final insert = db.prepare(
    'INSERT INTO notes(rowid, embedding) VALUES (?, ?)',
  );
  insert.execute([
    1,
    f32([1, 0, 0, 0]),
  ]);
  insert.execute([
    2,
    f32([0, 1, 0, 0]),
  ]);
  insert.execute([
    3,
    f32([0.9, 0.1, 0, 0]),
  ]);
  insert.close();

  // KNN: `MATCH` takes the query vector, `k` the number of neighbours. Results
  // come back ordered by distance — for cosine, 0 is identical and 2 opposite.
  for (final row in db.select(
    'SELECT rowid, distance FROM notes '
    'WHERE embedding MATCH ? AND k = 2 ORDER BY distance',
    [
      f32([1, 0, 0, 0]),
    ],
  )) {
    print('rowid=${row['rowid']} distance=${row['distance']}');
  }

  db.close();
}
