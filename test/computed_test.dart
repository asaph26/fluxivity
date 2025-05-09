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
  group('Computed', () {
    test('should compute initial value correctly', () {
      final reactiveA = Reactive<int>(5);
      final reactiveB = Reactive<int>(10);

      final computedSum = Computed<int>([reactiveA, reactiveB], (sources) {
        return sources[0].value + sources[1].value;
      });

      expect(computedSum.value, 15);
    });

    test('should update computed value when source values change', () async {
      final reactiveA = Reactive<int>(5);
      final reactiveB = Reactive<int>(10);

      final computedSum = Computed<int>([reactiveA, reactiveB], (sources) {
        return sources[0].value + sources[1].value;
      });

      reactiveA.value = 8;
      reactiveB.value = 12;

      await Future.delayed(const Duration(milliseconds: 100));

      expect(computedSum.value, 20);
    });

    test(
        'should not update computed value when source values change, but computed value remains the same',
        () async {
      final reactiveA = Reactive<int>(4);
      final reactiveB = Reactive<int>(10);

      final computedEvenSum = Computed<bool>([reactiveA, reactiveB],
          (sources) => (sources[0].value + sources[1].value) % 2 == 0);

      final values = <bool>[];
      computedEvenSum.stream.listen((snapshot) {
        values.add(snapshot.newValue);
      });

      reactiveA.value = 8;
      reactiveB.value = 12;

      // Wait for effects to process
      await Future.delayed(const Duration(milliseconds: 100));

      // There should be only one value in the values list, which is the initial value
      expect(values.length, 1);
      expect(computedEvenSum.value, true);
    });

    test('should handle errors in compute function', () async {
      final reactiveA = Reactive<int>(5);
      final middleware = TestMiddleware<String>();

      final computed = Computed<String>([reactiveA], (sources) {
        final value = sources[0].value;
        if (value < 0) {
          throw Exception('Value cannot be negative');
        }
        return 'Value: $value';
      }, middlewares: [middleware]);

      expect(computed.value, 'Value: 5');

      reactiveA.value = -10;
      await Future.delayed(const Duration(milliseconds: 100));

      // Value should not change
      expect(computed.value, 'Value: 5');

      // Error should be handled by middleware
      expect(middleware.events.length, 2);
      expect(
          middleware.events.any((event) => event.contains('onError')), isTrue);
    });

    test('should work with middleware', () async {
      final reactiveA = Reactive<int>(5);
      final reactiveB = Reactive<int>(10);
      final middleware = TestMiddleware<int>();

      final computed = Computed<int>([reactiveA, reactiveB], (sources) {
        return sources[0].value + sources[1].value;
      }, middlewares: [middleware]);

      final values = <int>[];
      computed.stream.listen((snapshot) {
        values.add(snapshot.newValue);
      });

      reactiveA.value = 8;

      // Wait for updates to propagate
      await Future.delayed(const Duration(milliseconds: 100));

      expect(middleware.events.length, 2); // beforeUpdate + afterUpdate
      expect(values, [15, 18]);
    });

    test('should not emit updates when middleware shouldEmit returns false',
        () async {
      final reactiveA = Reactive<int>(5);
      final reactiveB = Reactive<int>(10);
      final middleware = TestMiddleware<int>();
      middleware.emitValue = false;

      final computed = Computed<int>([reactiveA, reactiveB], (sources) {
        return sources[0].value + sources[1].value;
      }, middlewares: [middleware]);

      final values = <int>[];
      computed.stream.listen((snapshot) {
        values.add(snapshot.newValue);
      });

      reactiveA.value = 8;

      // Wait for updates to propagate
      await Future.delayed(const Duration(milliseconds: 100));

      expect(middleware.events.length, 2); // Middleware still processes updates
      expect(values, [15]); // But no new values emitted to stream
    });

    test('should handle multiple dependencies correctly', () async {
      final reactiveA = Reactive<int>(5);
      final reactiveB = Reactive<int>(10);
      final reactiveC = Reactive<int>(15);

      final computed =
          Computed<int>([reactiveA, reactiveB, reactiveC], (sources) {
        return sources[0].value + sources[1].value + sources[2].value;
      });

      final values = <int>[];
      computed.stream.listen((snapshot) {
        values.add(snapshot.newValue);
      });

      expect(computed.value, 30);

      reactiveA.value = 10;
      await Future.delayed(const Duration(milliseconds: 50));

      reactiveB.value = 20;
      await Future.delayed(const Duration(milliseconds: 50));

      reactiveC.value = 30;
      await Future.delayed(const Duration(milliseconds: 50));

      expect(computed.value, 60);
      expect(values, [30, 35, 45, 60]);
    });

    test('should handle chain of computed values', () async {
      final reactiveA = Reactive<int>(5);

      final computedDouble = Computed<int>([reactiveA], (sources) {
        return sources[0].value * 2;
      });

      // Wrap computed in a reactive to use as dependency
      final reactiveComputed = Reactive<int>(computedDouble.value);
      computedDouble.stream.listen((snapshot) {
        reactiveComputed.value = snapshot.newValue;
      });

      final computedSquare = Computed<int>([reactiveComputed], (sources) {
        return sources[0].value * sources[0].value;
      });

      expect(reactiveA.value, 5);
      expect(computedDouble.value, 10);
      expect(computedSquare.value, 100);

      reactiveA.value = 10;
      await Future.delayed(const Duration(milliseconds: 100));

      expect(reactiveA.value, 10);
      expect(computedDouble.value, 20);
      expect(computedSquare.value, 400);
    });

    test('should batch updates correctly', () async {
      final reactiveA = Reactive<int>(5);
      final reactiveB = Reactive<int>(10);

      final computed = Computed<int>([reactiveA, reactiveB], (sources) {
        return sources[0].value + sources[1].value;
      });

      final values = <int>[];
      computed.stream.listen((snapshot) {
        values.add(snapshot.newValue);
      });

      computed.startBatchUpdate();
      reactiveA.value = 15;
      reactiveB.value = 25;
      computed.endBatchUpdate();

      // Wait for batch update to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Initial value + final value after batch
      expect(values, [15, 40]);
    });

    test('should dispose correctly', () async {
      final reactiveA = Reactive<int>(5);
      final computed = Computed<int>([reactiveA], (sources) {
        return sources[0].value * 2;
      });

      // Subscribe to ensure the stream is active
      bool wasCalled = false;
      final subscription = computed.stream.listen((_) {
        wasCalled = true;
      });

      // Wait to ensure the subscription is active
      await Future.delayed(const Duration(milliseconds: 10));

      computed.dispose();
      await Future.delayed(const Duration(milliseconds: 10));

      try {
        // Should not throw errors when the source is updated after disposal
        reactiveA.value = 10;
        await Future.delayed(const Duration(milliseconds: 100));

        // Cancel subscription to avoid interference with other tests
        subscription.cancel();

        // Test that no error was thrown
        expect(true, isTrue);
      } catch (e) {
        fail('Exception was thrown after disposal: $e');
      }
    });
  });
}
