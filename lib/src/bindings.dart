import 'dart:ffi';

typedef _InitNative =
    Int32 Function(Pointer<Void>, Pointer<Pointer<Char>>, Pointer<Void>);

/// Entry point of the sqlite-vec extension. `src/sqlite-vec.c` declares it
/// `SQLITE_VEC_API`, which expands to `__declspec(dllexport)` on Windows, so
/// the symbol is in the export table on every platform.
@Native<_InitNative>(symbol: 'sqlite3_vec_init')
external int _sqlite3VecInit(
  Pointer<Void> db,
  Pointer<Pointer<Char>> pzErrMsg,
  Pointer<Void> pApi,
);

/// Address of the extension entry point, as `sqlite3_auto_extension` wants it.
Pointer<Void> vecInitAddress() =>
    Native.addressOf<NativeFunction<_InitNative>>(_sqlite3VecInit).cast();
