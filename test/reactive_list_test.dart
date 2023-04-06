import 'package:test/test.dart';
import 'package:fluxivity/fluxivity.dart';

void main() {
  group('ReactiveList', () {
    test('should emit a stream when adding an element', () async {
      final reactiveList = [1, 2, 3].reactive;
      final updates = <List<int>>[];

      reactiveList.stream.listen((snapshot) {
        updates.add(snapshot.newValue);
      });

      reactiveList.value.add(4);

      // Wait for the stream to emit
      await Future.delayed(Duration.zero);

      expect(updates, [
        [1, 2, 3, 4],
      ]);
    });

    test('should emit a stream when removing an element', () async {
      final reactiveList = [1, 2, 3].reactive;
      final updates = <List<int>>[];

      reactiveList.stream.listen((snapshot) {
        updates.add(snapshot.newValue);
      });

      reactiveList.value.remove(2);

      // Wait for the stream to emit
      await Future.delayed(Duration.zero);

      expect(updates, [
        [1, 3],
      ]);
    });

    test('should emit a stream when updating an element using []=', () async {
      final reactiveList = [1, 2, 3].reactive;
      final updates = <List<int>>[];

      reactiveList.stream.listen((snapshot) {
        updates.add(snapshot.newValue);
      });

      reactiveList.value[1] = 4;

      // Wait for the stream to emit
      await Future.delayed(Duration.zero);

      expect(updates, [
        [1, 4, 3],
      ]);
    });
  });
}
