
## 更新应用图标

项目已接入 `flutter_launcher_icons`，用于统一生成 Web、Android、iOS、macOS、Windows 的应用图标。

### 图标源文件

- 默认源图：`assets/images/getwiner.png`
- 插件配置：`flutter_launcher_icons.yaml`

如果以后要换图标，优先替换 `assets/images/getwiner.png`。如果你想改成别的源图路径，再同步修改 `flutter_launcher_icons.yaml` 里的 `image_path` 和 `adaptive_icon_foreground`。

### 使用步骤

1. 替换源图文件。
2. 拉取依赖：

```bash
flutter pub get
```

3. 生成全部平台图标：

```bash
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml
```

### 生成范围

执行完成后会覆盖以下平台图标资源：

- `web/favicon.png`
- `web/icons/*`
- `android/app/src/main/res/*`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/*`
- `macos/Runner/Assets.xcassets/AppIcon.appiconset/*`
- `windows/runner/resources/app_icon.ico`

### 注意事项

- Web 标签页图标可能被浏览器缓存；如果没立即变化，先强制刷新。
- Android / iOS 如果桌面图标未立即更新，卸载重装一次最稳。
