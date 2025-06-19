# Package

version       = "2.0.0"
author        = "oliyo"
description   = "Augment 扩展试用期重置工具 - 模块化版本"
license       = "MIT"
srcDir        = "src"
bin           = @["augment_reset"]

# Dependencies

requires "nim >= 1.6.0"

# Tasks

task clean, "清理构建文件":
  exec "rm -rf augment_reset.exe"
  exec "rm -rf src/augment_reset.exe"

task build, "构建项目":
  exec "nim compile --verbosity:1 src/augment_reset.nim"

task release, "构建发布版本":
  exec "nim compile -d:release --verbosity:1 src/augment_reset.nim"

task test, "运行测试":
  exec "nim compile --run tests/test_all.nim"
