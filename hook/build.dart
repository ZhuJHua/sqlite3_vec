import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    // Reading input.config.code throws when buildCodeAssets is false.
    if (!input.config.buildCodeAssets) return;
    final targetOS = input.config.code.targetOS;
    final packageRoot = input.packageRoot;

    await CLibrary(
      name: 'sqlite3_vec',
      packageName: input.packageName,
      assetName: 'src/bindings.dart',
      sources: [packageRoot.resolve('src/sqlite-vec.c').toFilePath()],
      includes: [packageRoot.resolve('src/').toFilePath()],
      // sqlite-vec's distance kernels call sqrtf/fabsf. On Android libm is a
      // separate shared object, and the link would otherwise succeed with the
      // references unresolved (Android does not pass --no-undefined for shared
      // libraries) only for dlopen to fail at startup.
      libraries: targetOS == OS.android ? const ['m'] : const [],
      flags: [
        if (targetOS == OS.android) ...[
          // Turn an unresolved symbol into a link error instead of a dlopen
          // failure at startup.
          '-Wl,--no-undefined',
          // Android 15 runs on 16 KB pages. Upstream's own prebuilt libraries
          // are still 4 KB aligned, which is why this is here.
          '-Wl,-z,max-page-size=16384',
        ],
        if (targetOS case OS.iOS || OS.macOS) ...[
          // clang would otherwise bake in the temporary directory that
          // native_toolchain_c compiles in, which hurts reproducibility.
          '-install_name',
          '@rpath/libsqlite3_vec.dylib',
        ],
      ],
    ).build(
      input: input,
      output: output,
      // CLibrary.build() flips both of these to static + ToLinkHook when
      // input.config.linkingEnabled is true, which is the case for Flutter
      // release builds. That would emit a .a routed to a link hook this package
      // does not have, and the build fails validation.
      //
      // Pinning them keeps every build mode on the one shape that is actually
      // tested: a bundled dynamic library. Static linking would also put the
      // extension entry point at the mercy of tree shaking — and a dropped
      // symbol here does not degrade, it makes CREATE VIRTUAL TABLE fail.
      routing: const [ToAppBundle()],
      linkModePreference: LinkModePreference.dynamic,
    );

    // native_toolchain_c only tracks the files it is handed, so without this
    // the hook would happily reuse a stale library after a header changes.
    output.dependencies.addAll([
      for (final entry in Directory.fromUri(
        packageRoot.resolve('src/'),
      ).listSync(recursive: true).whereType<File>())
        entry.uri,
    ]);
  });
}
