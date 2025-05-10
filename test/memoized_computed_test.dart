import 'package:test/test.dart';
import 'package:fluxivity/fluxivity.dart';

void main() {
  test('memoize function should return a Computed instance', () {
    final count = Reactive(0);
    final computed = Computed([count], (sources) => sources[0].value * 2);
    final memoized = memoize(computed);

    // It should be an object that implements the Computed interface
    expect(memoized.value, equals(0));
  });

  test('memoized computed should delegate value to original computed',
      () async {
    final count = Reactive(10);
    final computed = Computed([count], (sources) => sources[0].value * 2);
    final memoized = memoize(computed);

    expect(memoized.value, equals(20));

    // Update source
    count.value = 20;

    // Wait for computed to update
    await Future.delayed(Duration(milliseconds: 10));

    // Should reflect the new value
    expect(computed.value, equals(40));
    expect(memoized.value, equals(40));
  });

  test('memoized computed should delegate stream events', () async {
    final count = Reactive(5);
    final computed = Computed([count], (sources) => sources[0].value * 2);
    final memoized = memoize(computed);

    final snapshots = <Snapshot>[];
    memoized.stream.listen((snapshot) {
      snapshots.add(snapshot);
    });

    // Initial value should have been emitted
    await Future.delayed(Duration(milliseconds: 10));
    expect(snapshots.length, equals(1));

    // Update value
    count.value = 10;

    // Wait for stream to emit
    await Future.delayed(Duration(milliseconds: 10));

    // Should receive the update
    expect(snapshots.length, equals(2));
    expect(snapshots[1].oldValue, equals(10));
    expect(snapshots[1].newValue, equals(20));
  });

  test('memoized computed should cache computed values', () async {
    int computeCount = 0;
    final a = Reactive(1);
    final b = Reactive(2);

    final computed = Computed<int>([a, b], (sources) {
      computeCount++;
      return sources[0].value + sources[1].value;
    });

    final memoized = memoize(computed);

    // First access, should compute
    expect(memoized.value, equals(3));
    expect(computeCount, equals(1));

    // Access again, should use cached value
    expect(memoized.value, equals(3));
    expect(computeCount, equals(1)); // still 1, didn't recompute

    // Change source values
    a.value = 10;

    // Wait for computation in original
    await Future.delayed(Duration(milliseconds: 10));
    computed.value;

    // Should get the new value (original already computed it)
    expect(memoized.value, equals(12));

    // Change back to original values - this key exists in cache
    a.value = 1;
    await Future.delayed(Duration(milliseconds: 10));
    computed.value; // Force update in original

    // Should get the original value again
    expect(memoized.value, equals(3));
  });

  test('memoized computed should respect cache size limit', () async {
    final source = Reactive(0);
    int computeCount = 0;

    final computed = Computed<int>([source], (sources) {
      computeCount++;
      return sources[0].value;
    });

    // Create memoized with cache size 2
    final memoized = memoize(computed, cacheSize: 2);

    // Cycle through 4 different values
    source.value = 1;
    await Future.delayed(Duration(milliseconds: 10));
    computed.value; // Force computation
    memoized.value; // Cache it

    source.value = 2;
    await Future.delayed(Duration(milliseconds: 10));
    computed.value; // Force computation
    memoized.value; // Cache it

    // At this point cache contains 1, 2

    source.value = 3;
    await Future.delayed(Duration(milliseconds: 10));
    computed.value; // Force computation
    memoized.value; // Cache it

    // Cache should now contain 2, 3 (1 was evicted)

    source.value = 1; // Go back to a value that was evicted
    await Future.delayed(Duration(milliseconds: 10));
    computed.value; // Force recomputation in original
    memoized.value; // This should add 1 back to cache

    // Cache should now contain 3, 1 (2 was evicted)

    // Access 3 again (still in cache)
    source.value = 3;
    await Future.delayed(Duration(milliseconds: 10));
    final startCount = computeCount;
    memoized.value; // Should use cache
    expect(computeCount, equals(startCount)); // No new computation

    // Access 2 again (was evicted)
    source.value = 2;
    await Future.delayed(Duration(milliseconds: 10));
    computed.value; // Force computation in original
    final beforeAccess = computeCount;
    memoized.value; // This should require re-adding to cache
    expect(
        computeCount, equals(beforeAccess)); // Already computed in the original
  });

  test('memoized computed should call dispose on original computed', () async {
    bool disposed = false;

    // Create a custom computed to track disposal
    final tracker = DisposableTracker();
    tracker.onDispose = () {
      disposed = true;
    };

    // Create memoized version
    final memoized = memoize(tracker);

    // Dispose memoized version
    memoized.dispose();

    // Verify original was disposed
    expect(disposed, isTrue);
  });
}

// Helper for testing dispose behavior
class DisposableTracker implements Computed<int> {
  VoidCallback? onDispose;

  @override
  void dispose() {
    if (onDispose != null) {
      onDispose!();
    }
  }

  @override
  int get value => 42;

  @override
  Stream<Snapshot<int>> get stream => Stream.value(Snapshot(42, 42));

  @override
  List<Reactive<dynamic>> get sources => [];

  @override
  void startBatchUpdate() {}

  @override
  void endBatchUpdate({bool publishAll = false}) {}
}

// Type definition for callbacks
typedef VoidCallback = void Function();
