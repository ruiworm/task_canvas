// Web 预览用持久化：没有本地文件可写，数据只保留在内存里。
// 接口与 persistence_io.dart 保持一致，由 persistence.dart 条件导出。

/// 画布数据的存取接口（桌面端实现见 persistence_io.dart）
abstract class CanvasPersistence {
  /// 是否真的能落盘（桌面端 true，Web 预览 false）
  bool get supported;

  /// 读盘；文件不存在或损坏返回 null
  Future<Map<String, dynamic>?> load();

  /// 写盘
  Future<void> save(Map<String, dynamic> data);
}

/// Web 下的空实现：读不到旧数据，保存也不落盘
CanvasPersistence createPersistence() => _MemoryPersistence();

class _MemoryPersistence implements CanvasPersistence {
  @override
  bool get supported => false;

  @override
  Future<Map<String, dynamic>?> load() async => null;

  @override
  Future<void> save(Map<String, dynamic> data) async {}
}
