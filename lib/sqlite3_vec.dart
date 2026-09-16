/// Vector search for SQLite, backed by the
/// [sqlite-vec](https://github.com/asg017/sqlite-vec) extension.
///
/// The native library is compiled from the bundled C by this package's build
/// hook and shipped as a code asset — nothing to install per platform, and no
/// Flutter dependency.
///
/// ```dart
/// import 'package:sqlite3/sqlite3.dart';
/// import 'package:sqlite3_vec/sqlite3_vec.dart';
///
/// loadSqliteVec();
/// final db = sqlite3.openInMemory();
/// db.execute(
///   'CREATE VIRTUAL TABLE items USING vec0('
///   'embedding float[4] distance_metric=cosine)',
/// );
/// ```
library;

export 'src/loader.dart';
