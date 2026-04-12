# igames

Flutter 项目说明，包含 Android / Web 打包、应用图标生成、应用名称与包名修改流程。

## 快速目录

- [打包发布](#打包发布)
- [Android 单架构 APK 打包](#android-单架构-apk-打包)
- [Android 通用 APK 打包](#android-通用-apk-打包)
- [Android 拆分 APK 打包](#android-拆分-apk-打包)
- [Web 打包](#web-打包)
- [品牌与命名](#品牌与命名)
- [更新应用图标](#更新应用图标)
- [更新应用名称和包名](#更新应用名称和包名)

## 打包发布

### Android 单架构 APK 打包

适合明确只给 64 位 ARM 安卓真机安装的场景，例如大多数近年的安卓手机。

#### 打包命令

先清理并拉依赖：

```bash
flutter clean
flutter pub get
```

再执行 arm64 单架构打包：

```bash
flutter build apk --release --target-platform android-arm64
```

#### 输出文件

生成文件：

- `build/app/outputs/flutter-apk/app-release.apk`

#### 说明

- 这个包只包含 `arm64-v8a`。
- 适合大多数现代安卓真机。
- 体积比通用 APK 更小。
- 本质上等同于只打出一份 `arm64-v8a` 包，只是文件名默认叫 `app-release.apk`。

### Android 通用 APK 打包

适合不想区分手机架构，想直接生成一份通用安装包时使用。

#### 打包命令

先清理并拉依赖：

```bash
flutter clean
flutter pub get
```

再执行通用 APK 打包：

```bash
flutter build apk --release
```

#### 输出文件

生成文件：

- `build/app/outputs/flutter-apk/app-release.apk`

#### 说明

- 这是通用 APK，会包含多种 ABI。
- 安装最省事，不需要区分用户手机架构。
- 缺点是包体积通常比拆分包更大。

### Android 拆分 APK 打包

当前项目的 release 构建仍使用 debug key 签名，适合自测，不适合正式上架或长期正式分发。

#### 打包命令

先清理并拉依赖：

```bash
flutter clean
flutter pub get
```

再执行拆分 APK 打包：

```bash
flutter build apk --release --split-per-abi
```

生成文件目录：

- `build/app/outputs/flutter-apk/`

常见输出文件：

- `app-armeabi-v7a-release.apk`
- `app-arm64-v8a-release.apk`
- `app-x86_64-release.apk`

#### 架构区别

- `app-armeabi-v7a-release.apk`：给 32 位 ARM 设备使用，适合较老的安卓手机。
- `app-arm64-v8a-release.apk`：给 64 位 ARM 设备使用，绝大多数现在的安卓真机都装这个。
- `app-x86_64-release.apk`：主要给 Android 模拟器或少数 x86_64 设备使用。

#### 当前设备建议

如果是现代安卓真机，例如你现在这类三星真机，优先安装：

- `app-arm64-v8a-release.apk`

#### 为什么用拆分包

- 单个 APK 更小，因为只包含对应 CPU 架构的原生库。
- 安装包体积比通用 `app-release.apk` 更小。
- 手工分发时需要给用户发对架构的那一份 APK。

#### 三种打包方式怎么选

- `flutter build apk --release --target-platform android-arm64`：只给大多数现代安卓真机用，体积更小。
- `flutter build apk --release`：想省事，直接出一份通用包。
- `flutter build apk --release --split-per-abi`：想把包尽量做小，并且可以按机型分别发包。

### Web 打包

#### 打包命令

先清理并拉依赖：

```bash
flutter clean
flutter pub get
```

再执行 Web 构建：

```bash
flutter build web
```

#### 输出目录

Web 构建产物会生成到：

- `build/web/`

常见文件包括：

- `build/web/index.html`
- `build/web/main.dart.js`
- `build/web/flutter_bootstrap.js`
- `build/web/assets/`
- `build/web/icons/`

#### 部署说明

- 把 `build/web/` 整个目录上传到 Web 服务器即可。
- 如果服务器开启了强缓存，更新后可能需要清理缓存或刷新 CDN。
- 如果项目后面改成前端路由模式，需要服务器把未知路径回退到 `index.html`。

#### 本地验证

构建完成后，建议至少本地跑一次：

```bash
flutter run -d chrome
```

或者直接部署 `build/web/` 到测试环境再验收。

## 品牌与命名

### 更新应用图标

项目已接入 `flutter_launcher_icons`，用于统一生成 Web、Android、iOS、macOS、Windows 的应用图标。

#### 图标源文件

- 默认源图：`assets/images/getwiner.png`
- 插件配置：`flutter_launcher_icons.yaml`

如果以后要换图标，优先替换 `assets/images/getwiner.png`。如果你想改成别的源图路径，再同步修改 `flutter_launcher_icons.yaml` 里的 `image_path` 和 `adaptive_icon_foreground`。

#### 使用步骤

1. 替换源图文件。
2. 拉取依赖：

```bash
flutter pub get
```

1. 生成全部平台图标：

```bash
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml
```

#### 生成范围

执行完成后会覆盖以下平台图标资源：

- `web/favicon.png`
- `web/icons/*`
- `android/app/src/main/res/*`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/*`
- `macos/Runner/Assets.xcassets/AppIcon.appiconset/*`
- `windows/runner/resources/app_icon.ico`

#### 注意事项

- Web 标签页图标可能被浏览器缓存；如果没立即变化，先强制刷新。
- Android / iOS 如果桌面图标未立即更新，卸载重装一次最稳。

### 更新应用名称和包名

项目已接入 `package_rename`，用于统一修改 Android、iOS、Linux、macOS、Web、Windows 的应用名称和包名，避免后面手工改漏。

#### 配置位置

配置直接写在 [pubspec.yaml](/Users/mac/Desktop/游戏菠菜/igames/pubspec.yaml) 的 `package_rename_config` 节点里。

当前已经按项目现状预填了一版，你后面只需要改这些字段的值：

```yaml
package_rename_config:
  android:
    app_name: "getwiner"
    package_name: "win.getwiner"
    override_old_package: "co.getwiner.igames"
    lang: "kotlin"

  ios:
    app_name: "Igames"
    bundle_name: "igames"
    package_name: "win.getwiner"

  linux:
    app_name: "igames"
    package_name: "win.getwiner"
    exe_name: "igames"

  macos:
    app_name: "igames"
    package_name: "win.getwiner"
    copyright_notice: "Copyright © 2025 win.getwiner. All rights reserved."

  web:
    app_name: "getwiner.win"
    short_app_name: "igames7"
    description: "best online casino"

  windows:
    app_name: "igames"
    organization: "win.getwiner"
    copyright_notice: "Copyright (C) 2025 win.getwiner. All rights reserved."
    exe_name: "igames"
```

#### 字段说明

- `app_name`: 应用显示名。影响桌面标题、应用名称、部分平台的显示文案。
- `package_name`: 包名 / Bundle Identifier / Application ID。
- `bundle_name`: iOS 的 Bundle Name。
- `exe_name`: Linux / Windows 的可执行文件名。
- `organization`: Windows 公司名。
- `short_app_name`: Web PWA 的短名称。
- `description`: Web manifest 描述。
- `copyright_notice`: macOS / Windows 版权信息。
- `lang`: Android 工程语言。当前项目是 `kotlin`。

#### 使用步骤

1. 按需要修改 [pubspec.yaml](/Users/mac/Desktop/游戏菠菜/igames/pubspec.yaml) 里的 `package_rename_config`。
2. 拉依赖：

```bash
flutter pub get
```

1. 执行改名：

```bash
dart run package_rename
```

#### 常见场景

- 只改显示名：改各平台的 `app_name`，其他字段不动。
- 改包名：改各平台的 `package_name`。
- 改可执行文件名：改 Linux / Windows 的 `exe_name`。

#### Android 改包名补充

如果你后面要把 Android 包名从旧值彻底迁到新值，建议在 `android` 配置里临时补上：

```yaml
android:
  app_name: "新应用名"
  package_name: "com.new.package"
  override_old_package: "co.getwiner.igames"
  lang: "kotlin"
```

`override_old_package` 的作用是清理旧包路径，避免 Java/Kotlin 目录结构残留在老包名下面。

#### 改名后建议

- 执行一次 `flutter clean`
- 再执行一次 `flutter pub get`
- 然后重新运行对应平台

参考插件文档：
[https://pub.dev/packages/package_rename](https://pub.dev/packages/package_rename)
