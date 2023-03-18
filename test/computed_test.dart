@TestOn('vm')

import 'package:test/test.dart';
import 'package:fluxivity/fluxivity.dart';

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
  });
}
