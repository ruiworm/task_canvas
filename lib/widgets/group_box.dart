// 分组框：渲染在卡片下层，半透明暖色底 + 橙色虚线边框。
// 拖标题栏时分组与组内卡片一起移动；删框不删卡。

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';

const Color _kOrange = Color(0xFFE8590C);
const Color _kTextMain = Color(0xFF1F1B16);
const Color _kTextSecondary = Color(0xFF8A8177);

/// 沿圆角矩形画虚线边框（Flutter 的 Border 不支持虚线，只能手绘）
class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(12),
        ),
      );
    const dash = 6.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GroupBox extends StatelessWidget {
  const GroupBox({
    super.key,
    required this.group,
    required this.memberCount,
    required this.onDragUpdate,
    required this.onRename,
    required this.onDelete,
  });

  final CanvasGroup group;
  final int memberCount;
  final GestureDragUpdateCallback onDragUpdate;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: group.width,
      height: group.height,
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5EFE4).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏：按住拖动整个分组，双击改名
              GestureDetector(
                onPanUpdate: onDragUpdate,
                onDoubleTap: onRename,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.only(left: 12, right: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${group.title}（$memberCount）',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kTextMain,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        color: _kTextSecondary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        splashRadius: 14,
                        tooltip: '删除分组（卡片保留）',
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
