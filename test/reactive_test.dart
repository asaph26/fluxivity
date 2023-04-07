@TestOn('vm')

import 'package:test/test.dart';
import 'package:fluxivity/fluxivity.dart';

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
  });
}
