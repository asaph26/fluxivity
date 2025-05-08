@TestOn('vm')

import 'package:test/test.dart';
import 'package:fluxivity/fluxivity.dart';

class TestMiddleware<T> extends FluxivityMiddleware<T> {
  final List<String> events = [];
  bool emitValue = true;
  
  @override
  void beforeUpdate(T oldValue, T newValue) {
    events.add('beforeUpdate: $oldValue -> $newValue');
  }
  
  @override
  void afterUpdate(T oldValue, T newValue) {
    events.add('afterUpdate: $oldValue -> $newValue');
  }
  
  @override
  void onError(Object error, StackTrace stackTrace) {
    events.add('onError: $error');
  }
  
  @override
  bool shouldEmit(T oldValue, T newValue) {
    return emitValue;
  }
}

void main() {
  group('Reactive', () {
    test('should store and retrieve the value', () {
      final reactive = Reactive<int>(42);
      expect(reactive.value, 42);
    });

    test('should update the value and notify listeners', () async {
      final reactive = Reactive<int>(0);
      final values = <int>[];

      reactive.addEffect((value) {
        values.add(value.newValue);
      });

      reactive.value = 1;
      reactive.value = 2;
      reactive.value = 3;

      // Wait for effects to process
      await Future.delayed(const Duration(milliseconds: 100));

      expect(values, [0, 1, 2, 3]);
    });

    test('should dispose the stream', () async {
      final reactive = Reactive<int>(0);
      final values = <int>[];

      reactive.addEffect((value) {
        values.add(value.newValue);
      });

      reactive.value = 1;
      reactive.dispose();

      expect(() => reactive.value = 2, throwsStateError);
      expect(() => reactive.value = 3, throwsStateError);

      // Wait for effects to process
      await Future.delayed(const Duration(milliseconds: 100));

      expect(values, [0, 1]);
    });
    
    test('should not update value if the new value is equal to the current value', () async {
      final reactive = Reactive<int>(5);
      var updateCount = 0;
      
      reactive.stream.listen((_) {
        updateCount++;
      });
      
      // Wait for initial emission to be processed
      await Future.delayed(Duration.zero);
      
      // Reset counter after initial emission
      updateCount = 0;
      
      reactive.value = 5; // Same value, should not trigger an update
      reactive.value = 5; // Same value, should not trigger an update
      
      await Future.delayed(Duration.zero);
      
      expect(updateCount, 0); // No emissions for same value
    });
    
    test('should work with middleware', () async {
      final middleware = TestMiddleware<int>();
      final reactive = Reactive<int>(0, middlewares: [middleware]);
      final values = <int>[];
      
      reactive.stream.listen((snapshot) {
        values.add(snapshot.newValue);
      });
      
      reactive.value = 1;
      reactive.value = 2;
      
      // Wait for updates to propagate
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(middleware.events.length, 4); // 2 updates x (before + after)
      expect(values, [0, 1, 2]);
    });
    
    test('should not emit updates when middleware shouldEmit returns false', () async {
      final middleware = TestMiddleware<int>();
      middleware.emitValue = false;
      
      final reactive = Reactive<int>(0, middlewares: [middleware]);
      final values = <int>[];
      
      reactive.stream.listen((snapshot) {
        values.add(snapshot.newValue);
      });
      
      reactive.value = 1;
      reactive.value = 2;
      
      // Wait for updates to propagate
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(middleware.events.length, 4); // Middleware still processes updates
      expect(values, [0]); // But no new values emitted to stream
    });
    
    test('should batch updates correctly', () async {
      final reactive = Reactive<int>(0);
      final values = <int>[];
      
      reactive.stream.listen((snapshot) {
        values.add(snapshot.newValue);
      });
      
      reactive.startBatchUpdate();
      reactive.value = 1;
      reactive.value = 2;
      reactive.value = 3;
      reactive.endBatchUpdate();
      
      // Wait for batch update to complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(values, [0, 3]); // Only initial and final value
    });
    
    test('should publish all updates when publishAll is true', () async {
      final reactive = Reactive<int>(0);
      final values = <int>[];
      
      reactive.stream.listen((snapshot) {
        values.add(snapshot.newValue);
      });
      
      reactive.startBatchUpdate();
      reactive.value = 1;
      reactive.value = 2;
      reactive.value = 3;
      reactive.endBatchUpdate(publishAll: true);
      
      // Wait for batch update to complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(values, [0, 1, 2, 3]); // All values published
    });
    
    test('should support nested batch updates', () async {
      final reactive = Reactive<int>(0);
      final values = <int>[];
      
      reactive.stream.listen((snapshot) {
        values.add(snapshot.newValue);
      });
      
      reactive.startBatchUpdate(); // Outer batch
      reactive.value = 1;
      
      reactive.startBatchUpdate(); // Inner batch
      reactive.value = 2;
      reactive.value = 3;
      reactive.endBatchUpdate(); // End inner batch (no publish yet)
      
      reactive.value = 4;
      reactive.endBatchUpdate(); // End outer batch (publish now)
      
      // Wait for updates to propagate
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(values, [0, 4]); // Only initial and final value
    });
  });
}
