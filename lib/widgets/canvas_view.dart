// 画布主界面：工具栏 + InteractiveViewer 画布。
// 画布世界是 4000x4000 的 Stack，卡片、分组、连线都按世界坐标摆放。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../dialogs.dart';
import '../models.dart';
import '../store.dart';
import 'edge_painter.dart';
import 'group_box.dart';
import 'node_card.dart';
import 'toolbar.dart';

/// 画布世界尺寸
const double kCanvasSize = 4000;

/// 点阵背景：暖纸底上的圆点，间距 24px
class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE8E2D8);
    for (double x = 12; x < size.width; x += 24) {
      for (double y = 12; y < size.height; y += 24) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CanvasScreen extends StatefulWidget {
  const CanvasScreen({super.key});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  final TransformationController _viewController = TransformationController();
  final FocusNode _focusNode = FocusNode();

  /// 视口尺寸（LayoutBuilder 量出来的），用来算视图中心
  Size _viewportSize = Size.zero;

  /// 连线模式：打开后点手柄选起点，再点另一张卡片建连线
  bool _linkMode = false;

  /// 连线起点卡片 id（已点手柄、等点终点时非空）
  String? _linkFromId;

  /// 当前选中的卡片 / 连线
  String? _selectedNodeId;
  String? _selectedEdgeId;

  @override
  void dispose() {
    _viewController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  double get _scale => _viewController.value.getMaxScaleOnAxis();

  /// 视口中心对应的画布世界坐标（InteractiveViewer 只做缩放+平移，
  /// 所以直接用矩阵的缩放和平移分量换算即可）
  Offset _viewCenterScene() {
    final m = _viewController.value;
    final scale = m.getMaxScaleOnAxis();
    final tx = m.entry(0, 3);
    final ty = m.entry(1, 3);
    final center = Offset(_viewportSize.width / 2, _viewportSize.height / 2);
    return Offset((center.dx - tx) / scale, (center.dy - ty) / scale);
  }

  // ---------- 视图操作 ----------

  /// 以视口中心为支点缩放，缩放范围 0.25～2.0
  void _zoomBy(double factor) {
    final current = _viewController.value;
    final currentScale = current.getMaxScaleOnAxis();
    final target = (currentScale * factor).clamp(0.25, 2.0);
    final f = target / currentScale;
    if (f == 1.0) return;
    final center = Offset(_viewportSize.width / 2, _viewportSize.height / 2);
    final zoomed = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(f, f, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
    zoomed.multiply(current);
    _viewController.value = zoomed;
  }

  /// 重置视图：回到 100% 且回到原点
  void _resetView() {
    _viewController.value = Matrix4.identity();
  }

  void _addNodeAtCenter(CanvasStore store) {
    final center = _viewCenterScene();
    final node = store.addNodeAt(
      center.dx - kCardWidth / 2,
      center.dy - kCardHeight / 2,
    );
    setState(() {
      _selectedNodeId = node.id;
      _selectedEdgeId = null;
    });
  }

  void _addGroupAtCenter(CanvasStore store) {
    final center = _viewCenterScene();
    store.addGroupAt(
      center.dx - kDefaultGroupWidth / 2,
      center.dy - kDefaultGroupHeight / 2,
    );
  }

  // ---------- 卡片交互 ----------

  void _onNodeTap(CanvasStore store, CanvasNode node) {
    // 连线模式下：已选了起点，点另一张卡片即建连线
    if (_linkMode && _linkFromId != null && _linkFromId != node.id) {
      store.addEdge(_linkFromId!, node.id);
      setState(() {
        _linkFromId = null;
        _selectedNodeId = node.id;
        _selectedEdgeId = null;
      });
      return;
    }
    setState(() {
      _selectedNodeId = node.id;
      _selectedEdgeId = null;
    });
  }

  void _onHandleTap(CanvasNode node) {
    // 手柄只在连线模式下起作用
    if (!_linkMode) return;
    setState(() {
      if (_linkFromId == null) {
        _linkFromId = node.id;
      } else if (_linkFromId == node.id) {
        _linkFromId = null; // 再点一次取消起点
      } else {
        // 这里一般走不到（点卡片已建连线），兜底处理
        _linkFromId = node.id;
      }
    });
  }

  Future<void> _editNode(CanvasStore store, CanvasNode node) async {
    final result = await showEditNodeDialog(context, node);
    if (result == null || !mounted) return;
    store.updateNode(node.id, title: result.title, body: result.body);
  }

  void _deleteNode(CanvasStore store, String id) {
    store.deleteNode(id);
    if (_selectedNodeId == id) {
      setState(() => _selectedNodeId = null);
    }
  }

  // ---------- 连线交互 ----------

  Future<void> _editEdge(CanvasStore store, CanvasEdge edge) async {
    final result = await showEditEdgeDialog(context, edge);
    if (result == null || !mounted) return;
    if (result.delete) {
      store.deleteEdge(edge.id);
      if (_selectedEdgeId == edge.id) {
        setState(() => _selectedEdgeId = null);
      }
    } else {
      store.updateEdgeLabel(edge.id, result.label);
    }
  }

  // ---------- 分组交互 ----------

  Future<void> _renameGroup(CanvasStore store, CanvasGroup group) async {
    final title = await showRenameGroupDialog(context, group);
    if (title == null || title.isEmpty || !mounted) return;
    store.renameGroup(group.id, title);
  }

  // ---------- 背景点击 ----------

  /// 点空白处：先排除落在卡片上的点击（交给卡片自己处理），
  /// 再看是否点中某条连线附近 8px（命中则选中连线），否则取消选中。
  void _onBackgroundTapUp(TapUpDetails details) {
    // GestureDetector 的 localPosition 已是画布世界坐标
    final scene = details.localPosition;
    final store = context.read<CanvasStore>();
    for (final n in store.nodes) {
      if (Rect.fromLTWH(n.x, n.y, kCardWidth, kCardHeight)
          .contains(scene)) {
        return;
      }
    }
    final threshold = 8 / _scale; // 8 个屏幕像素换算成世界坐标
    final byId = {for (final n in store.nodes) n.id: n};
    String? hit;
    for (final edge in store.edges) {
      final from = byId[edge.fromId];
      final to = byId[edge.toId];
      if (from == null || to == null) continue;
      if (EdgeGeometry(from, to).distanceTo(scene) <= threshold) {
        hit = edge.id;
        break;
      }
    }
    setState(() {
      _selectedEdgeId = hit;
      if (hit == null) _selectedNodeId = null;
    });
  }

  // ---------- 键盘快捷键 ----------

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final store = context.read<CanvasStore>();

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      // Esc：退出连线模式 / 取消选中
      if (_linkMode ||
          _linkFromId != null ||
          _selectedNodeId != null ||
          _selectedEdgeId != null) {
        setState(() {
          _linkMode = false;
          _linkFromId = null;
          _selectedNodeId = null;
          _selectedEdgeId = null;
        });
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      // Delete：删除当前选中的卡片或连线
      if (_selectedNodeId != null) {
        _deleteNode(store, _selectedNodeId!);
        return KeyEventResult.handled;
      }
      if (_selectedEdgeId != null) {
        store.deleteEdge(_selectedEdgeId!);
        setState(() => _selectedEdgeId = null);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (HardwareKeyboard.instance.isControlPressed) {
      if (event.logicalKey == LogicalKeyboardKey.keyS) {
        store.saveNow(); // Ctrl+S 立即保存
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyN) {
        _addNodeAtCenter(store); // Ctrl+N 在视图中心新建卡片
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  // ---------- 连线标签 ----------

  /// 有文字的连线，在曲线中点处放一个可点击的白色小标签
  List<Widget> _buildEdgeLabels(CanvasStore store) {
    final byId = {for (final n in store.nodes) n.id: n};
    final labels = <Widget>[];
    for (final edge in store.edges) {
      if (edge.label.isEmpty) continue;
      final from = byId[edge.fromId];
      final to = byId[edge.toId];
      if (from == null || to == null) continue;
      final mid = EdgeGeometry(from, to).midpoint;
      labels.add(
        Positioned(
          left: mid.dx - 60,
          top: mid.dy - 13,
          child: GestureDetector(
            onTap: () => _editEdge(store, edge),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 120),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E0D8)),
              ),
              child: Text(
                edge.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1F1B16),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return labels;
  }

  // ---------- 构建 ----------

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CanvasStore>();

    if (!store.loaded) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF7F2),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final total = store.nodes.length;
    final done =
        store.nodes.where((n) => n.status == NodeStatus.done).length;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: Column(
        children: [
          CanvasToolbar(
            doneCount: done,
            totalCount: total,
            linkMode: _linkMode,
            saveStatusText: store.saveStatusText,
            onAddNode: () => _addNodeAtCenter(store),
            onAddGroup: () => _addGroupAtCenter(store),
            onToggleLink: () {
              setState(() {
                _linkMode = !_linkMode;
                _linkFromId = null;
              });
            },
            onZoomIn: () => _zoomBy(1.25),
            onZoomOut: () => _zoomBy(0.8),
            onResetView: _resetView,
          ),
          Expanded(
            child: Focus(
              autofocus: true,
              focusNode: _focusNode,
              onKeyEvent: _onKeyEvent,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _viewportSize =
                      Size(constraints.maxWidth, constraints.maxHeight);
                  return InteractiveViewer(
                    transformationController: _viewController,
                    minScale: 0.25,
                    maxScale: 2.0,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    constrained: false,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: _onBackgroundTapUp,
                      child: SizedBox(
                        width: kCanvasSize,
                        height: kCanvasSize,
                        child: Stack(
                          children: [
                            // 点阵背景
                            const Positioned.fill(
                              child: CustomPaint(painter: _DotGridPainter()),
                            ),
                            // 连线（卡片下层）
                            CustomPaint(
                              size: const Size(kCanvasSize, kCanvasSize),
                              painter: EdgePainter(
                                nodes: store.nodes,
                                edges: store.edges,
                                selectedEdgeId: _selectedEdgeId,
                              ),
                            ),
                            // 分组（卡片下层）
                            ...store.groups.map(
                              (g) => Positioned(
                                left: g.x,
                                top: g.y,
                                child: GroupBox(
                                  group: g,
                                  memberCount: store.nodes
                                      .where((n) => n.groupId == g.id)
                                      .length,
                                  onDragUpdate: (details) =>
                                      store.moveGroup(
                                    g.id,
                                    details.delta.dx / _scale,
                                    details.delta.dy / _scale,
                                  ),
                                  onRename: () => _renameGroup(store, g),
                                  onDelete: () {
                                    store.deleteGroup(g.id);
                                  },
                                ),
                              ),
                            ),
                            // 卡片
                            ...store.nodes.map(
                              (n) => Positioned(
                                left: n.x,
                                top: n.y,
                                child: NodeCard(
                                  node: n,
                                  selected: _selectedNodeId == n.id,
                                  linkMode: _linkMode,
                                  isLinkStart: _linkFromId == n.id,
                                  onTap: () => _onNodeTap(store, n),
                                  onDoubleTap: () => _editNode(store, n),
                                  onDragStart: (_) {
                                    setState(() {
                                      _selectedNodeId = n.id;
                                      _selectedEdgeId = null;
                                    });
                                  },
                                  onDragUpdate: (details) => store.moveNode(
                                    n.id,
                                    details.delta.dx / _scale,
                                    details.delta.dy / _scale,
                                  ),
                                  onDragEnd: (_) =>
                                      store.finishNodeDrag(n.id),
                                  onEdit: () => _editNode(store, n),
                                  onDelete: () => _deleteNode(store, n.id),
                                  onStatusTap: () =>
                                      store.cycleStatus(n.id),
                                  onHandleTap: () => _onHandleTap(n),
                                ),
                              ),
                            ),
                            // 连线标签
                            ..._buildEdgeLabels(store),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
