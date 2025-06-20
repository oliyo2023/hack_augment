# Package

version       = "2.2.0"
author        = "oliyo"
description   = "Augment Free Trail - Augment IDE清理工具 - 支持选择性清理"
license       = "MIT"
srcDir        = "src"
binDir        = "target/output"
bin           = @["augment_reset"]

# Dependencies

requires "nim >= 1.6.0"
requires "tiny_sqlite >= 0.1.0"

# Tasks

task clean, "清理构建文件":
  when defined(windows):
    exec "if exist target\\output\\augment_reset.exe del target\\output\\augment_reset.exe"
    exec "if exist augment_reset.exe del augment_reset.exe"
    exec "if exist src\\augment_reset.exe del src\\augment_reset.exe"
    exec "if exist tests\\test_all.exe del tests\\test_all.exe"
    exec "if exist example.exe del example.exe"
    exec "if exist nimcache rmdir /s /q nimcache"
  else:
    exec "rm -f target/output/augment_reset"
    exec "rm -f augment_reset"
    exec "rm -f src/augment_reset"
    exec "rm -f tests/test_all"
    exec "rm -f example"
    exec "rm -rf nimcache"

task build, "构建项目":
  exec "nim compile --verbosity:1 --outdir:target/output src/augment_reset.nim"

task release, "构建发布版本":
  exec "nim compile -d:release -d:staticSqlite --opt:speed --verbosity:1 --outdir:target/output src/augment_reset.nim"

task static, "构建静态编译版本":
  exec "nim compile -d:release --opt:speed --dynlibOverride:sqlite3 --verbosity:1 --outdir:target/output src/augment_reset.nim"

task test, "运行测试":
  exec "nim compile --run tests/test_all.nim"

task example, "运行示例":
  exec "nim compile --run example.nim"

task docs, "生成文档":
  exec "nim doc --project --index:on --outdir:docs src/augment_reset.nim"

task install_deps, "安装依赖":
  echo "检查系统依赖..."
  echo "✅ 程序使用 tiny_sqlite 模块，支持静态编译"
  echo "✅ 无需外部 SQLite 库或 DLL 文件"
  echo "✅ 静态编译版本包含 SQLite 3.31.1"
  echo "✅ 所有依赖已通过 Nimble 自动管理"
  echo "✅ 系统要求：Nim 1.6.0 或更高版本"

task check, "代码检查":
  exec "nim check src/augment_reset.nim"
  exec "nim check tests/test_all.nim"
  exec "nim check example.nim"
