// 顶部工具栏：左侧进度统计，中间操作按钮，右侧保存状态。

import 'package:flutter/material.dart';

const Color _kTextMain = Color(0xFF1F1B16);
const Color _kTextSecondary = Color(0xFF8A8177);
const Color _kBorder = Color(0xFFE5E0D8);
const Color _kOrange = Color(0xFFE8590C);

class CanvasToolbar extends StatelessWidget {
  const CanvasToolbar({
    super.key,
    required this.doneCount,
    required this.totalCount,
    required this.linkMode,
    required this.saveStatusText,
    required this.onAddNode,
    required this.onAddGroup,
    required this.onToggleLink,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetView,
  });

  final int doneCount;
  final int totalCount;
  final bool linkMode;
  final String saveStatusText;
  final VoidCallback onAddNode;
  final VoidCallback onAddGroup;
  final VoidCallback onToggleLink;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetView;

  @override
  Widget build(BuildContext context) {
    final percent =
        totalCount == 0 ? 0 : (doneCount * 100 / totalCount).round();
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          // 左侧：进度统计
          Text(
            '已完成 $doneCount / $totalCount · $percent%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kTextMain,
            ),
          ),
          const SizedBox(width: 16),
          const VerticalDivider(width: 1, color: _kBorder),
          const SizedBox(width: 8),
          // 中间：操作按钮
          _toolButton(
            label: '新建卡片',
            icon: Icons.add,
            onPressed: onAddNode,
          ),
          _toolButton(
            label: '新建分组',
            icon: Icons.dashboard_customize_outlined,
            onPressed: onAddGroup,
          ),
          _toolButton(
            label: '连线',
            icon: Icons.timeline,
            active: linkMode,
            onPressed: onToggleLink,
          ),
          const SizedBox(width: 8),
          const VerticalDivider(width: 1, color: _kBorder),
          const SizedBox(width: 8),
          _toolButton(
            label: '放大',
            icon: Icons.zoom_in,
            onPressed: onZoomIn,
          ),
          _toolButton(
            label: '缩小',
            icon: Icons.zoom_out,
            onPressed: onZoomOut,
          ),
          _toolButton(
            label: '重置视图',
            icon: Icons.center_focus_strong,
            onPressed: onResetView,
          ),
          const Spacer(),
          // 右侧：保存状态
          Text(
            saveStatusText,
            style: const TextStyle(fontSize: 12, color: _kTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _toolButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool active = false,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 16,
        color: active ? _kOrange : _kTextMain,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: active ? _kOrange : _kTextMain,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor:
            active ? const Color(0xFFFDEBDD) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
