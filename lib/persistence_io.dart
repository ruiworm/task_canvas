// 桌面端持久化：JSON 文件写到系统文档目录下的 task_canvas/canvas.json。

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 画布数据的存取接口（Web 实现见 persistence_web.dart，保持一致）
abstract class CanvasPersistence {
  /// 是否真的能落盘（桌面端 true，Web 预览 false）
  bool get supported;

  /// 读盘；文件不存在或损坏返回 null
  Future<Map<String, dynamic>?> load();

  /// 写盘
  Future<void> save(Map<String, dynamic> data);
}

/// 桌面端用文件实现
CanvasPersistence createPersistence() => _FilePersistence();

class _FilePersistence implements CanvasPersistence {
  @override
  bool get supported => true;

  /// 数据文件：文档目录 / task_canvas / canvas.json
  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/task_canvas');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return File('${folder.path}/canvas.json');
  }

  @override
  Future<Map<String, dynamic>?> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final text = await file.readAsString();
      final data = jsonDecode(text);
      if (data is Map<String, dynamic>) return data;
      return null;
    } catch (_) {
      // 文件损坏或读不到都当作没有存盘，不让启动崩掉
      return null;
    }
  }

  @override
  Future<void> save(Map<String, dynamic> data) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(data));
  }
}
