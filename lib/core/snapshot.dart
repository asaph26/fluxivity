/// A container class that holds both the previous and current values during a state change.
///
/// The [Snapshot] class is used throughout Fluxivity to represent state transitions.
/// It's passed to stream listeners and effect callbacks to provide context about what changed.
///
/// Example usage:
/// ```dart
/// final counter = Reactive(0);
///
/// // Add an effect that can access both old and new values
/// counter.addEffect((Snapshot<int> snapshot) {
///   print('Counter changed from ${snapshot.oldValue} to ${snapshot.newValue}');
/// });
///
/// counter.value = 1; // Prints: "Counter changed from 0 to 1"
/// ```
class Snapshot<T> {
  /// The previous value before the state change occurred.
  final T oldValue;

  /// The new current value after the state change.
  final T newValue;

  /// Creates a new snapshot containing both old and new values.
  ///
  /// This is typically created internally by [Reactive] and [Computed] instances
  /// when a value changes, and then passed to listeners and effect callbacks.
  Snapshot(this.oldValue, this.newValue);

  @override
  String toString() => 'Snapshot(old: $oldValue, new: $newValue)';
}
