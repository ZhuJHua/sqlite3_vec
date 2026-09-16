# sqlite3_vec

Vector search for SQLite, backed by [sqlite-vec](https://github.com/asg017/sqlite-vec) and shipped
as a native asset. It adds the `vec0` virtual table module and the `vec_*()` SQL functions to
[`package:sqlite3`](https://pub.dev/packages/sqlite3) — no per-platform install, no Flutter
dependency, no prebuilt binary to trust.

```sql
CREATE VIRTUAL TABLE items USING vec0(embedding float[384] distance_metric=cosine);
SELECT rowid, distance FROM items WHERE embedding MATCH ? AND k = 10;
```

## Install

```yaml
dependencies:
  sqlite3_vec: ^0.1.0
```

The native library is compiled from the bundled C by a Dart build hook, so the machine that
compiles your app needs a C toolchain — on every platform that is the one Flutter already requires.
Nothing is needed on your users' machines.

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
  // Registers via sqlite3_auto_extension, which is process-level state: call it
  // BEFORE opening the database you want vec0 on. Calling it twice is fine.
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
  db.dispose();
}
```

Vectors are passed as raw little-endian `float32` bytes. The column's dimension and metric are
fixed when the table is created; inserting a vector of the wrong length is an error, not a silent
truncation.

### With drift

Register before drift opens its connection — the background isolate and the read pool inherit the
process-level registration:

```dart
loadSqliteVec();
final executor = NativeDatabase.createInBackground(File(path), readPool: 3);
```

`vec0` is a virtual table, so drift cannot manage it. Create it with `customStatement`, and give it
a `rowid` that points back into a drift-managed table you join against.

### Changing the dimension

The dimension is part of the table definition, so changing embedding models means `DROP TABLE` and
`CREATE` again, then re-embedding. There is no migration path for the vectors themselves — they are
derived data.

## One thing to know before you ship

**A `vec0` table can only be dropped on a connection where this extension is registered.** `DROP
TABLE` has to call the module's `xDestroy`, and without the module SQLite answers `no such module:
vec0` — and, inside a transaction, takes the whole transaction with it. The same applies to
`VACUUM`.

That matters if you ever plan to *remove* this package from an app that already shipped it: drop
the table in a release that still has the extension, not in the one that removes it. Otherwise the
vectors are stranded in four shadow tables (`<name>_chunks`, `_info`, `_rowids`,
`_vector_chunks00`) plus a schema row that ordinary SQL cannot reach.

## How it works

`src/sqlite-vec.c` is the upstream amalgamation, unmodified. The build hook compiles it with
`native_toolchain_c` into a dynamic library and declares it as a code asset; Dart takes the address
of `sqlite3_vec_init` through `@Native` and hands it to `sqlite3_auto_extension` via
`package:sqlite3`'s `SqliteExtension`.

The hook pins `routing: [ToAppBundle()]` and `linkModePreference: dynamic`. Without that, Flutter
release builds (`linkingEnabled: true`) would emit a static archive routed to a link hook this
package does not have, and static linking would also expose the extension entry point to tree
shaking — where a dropped symbol does not degrade, it makes `CREATE VIRTUAL TABLE` fail.

On Android the library links `libm` explicitly (the distance kernels call `sqrtf`/`fabsf`, and
Android keeps the math symbols out of libc) and is built with `-Wl,-z,max-page-size=16384`, because
Android 15 runs on 16 KB pages and upstream's own prebuilt libraries are still 4 KB aligned.

## License

MIT. Bundles [sqlite-vec](https://github.com/asg017/sqlite-vec) (Apache-2.0 / MIT, used under MIT).
See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
