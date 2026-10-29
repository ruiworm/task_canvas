# 任务画布（Flutter 桌面版）

把 Muse 里的任务画布搬成的桌面软件，自己用：一张可以自由拖拽的画布，上面放任务卡片，卡片之间可以连线、分组，进度实时统计，数据自动保存在本地。

## 功能

- 新建卡片：标题 + 多行正文，拖标题区移动卡片，双击或点「编辑」修改
- 卡片状态：点底部徽标切换 待办 → 进行中 → 已完成
- 连线：打开工具栏「连线」开关，点一张卡片右侧的橙色圆点，再点另一张卡片；连线可以写说明文字，点说明可改可删
- 分组：新建分组后把卡片拖进去，拖分组标题栏会带着组内卡片一起动；删分组只删框，卡片保留
- 画布：拖空白处平移，Ctrl + 滚轮缩放，工具栏可以放大 / 缩小 / 重置视图
- 快捷键：Delete 删选中的卡片或连线，Ctrl+S 立即保存，Ctrl+N 在视图中心新建卡片，Esc 退出连线模式 / 取消选中
- 自动保存：每次改动后 500ms 写盘，工具栏右侧显示保存状态

## Windows 上跑起来

```bat
:: 1. 安装 Flutter（stable 通道），确保 flutter 在 PATH 里
:: 2. 开启 Windows 桌面支持
flutter config --enable-windows-desktop

:: 3. 进工程目录装依赖
flutter pub get

:: 4. 运行
flutter run -d windows

:: 打包（exe 在 build\windows\x64\runner\Release\）
flutter build windows
```

## 数据存在哪

`%USERPROFILE%\Documents\task_canvas\canvas.json`

一个 JSON 文件，结构是 `{"nodes": [...], "edges": [...], "groups": [...]}`。
备份直接复制这个文件；换电脑把文件拷到同样位置就能接着用。
删掉它，下次启动会新建一张只有欢迎卡片的空画布。

## 代码结构

```
lib/
  main.dart            # 入口：MaterialApp + ChangeNotifierProvider + CanvasScreen
  models.dart          # Node / Edge / Group / NodeStatus + toJson / fromJson
  store.dart           # CanvasStore：状态 + 增删改查 + 自动保存（debounce 500ms）
  persistence.dart     # 持久化条件导出（桌面端写文件 / Web 预览走内存）
  persistence_io.dart  # 桌面端实现：文档目录下的 canvas.json
  persistence_web.dart # Web 预览实现：不落盘，只放内存（仅用于本机验证预览）
  dialogs.dart         # 编辑卡片 / 编辑连线标签 / 重命名分组对话框
  widgets/
    canvas_view.dart   # 画布：InteractiveViewer + Stack + 选中 / 拖拽 / 快捷键
    node_card.dart     # 卡片：标题、滚动正文、状态徽标、连线手柄
    edge_painter.dart  # 连线绘制：三次贝塞尔曲线 + 箭头 + 点击命中判定
    group_box.dart     # 分组框：虚线边框 + 标题栏拖动
    toolbar.dart       # 顶部工具栏：进度统计 + 操作按钮 + 保存状态
```

## 已知的坑

- 卡片正文超出高度时在卡片内滚动显示，禁止用省略号截断——旧版网页画布出过这个 bug（文字一多直接不显示），这里特意避开了。
- 卡片、分组、连线都按世界坐标摆放，画布缩放后拖动距离要除以当前缩放倍率，否则拖起来会飘。
