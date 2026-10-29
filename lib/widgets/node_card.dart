// 画布上的一张卡片：宽 240、高 180 固定。
// 结构：标题行（标题 + 编辑 + 删除）→ 正文 → 底部状态徽标。
// 正文全部显示，超出卡片高度时在卡片内滚动，禁止用省略号截断
// （这是旧版网页画布出过的 bug，这次特意避开）。

import 'package:flutter/material.dart';

import '../models.dart';

const Color _kTextMain = Color(0xFF1F1B16);
const Color _kTextSecondary = Color(0xFF8A8177);
const Color _kBorder = Color(0xFFE5E0D8);
const Color _kOrange = Color(0xFFE8590C);
const Color _kGreen = Color(0xFF2F9E44);

/// 状态徽标配色：背景浅色 + 文字深色
(Color, Color) _statusColors(NodeStatus status) {
  switch (status) {
    case NodeStatus.todo:
      return (const Color(0xFFEFEDEA), _kTextSecondary);
    case NodeStatus.doing:
      return (const Color(0xFFFDEBDD), _kOrange);
    case NodeStatus.done:
      return (const Color(0xFFDDF2E3), _kGreen);
  }
}

class NodeCard extends StatelessWidget {
  const NodeCard({
    super.key,
    required this.node,
    required this.selected,
    required this.linkMode,
    required this.isLinkStart,
    required this.onTap,
    required this.onDoubleTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusTap,
    required this.onHandleTap,
  });

  final CanvasNode node;
  final bool selected;
  final bool linkMode;
  final bool isLinkStart;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStatusTap;
  final VoidCallback onHandleTap;

  @override
  Widget build(BuildContext context) {
    final (chipBg, chipFg) = _statusColors(node.status);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          child: Container(
            width: kCardWidth,
            height: kCardHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? _kOrange : _kBorder,
                width: selected ? 2 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 标题区：按住这里拖动卡片
                GestureDetector(
                  onPanStart: onDragStart,
                  onPanUpdate: onDragUpdate,
                  onPanEnd: onDragEnd,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.only(left: 12, right: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            node.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _kTextMain,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: onEdit,
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Text(
                              '编辑',
                              style: TextStyle(
                                fontSize: 12,
                                color: _kOrange,
                              ),
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
                          tooltip: '删除卡片',
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: _kBorder),
                // 正文：全部显示，超出高度时在卡片内滚动，绝不截断
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        node.body,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: _kTextMain,
                        ),
                      ),
                    ),
                  ),
                ),
                // 底部：点状态徽标切换状态
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: onStatusTap,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: chipBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          node.status.label,
                          style: TextStyle(fontSize: 12, color: chipFg),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // 连线手柄：右侧边缘中间的橙色小圆点
        Positioned(
          right: -7,
          top: kCardHeight / 2 - 7,
          child: GestureDetector(
            onTap: onHandleTap,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // 作为连线起点时加一圈橙色描边，提示正在连线
                border: isLinkStart
                    ? Border.all(color: _kOrange, width: 2)
                    : null,
              ),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _kOrange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
