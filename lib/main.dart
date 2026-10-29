// 入口：MaterialApp + ChangeNotifierProvider + CanvasScreen。

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'store.dart';
import 'widgets/canvas_view.dart';

void main() {
  runApp(const TaskCanvasApp());
}

class TaskCanvasApp extends StatelessWidget {
  const TaskCanvasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // 启动时读盘，没有存盘就新建一张带欢迎卡片的空画布
      create: (_) => CanvasStore()..init(),
      child: MaterialApp(
        title: '任务画布',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE8590C),
            surface: const Color(0xFFFAF7F2),
          ),
          scaffoldBackgroundColor: const Color(0xFFFAF7F2),
          useMaterial3: true,
        ),
        home: const CanvasScreen(),
      ),
    );
  }
}
