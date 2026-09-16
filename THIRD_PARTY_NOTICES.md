# 第三方组件

本包分发以下第三方源码，各自许可如下。

机器可读的版本在包根的 [`third_party.json`](third_party.json)，形状是
`[{"packages": [...], "text": "<许可全文>"}]`，供在构建期生成许可清单的项目直接读取
（例如通过 `package_config.json` 定位本包后读该文件），不必解析本文档。

## sqlite-vec

- 来源：https://github.com/asg017/sqlite-vec，版本 `v0.1.9`（源码 commit
  `e9f598abfa0c06b328d8fe5da9c3760cce74be10`，2026-03-31）
- 位置：`src/sqlite-vec.c`、`src/sqlite-vec.h`
- 许可：Apache-2.0 / MIT 双许可，**本包按 MIT 使用**。完整文本见 `src/LICENSE-sqlite-vec`。
- 改动：无。amalgamation 按原样编译。

## SQLite 头文件

- 来源：SQLite amalgamation 附带的 `sqlite3.h` / `sqlite3ext.h`
- 位置：`src/sqlite3.h`、`src/sqlite3ext.h`
- 许可：公有领域。
- 改动：无。仅在编译扩展时提供 `sqlite3ext.h` 的加载式扩展接口；本包不编译 SQLite 本体，
  运行时用的是 `package:sqlite3` 所加载的那一份。
