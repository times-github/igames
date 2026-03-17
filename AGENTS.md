# Repository Guidelines

## 项目结构与模块

- 项目使用getx 框架 ，网络使用dio，web版本 电脑端和手机端 要可以自适应  ui 基本一致，不管切换到电脑端还是手机版 不会出现两种不同的ui
- `lib/`：Flutter 主代码。重点：`app/modules`（功能：`auth`、`home`、`widgets` 等），`config`（主题/颜色/配置），`generated`（多语言），`utils`（工具）。
- `assets/`：图片等资源，新增后记得在 `pubspec.yaml` 声明。
- `test/`：单元/组件测试，路径与业务代码保持镜像。
- 平台目录（`android`/`ios`/`web`/`windows` 等）由 Flutter 生成，除非做平台专项开发，避免手改。

## 构建、测试与开发

- `flutter pub get`：更新依赖后执行。
- `flutter run -d chrome`：Web 开发运行，每次代码生成结束之后运行该命令或者命令行输入 r  R 刷新 ，调用chrom mcp工具 查看生成的网页代码是否正常
- `flutter run -d macos` / `-d android` / `-d ios`：平台调试。
- `flutter test`：运行单元与组件测试。
- `flutter build web`（或 `apk`/`ios`/`macos`）：生成对应平台产物。
- 若格式化因权限失败，先处理环境，再运行 `dart format .`。

## 代码风格与命名

- 遵循 Dart/Flutter 习惯：2 空格缩进；变量/方法用 `lowerCamelCase`，类用 `UpperCamelCase`，文件用 `lower_snake_case`。
- 用 `dart format` 保持风格，避免手工对齐。
- 视图文件放 `app/modules/<feature>/views/`，控制器在 `.../controllers/`，通用组件在 `app/modules/widgets/`。
- UI 文案走 `generated/locales.g.dart`，有翻译的不要硬编码。

## 测试指引

- 测试放 `test/`，路径镜像源码（如 `lib/app/modules/auth/...` → `test/app/modules/auth/...`）。
- Widget 用 `flutter_test`，纯 Dart 用 `test`。
- 命名示例：`should_doSomething_when_condition`。
- 新增逻辑需基本覆盖，复杂组件可考虑 golden test。

## 提交与 PR 规范

- 提交信息用简洁祈使句（例：“Add mobile bottom nav gradient”），同类改动尽量同一提交。
- 提 PR 前：跑 `flutter test`，视变更平台做一次 `flutter run`；UI 改动附截图/GIF。
- PR 描述聚焦「做了什么/为什么」，关联 issue/需求编号。

## 安全与配置

- 不要提交密钥/令牌；用环境变量或占位配置，`.gitignore` 忽略本地秘钥文件。
- 网络请求复用现有客户端 `app/utils/api_client.dart`，避免新建多余 HTTP 封装。
