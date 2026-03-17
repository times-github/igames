# Flutter 响应式布局使用指南

## 📱 断点设计概念

**断点（Breakpoints）** 是响应式设计中的核心概念，它定义了在不同屏幕尺寸下布局发生变化的临界点。

### 我们定义的断点：

```dart
class AppBreakpoints {
  static const double mobile = 768.0;      // 手机断点
  static const double tablet = 1024.0;     // 平板断点  
  static const double desktop = 1200.0;    // 桌面断点
  static const double largeDesktop = 1440.0; // 大桌面断点
}
```

### 断点的工作原理：

1. **< 768px**: 手机布局 - 单列，紧凑间距
2. **768px - 1024px**: 平板布局 - 双列，中等间距
3. **1024px - 1200px**: 桌面布局 - 三列，宽松间距
4. **> 1200px**: 大桌面布局 - 四列，最大间距

## 🛠️ 响应式工具类使用

### 1. 设备类型判断

```dart
// 判断是否为手机
if (ResponsiveUtils.isMobile(context)) {
  // 手机特定逻辑
}

// 判断是否为平板
if (ResponsiveUtils.isTablet(context)) {
  // 平板特定逻辑
}

// 判断是否为桌面
if (ResponsiveUtils.isDesktop(context)) {
  // 桌面特定逻辑
}
```

### 2. 响应式值获取

```dart
// 根据屏幕尺寸返回不同的值
final fontSize = ResponsiveUtils.responsiveValue(
  context: context,
  mobile: 16.0,      // 手机字体大小
  tablet: 18.0,      // 平板字体大小
  desktop: 20.0,     // 桌面字体大小
);

// 响应式边距
final padding = ResponsiveUtils.responsivePadding(context);

// 响应式列数
final columns = ResponsiveUtils.responsiveColumns(context);
```

## 🎨 响应式组件使用

### 1. ResponsiveWrapper - 基础响应式容器

```dart
ResponsiveWrapper(
  maxWidth: 1200, // 最大宽度
  centerContent: true, // 居中内容
  child: YourContent(),
)
```

**特点：**
- 自动限制最大宽度
- 响应式边距
- 内容居中显示

### 2. ResponsiveGridWrapper - 响应式网格

```dart
ResponsiveGridWrapper(
  children: [
    GridItem1(),
    GridItem2(),
    GridItem3(),
  ],
  spacing: 16, // 列间距
  runSpacing: 16, // 行间距
)
```

**自动列数：**
- 手机：1列
- 平板：2列
- 桌面：3列
- 大桌面：4列

### 3. ResponsiveRowWrapper - 响应式行

```dart
ResponsiveRowWrapper(
  children: [
    Expanded(child: Item1()),
    Expanded(child: Item2()),
    Expanded(child: Item3()),
  ],
)
```

**特点：**
- 小屏幕自动换行
- 大屏幕保持行布局
- 自动分配空间

## 📐 LayoutBuilder 使用

`LayoutBuilder` 是Flutter中实现响应式布局的核心组件，它提供了当前约束信息。

### 基本用法：

```dart
LayoutBuilder(
  builder: (context, constraints) {
    // constraints.maxWidth - 可用宽度
    // constraints.maxHeight - 可用高度
    
    if (constraints.maxWidth < 600) {
      return MobileLayout();
    } else {
      return DesktopLayout();
    }
  },
)
```

### 实际应用：

```dart
Widget buildResponsiveContent(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 600;
      
      return Column(
        children: [
          Text(
            '标题',
            style: TextStyle(
              fontSize: isNarrow ? 20 : 28,
            ),
          ),
          if (isNarrow) 
            MobileContent()
          else 
            DesktopContent(),
        ],
      );
    },
  );
}
```

## 🎯 MediaQuery 使用

`MediaQuery` 提供了设备的详细信息，用于精确的响应式控制。

### 常用属性：

```dart
// 屏幕尺寸
final size = MediaQuery.of(context).size;
final width = size.width;
final height = size.height;

// 设备像素比
final pixelRatio = MediaQuery.of(context).devicePixelRatio;

// 安全区域（刘海屏等）
final padding = MediaQuery.of(context).padding;
final topPadding = padding.top; // 状态栏高度

// 方向
final orientation = MediaQuery.of(context).orientation;
final isPortrait = orientation == Orientation.portrait;
```

### 响应式字体大小：

```dart
Text(
  '响应式文本',
  style: TextStyle(
    fontSize: MediaQuery.of(context).size.width * 0.05, // 屏幕宽度的5%
    // 或者使用固定断点
    fontSize: MediaQuery.of(context).size.width < 600 ? 16 : 24,
  ),
)
```

## 🚀 最佳实践

### 1. 移动优先设计

```dart
// 先设计移动端，再向上扩展
Widget buildContent(BuildContext context) {
  return Column(
    children: [
      // 移动端基础布局
      MobileLayout(),
      
      // 平板端增强
      if (ResponsiveUtils.isTablet(context))
        TabletEnhancement(),
      
      // 桌面端增强
      if (ResponsiveUtils.isDesktop(context))
        DesktopEnhancement(),
    ],
  );
}
```

### 2. 使用常量管理尺寸

```dart
class AppSizes {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}
```

### 3. 响应式图片

```dart
Image.asset(
  ResponsiveUtils.responsiveValue(
    context: context,
    mobile: 'assets/images/small.png',
    tablet: 'assets/images/medium.png',
    desktop: 'assets/images/large.png',
  ),
)
```

## 🔍 测试响应式布局

### 1. 使用Flutter Inspector
- 调整窗口大小
- 查看不同尺寸下的布局

### 2. 模拟不同设备
```bash
# 模拟iPhone
flutter run -d iPhone

# 模拟iPad
flutter run -d iPad

# 模拟Android平板
flutter run -d android
```

### 3. 浏览器测试
```bash
flutter run -d chrome
# 然后调整浏览器窗口大小
```

## 📱 多语言适配注意事项

### 1. 文本长度差异
```dart
// 中文通常比英文短
final buttonWidth = ResponsiveUtils.responsiveValue(
  context: context,
  mobile: 120, // 英文按钮宽度
  tablet: 140,
  desktop: 160,
);

// 根据语言调整
if (Get.locale?.languageCode == 'zh') {
  buttonWidth *= 0.8; // 中文按钮可以窄一些
}
```

### 2. 字体选择
```dart
Text(
  '多语言文本',
  style: TextStyle(
    fontFamily: Get.locale?.languageCode == 'zh' 
        ? 'PingFang SC' 
        : 'Roboto',
  ),
)
```

## 🎉 总结

通过合理使用断点设计、LayoutBuilder、MediaQuery和响应式组件，你可以创建出在各种设备上都有良好体验的Flutter应用。

关键要点：
1. **定义清晰的断点**：768px、1024px、1200px
2. **使用LayoutBuilder**：获取当前约束信息
3. **利用MediaQuery**：获取设备详细信息
4. **创建响应式组件**：封装常用的响应式逻辑
5. **移动优先设计**：从小屏幕开始，向上扩展

这样设计出来的应用将能够自动适应各种屏幕尺寸，为用户提供最佳的浏览体验！ 