import '../plugin_abstract.dart';

/// A prebuilt middleware for logging state changes in Fluxivity.
///
/// This middleware logs all state changes to the console, including:
/// - Value updates (before and after)
/// - Errors during computation
///
/// It can be used as a debugging tool to track state changes throughout your application.
///
/// Example usage:
/// ```dart
/// // Add logging to a reactive value
/// final counter = Reactive(0, middlewares: [LoggingMiddleware<int>()]);
///
/// // Add logging to a computed value
/// final doubled = Computed([counter], (sources) {
///   return sources[0].value * 2;
/// }, middlewares: [LoggingMiddleware<int>()]);
///
/// // Updates will be logged to the console
/// counter.value = 5;
/// // Console output:
/// // Before update: 0 -> 5
/// // After update: 0 -> 5
/// // Before update: 0 -> 10 (for the computed value)
/// // After update: 0 -> 10 (for the computed value)
/// ```
///
/// This middleware always returns true from [shouldEmit], so it never
/// interferes with the normal behavior of state updates.
class LoggingMiddleware<T> extends FluxivityMiddleware<T> {
  @override
  void beforeUpdate(T oldValue, T newValue) {
    print("Before update: $oldValue -> $newValue");
  }

  @override
  void afterUpdate(T oldValue, T newValue) {
    print("After update: $oldValue -> $newValue");
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    print("Error: $error\n$stackTrace");
  }

  @override
  bool shouldEmit(T oldValue, T newValue) {
    return true;
  }
}
