import 'package:sqlite3/sqlite3.dart';

import 'bindings.dart';

/// Registers the sqlite-vec extension.
extension Sqlite3VecEx on Sqlite3 {
  /// Makes the `vec0` virtual table module and the `vec_*()` SQL functions
  /// available on every connection opened from here on.
  ///
  /// This goes through `sqlite3_auto_extension`, which is **process-level**
  /// state, so it must run *before* the first connection you intend to use it
  /// with — including connections opened on other isolates, which see the same
  /// registration. Calling it more than once is harmless.
  ///
  /// A `vec0` table cannot be dropped, or its database vacuumed into a new
  /// file, on a connection where this has not run: `DROP TABLE` has to call the
  /// module's `xDestroy`, and without the module SQLite answers `no such
  /// module: vec0`.
  void loadSqliteVec() {
    ensureExtensionLoaded(SqliteExtension(vecInitAddress()));
  }
}

var _loaded = false;

/// [Sqlite3VecEx.loadSqliteVec] on the default [sqlite3] instance, executed at
/// most once.
void loadSqliteVec() {
  if (_loaded) return;
  sqlite3.loadSqliteVec();
  _loaded = true;
}
