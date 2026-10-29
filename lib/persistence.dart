// 持久化接口的条件导出。
// 桌面端（dart:io 可用）走 persistence_io.dart 写真实文件；
// Web 下没有本地文件，走 persistence_web.dart 的内存空实现，数据只保留在内存里。
export 'persistence_web.dart' if (dart.library.io) 'persistence_io.dart';
