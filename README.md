# sqlite3_vec

[sqlite-vec](https://github.com/asg017/sqlite-vec) **v0.1.9** for
[`package:sqlite3`](https://pub.dev/packages/sqlite3): the `vec0` virtual table and the `vec_*()`
SQL functions, compiled from bundled C and shipped as a native asset.

```yaml
dependencies:
  sqlite3_vec: ^0.1.1
```

## Use

```dart
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_vec/sqlite3_vec.dart';

Uint8List f32(List<double> values) {
  final v = Float32List.fromList(values);
  return v.buffer.asUint8List(v.offsetInBytes, v.lengthInBytes);
}

void main() {
  // Registers via sqlite3_auto_extension: process-level state, so call it
  // before opening the database you want vec0 on. Twice is fine.
  loadSqliteVec();

  final db = sqlite3.openInMemory();
  db.execute(
    'CREATE VIRTUAL TABLE items USING vec0('
    'embedding float[4] distance_metric=cosine)',
  );
  db.execute('INSERT INTO items(rowid, embedding) VALUES (1, ?)', [
    f32([1, 0, 0, 0]),
  ]);

  for (final row in db.select(
    'SELECT rowid, distance FROM items '
    'WHERE embedding MATCH ? AND k = 5 ORDER BY distance',
    [
      f32([1, 0, 0, 0]),
    ],
  )) {
    print('${row['rowid']} ${row['distance']}');
  }
  db.close();
}
```

Vectors go in and out as raw little-endian `float32` bytes. The dimension and metric belong to the
table, so switching embedding models means dropping the table and re-embedding — the vectors are
derived data either way. `rowid` is yours to pick, which is how you join back to your own tables.

Upstream's [API reference](https://github.com/asg017/sqlite-vec/blob/main/site/api-reference.md)
covers the SQL surface; `SELECT vec_version()` reports the bundled version at runtime.

## With drift

Register before drift opens its connection — the background isolate and the read pool inherit the
process-level registration. `vec0` is a virtual table, so create it with `customStatement`; drift
cannot manage it.

```dart
loadSqliteVec();
final executor = NativeDatabase.createInBackground(File(path), readPool: 3);
```

## Before you remove this package

**A `vec0` table can only be dropped on a connection where the extension is registered.** `DROP
TABLE` calls the module's `xDestroy`, and without the module SQLite answers `no such module: vec0`
— inside a transaction, taking the whole transaction with it.

So if you ever migrate away, drop the table in a release that still depends on this package, not in
the one that removes it. Otherwise the vectors are stranded in four shadow tables (`<name>_chunks`,
`_info`, `_rowids`, `_vector_chunks00`) plus a schema row that ordinary SQL cannot reach.

## License

MIT. Bundles [sqlite-vec](https://github.com/asg017/sqlite-vec) (Apache-2.0 / MIT, used under MIT);
see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
