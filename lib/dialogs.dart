// 对话框：编辑卡片、编辑连线标签、重命名分组。

import 'package:flutter/material.dart';

import 'models.dart';

/// 编辑卡片：返回 (标题, 正文)，点取消返回 null
Future<({String title, String body})?> showEditNodeDialog(
  BuildContext context,
  CanvasNode node,
) async {
  final titleController = TextEditingController(text: node.title);
  final bodyController = TextEditingController(text: node.body);
  return showDialog<({String title, String body})>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('编辑卡片'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '标题'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: '正文'),
              maxLines: 6,
              minLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop((
            title: titleController.text.trim(),
            body: bodyController.text,
          )),
          child: const Text('保存'),
        ),
      ],
    ),
  );
}

/// 编辑连线标签：返回 (说明文字, 是否删除连线)，点取消返回 null
Future<({String label, bool delete})?> showEditEdgeDialog(
  BuildContext context,
  CanvasEdge edge,
) async {
  final labelController = TextEditingController(text: edge.label);
  return showDialog<({String label, bool delete})>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('连线说明'),
      content: TextField(
        controller: labelController,
        decoration: const InputDecoration(
          labelText: '说明文字',
          hintText: '留空则不显示标签',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop((
            label: edge.label,
            delete: true,
          )),
          child: const Text('删除连线', style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop((
            label: labelController.text.trim(),
            delete: false,
          )),
          child: const Text('保存'),
        ),
      ],
    ),
  );
}

/// 重命名分组：返回新标题，点取消返回 null
Future<String?> showRenameGroupDialog(
  BuildContext context,
  CanvasGroup group,
) async {
  final titleController = TextEditingController(text: group.title);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('重命名分组'),
      content: TextField(
        controller: titleController,
        decoration: const InputDecoration(labelText: '分组名称'),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(titleController.text.trim()),
          child: const Text('保存'),
        ),
      ],
    ),
  );
}
