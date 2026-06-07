import 'dart:async';

import '../models/pet_event.dart';

/// 宠物事件总线
///
/// 解耦事件生产者和消费者。
/// 页面触发事件 → EventBus → Orchestrator 处理
class PetEventBus {
  PetEventBus._();

  static final instance = PetEventBus._();

  final _controller = StreamController<PetEvent>.broadcast();

  /// 事件流
  Stream<PetEvent> get stream => _controller.stream;

  /// 发送事件
  void emit(PetEvent event) {
    _controller.add(event);
  }

  /// 监听特定类型的事件
  Stream<PetEvent> onType(PetEventType type) {
    return stream.where((e) => e.type == type);
  }

  /// 监听特定模块的事件
  Stream<PetEvent> onModule(String module) {
    return stream.where((e) => e.module == module);
  }

  void dispose() {
    _controller.close();
  }
}
