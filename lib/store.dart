// 状态管理：持有画布上的卡片、连线、分组，负责增删改查 + 自动保存。
// 界面通过 provider 监听这个 Store，任何变更都会触发重建。

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'models.dart';
import 'persistence.dart';

/// 默认分组尺寸
const double kDefaultGroupWidth = 480;
const double kDefaultGroupHeight = 320;

class CanvasStore extends ChangeNotifier {
  /// 持久化实现可注入（默认写本地文件；测试可传内存实现）。
  /// 传 null 时用平台默认实现：桌面端写文件，Web 走内存。
  CanvasStore({CanvasPersistence? persistence})
      : _persistence = persistence ?? createPersistence();

  final List<CanvasNode> nodes = [];
  final List<CanvasEdge> edges = [];
  final List<CanvasGroup> groups = [];

  /// 启动加载是否完成（界面据此决定是否显示加载圈）
  bool loaded = false;

  bool _saving = false;
  DateTime? _lastSaved;
  Timer? _saveTimer;
  final CanvasPersistence _persistence;

  /// 网页预览下无法写本地文件，数据只保留在内存里
  bool get persistSupported => _persistence.supported;

  /// 工具栏右侧的保存状态文字
  String get saveStatusText {
    if (!persistSupported) return '网页预览 · 仅内存';
    if (_saving) return '保存中…';
    if (_lastSaved == null) return '未保存';
    final t = _lastSaved!;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '已保存 $hh:$mm';
  }

  /// 启动时读盘；没有存盘就新建一张空画布，只放一张欢迎卡片
  Future<void> init() async {
    final data = await _persistence.load();
    var ok = false;
    if (data != null) {
      try {
        _readList(data['nodes'], nodes, CanvasNode.fromJson);
        _readList(data['edges'], edges, CanvasEdge.fromJson);
        _readList(data['groups'], groups, CanvasGroup.fromJson);
        ok = true;
      } catch (_) {
        // 存盘损坏：清空后按新画布处理
        nodes.clear();
        edges.clear();
        groups.clear();
      }
    }
    if (!ok) _addWelcomeCard();
    loaded = true;
    notifyListeners();
  }

  void _readList<T>(
    dynamic raw,
    List<T> target,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is! List) return;
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        target.add(fromJson(item));
      } else if (item is Map) {
        target.add(fromJson(Map<String, dynamic>.from(item)));
      }
    }
  }

  /// 新画布的欢迎卡片
  void _addWelcomeCard() {
    nodes.add(CanvasNode(
      id: newId(),
      title: '欢迎使用任务画布',
      body: '拖卡片移动，双击编辑，点状态切换。',
      x: 300,
      y: 200,
    ));
  }

  Map<String, dynamic> toJson() => {
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'edges': edges.map((e) => e.toJson()).toList(),
        'groups': groups.map((g) => g.toJson()).toList(),
      };

  // ---------- 保存 ----------

  /// 每次变更后调用：debounce 500ms 再写盘，避免拖动时频繁写文件
  void _scheduleSave() {
    if (!persistSupported) return;
    _saving = true;
    notifyListeners();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _doSave);
  }

  Future<void> _doSave() async {
    try {
      await _persistence.save(toJson());
      _lastSaved = DateTime.now();
    } catch (_) {
      // 写盘失败不打扰用户，下次变更再试
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  /// 立即保存（Ctrl+S 用）
  Future<void> saveNow() async {
    if (!persistSupported) return;
    _saveTimer?.cancel();
    await _doSave();
  }

  /// 变更后的统一收尾：通知界面 + 安排保存
  void _afterChange() {
    notifyListeners();
    _scheduleSave();
  }

  // ---------- 卡片 ----------

  CanvasNode addNodeAt(double x, double y) {
    final node = CanvasNode(
      id: newId(),
      title: '新卡片',
      body: '',
      x: x,
      y: y,
    );
    nodes.add(node);
    _afterChange();
    return node;
  }

  void updateNode(String id, {String? title, String? body}) {
    final node = _findNode(id);
    if (node == null) return;
    if (title != null) node.title = title;
    if (body != null) node.body = body;
    _afterChange();
  }

  /// 删除卡片，同时删除与它相连的所有连线
  void deleteNode(String id) {
    nodes.removeWhere((n) => n.id == id);
    edges.removeWhere((e) => e.fromId == id || e.toId == id);
    _afterChange();
  }

  /// 拖动中移动卡片（调用方已把屏幕位移换算成世界坐标位移）
  void moveNode(String id, double dx, double dy) {
    final node = _findNode(id);
    if (node == null) return;
    node.x += dx;
    node.y += dy;
    notifyListeners();
    _scheduleSave();
  }

  /// 拖动结束：按卡片中心是否落在某个分组内，更新归属
  void finishNodeDrag(String id) {
    final node = _findNode(id);
    if (node == null) return;
    final center = Offset(
      node.x + kCardWidth / 2,
      node.y + kCardHeight / 2,
    );
    String? found;
    for (final g in groups) {
      if (center.dx >= g.x &&
          center.dx <= g.x + g.width &&
          center.dy >= g.y &&
          center.dy <= g.y + g.height) {
        found = g.id; // 有重叠时以后建的分组为准
      }
    }
    node.groupId = found;
    _afterChange();
  }

  /// 点状态徽标流转状态
  void cycleStatus(String id) {
    final node = _findNode(id);
    if (node == null) return;
    node.status = node.status.next;
    _afterChange();
  }

  CanvasNode? _findNode(String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  // ---------- 连线 ----------

  /// 建连线：自己连自己、重复连线都不建
  void addEdge(String fromId, String toId) {
    if (fromId == toId) return;
    for (final e in edges) {
      if (e.fromId == fromId && e.toId == toId) return;
    }
    edges.add(CanvasEdge(id: newId(), fromId: fromId, toId: toId));
    _afterChange();
  }

  void updateEdgeLabel(String id, String label) {
    for (final e in edges) {
      if (e.id == id) {
        e.label = label;
        break;
      }
    }
    _afterChange();
  }

  void deleteEdge(String id) {
    edges.removeWhere((e) => e.id == id);
    _afterChange();
  }

  // ---------- 分组 ----------

  CanvasGroup addGroupAt(double x, double y) {
    final group = CanvasGroup(
      id: newId(),
      title: '新分组',
      x: x,
      y: y,
      width: kDefaultGroupWidth,
      height: kDefaultGroupHeight,
    );
    groups.add(group);
    _afterChange();
    return group;
  }

  void renameGroup(String id, String title) {
    for (final g in groups) {
      if (g.id == id) {
        g.title = title;
        break;
      }
    }
    _afterChange();
  }

  /// 删除分组只删框，组内卡片保留并脱离分组
  void deleteGroup(String id) {
    groups.removeWhere((g) => g.id == id);
    for (final n in nodes) {
      if (n.groupId == id) n.groupId = null;
    }
    _afterChange();
  }

  /// 拖动分组：分组框与组内所有卡片一起移动
  void moveGroup(String id, double dx, double dy) {
    CanvasGroup? group;
    for (final g in groups) {
      if (g.id == id) group = g;
    }
    if (group == null) return;
    group.x += dx;
    group.y += dy;
    for (final n in nodes) {
      if (n.groupId == id) {
        n.x += dx;
        n.y += dy;
      }
    }
    notifyListeners();
    _scheduleSave();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
