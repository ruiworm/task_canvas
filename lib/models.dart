// 数据模型：画布上的卡片、连线、分组。
// 字段名与存盘 JSON 保持一致，方便 toJson / fromJson 直出直读。

import 'dart:math';

/// 卡片固定尺寸（画布、卡片、连线三处共用，改这里即可）
const double kCardWidth = 240;
const double kCardHeight = 180;

/// 卡片状态：待办 / 进行中 / 已完成
enum NodeStatus { todo, doing, done }

extension NodeStatusX on NodeStatus {
  /// 界面显示的中文名
  String get label {
    switch (this) {
      case NodeStatus.todo:
        return '待办';
      case NodeStatus.doing:
        return '进行中';
      case NodeStatus.done:
        return '已完成';
    }
  }

  /// 存盘用的字符串
  String get value {
    switch (this) {
      case NodeStatus.todo:
        return 'todo';
      case NodeStatus.doing:
        return 'doing';
      case NodeStatus.done:
        return 'done';
    }
  }

  /// 从存盘字符串还原，未知值一律当作待办
  static NodeStatus fromValue(String value) {
    switch (value) {
      case 'doing':
        return NodeStatus.doing;
      case 'done':
        return NodeStatus.done;
      default:
        return NodeStatus.todo;
    }
  }

  /// 点状态徽标时的流转：待办 → 进行中 → 已完成 → 待办
  NodeStatus get next {
    switch (this) {
      case NodeStatus.todo:
        return NodeStatus.doing;
      case NodeStatus.doing:
        return NodeStatus.done;
      case NodeStatus.done:
        return NodeStatus.todo;
    }
  }
}

/// 生成唯一 id：毫秒时间戳 + 4 位随机数，不引入 uuid 包
String newId() {
  final random = Random().nextInt(10000).toString().padLeft(4, '0');
  return '${DateTime.now().millisecondsSinceEpoch}$random';
}

/// 画布上的一张卡片
class CanvasNode {
  CanvasNode({
    required this.id,
    required this.title,
    required this.body,
    required this.x,
    required this.y,
    this.status = NodeStatus.todo,
    this.groupId,
  });

  String id;
  String title;
  String body;
  double x, y; // 在画布世界坐标中的左上角
  NodeStatus status;
  String? groupId; // 所属分组 id，无分组为 null

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'x': x,
        'y': y,
        'status': status.value,
        'groupId': groupId,
      };

  factory CanvasNode.fromJson(Map<String, dynamic> json) => CanvasNode(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        status: NodeStatusX.fromValue(json['status'] as String? ?? 'todo'),
        groupId: json['groupId'] as String?,
      );
}

/// 两张卡片之间的一条连线
class CanvasEdge {
  CanvasEdge({
    required this.id,
    required this.fromId,
    required this.toId,
    this.label = '',
  });

  String id;
  String fromId; // 起点卡片 id
  String toId; // 终点卡片 id
  String label; // 连线上的说明文字，可为空

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromId': fromId,
        'toId': toId,
        'label': label,
      };

  factory CanvasEdge.fromJson(Map<String, dynamic> json) => CanvasEdge(
        id: json['id'] as String,
        fromId: json['fromId'] as String,
        toId: json['toId'] as String,
        label: json['label'] as String? ?? '',
      );
}

/// 画布上的一个分组框
class CanvasGroup {
  CanvasGroup({
    required this.id,
    required this.title,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  String id;
  String title;
  double x, y, width, height; // 世界坐标

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };

  factory CanvasGroup.fromJson(Map<String, dynamic> json) => CanvasGroup(
        id: json['id'] as String,
        title: json['title'] as String? ?? '新分组',
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
      );
}
