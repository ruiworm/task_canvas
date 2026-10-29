// 冒烟测试：画布能启动，工具栏、欢迎卡片、进度统计正常出现。
//
// 注意：测试不用真实持久化（平台通道 + 真实文件 IO 在
// flutter_test 的 FakeAsync 里跑不完），而是注入一个内存实现。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:task_canvas/persistence.dart';
import 'package:task_canvas/store.dart';
import 'package:task_canvas/widgets/canvas_view.dart';

/// 测试用内存持久化：不落盘，只放内存
class _MemoryPersistence implements CanvasPersistence {
  Map<String, dynamic>? _data;

  @override
  bool get supported => true;

  @override
  Future<Map<String, dynamic>?> load() async => _data;

  @override
  Future<void> save(Map<String, dynamic> data) async {
    _data = data;
  }
}

void main() {
  testWidgets('任务画布启动后显示工具栏与欢迎卡片', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) =>
              CanvasStore(persistence: _MemoryPersistence())..init(),
          child: const CanvasScreen(),
        ),
      ),
    );
    // 读盘是异步的，pump 两次让 init 跑完、界面重建
    await tester.pump();
    await tester.pump();

    expect(find.text('新建卡片'), findsOneWidget);
    expect(find.text('新建分组'), findsOneWidget);
    expect(find.text('连线'), findsOneWidget);
    expect(find.text('欢迎使用任务画布'), findsOneWidget);
    expect(find.text('已完成 0 / 1 · 0%'), findsOneWidget);
  });
}
