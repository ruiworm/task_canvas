// 连线绘制：三次贝塞尔曲线 + 终点箭头。
// EdgeGeometry 同时给画布提供点击命中判定（点到曲线的距离）。

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';

/// 连线颜色与线宽
const Color kEdgeColor = Color(0xFFE8590C);

/// 连线几何：起点为起点卡片右侧中点，终点为终点卡片左侧中点
class EdgeGeometry {
  EdgeGeometry(this.from, this.to);

  final CanvasNode from;
  final CanvasNode to;

  Offset get start => Offset(from.x + kCardWidth, from.y + kCardHeight / 2);
  Offset get end => Offset(to.x, to.y + kCardHeight / 2);

  /// 控制点：水平方向各伸出 60px，形成平滑的 S 形
  Offset get control1 => Offset(start.dx + 60, start.dy);
  Offset get control2 => Offset(end.dx - 60, end.dy);

  /// 三次贝塞尔曲线上 t 处的点
  Offset pointAt(double t) {
    final u = 1 - t;
    final x = u * u * u * start.dx +
        3 * u * u * t * control1.dx +
        3 * u * t * t * control2.dx +
        t * t * t * end.dx;
    final y = u * u * u * start.dy +
        3 * u * u * t * control1.dy +
        3 * u * t * t * control2.dy +
        t * t * t * end.dy;
    return Offset(x, y);
  }

  /// 曲线中点：连线标签就画在这里
  Offset get midpoint => pointAt(0.5);

  /// 点到曲线的最短距离（采样 40 个点近似），用于点击命中判定
  double distanceTo(Offset p) {
    var minDist = double.infinity;
    for (var i = 0; i <= 40; i++) {
      final d = (pointAt(i / 40) - p).distance;
      if (d < minDist) minDist = d;
    }
    return minDist;
  }

  Path get path {
    final path = Path()..moveTo(start.dx, start.dy);
    path.cubicTo(
      control1.dx,
      control1.dy,
      control2.dx,
      control2.dy,
      end.dx,
      end.dy,
    );
    return path;
  }
}

/// 画所有连线：曲线 + 终点小箭头；选中的连线加粗
class EdgePainter extends CustomPainter {
  EdgePainter({
    required this.nodes,
    required this.edges,
    this.selectedEdgeId,
  });

  final List<CanvasNode> nodes;
  final List<CanvasEdge> edges;
  final String? selectedEdgeId;

  @override
  void paint(Canvas canvas, Size size) {
    final byId = {for (final n in nodes) n.id: n};
    for (final edge in edges) {
      final from = byId[edge.fromId];
      final to = byId[edge.toId];
      if (from == null || to == null) continue;
      final geo = EdgeGeometry(from, to);
      final isSelected = edge.id == selectedEdgeId;
      final paint = Paint()
        ..color = kEdgeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3 : 2;
      canvas.drawPath(geo.path, paint);
      _drawArrow(canvas, geo);
    }
  }

  /// 在终点处按曲线切线方向画一个小实心三角箭头
  void _drawArrow(Canvas canvas, EdgeGeometry geo) {
    final nearEnd = geo.pointAt(0.96);
    final tip = geo.end;
    final dx = tip.dx - nearEnd.dx;
    final dy = tip.dy - nearEnd.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 0.001) return;
    final ux = dx / len;
    final uy = dy / len;
    final base = Offset(tip.dx - ux * 12, tip.dy - uy * 12);
    final perp = Offset(-uy, ux);
    final arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + perp.dx * 5, base.dy + perp.dy * 5)
      ..lineTo(base.dx - perp.dx * 5, base.dy - perp.dy * 5)
      ..close();
    canvas.drawPath(arrow, Paint()..color = kEdgeColor);
  }

  @override
  bool shouldRepaint(covariant EdgePainter oldDelegate) {
    // 卡片一动连线就得跟着动，直接每次重绘，数据量小不用优化
    return true;
  }
}
