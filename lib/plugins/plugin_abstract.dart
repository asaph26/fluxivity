/// An abstract class defining the interface for middleware plugins in Fluxivity.
///
/// Middleware plugins allow you to intercept and modify the behavior of reactive state changes.
/// They can be used for various purposes such as logging, validation, persistence, or any
/// custom behavior you want to add to your reactive state.
///
/// Middleware implementations can be attached to both [Reactive] and [Computed] instances
/// and will be executed in the order they are provided.
///
/// Example of a simple logging middleware:
/// ```dart
/// class LoggingMiddleware<T> extends FluxivityMiddleware<T> {
///   @override
///   void beforeUpdate(T oldValue, T newValue) {
///     print('About to update from $oldValue to $newValue');
///   }
///
///   @override
///   void afterUpdate(T oldValue, T newValue) {
///     print('Updated from $oldValue to $newValue');
///   }
///
///   @override
///   void onError(Object error, StackTrace stackTrace) {
///     print('Error occurred: $error');
///   }
///
///   @override
///   bool shouldEmit(T oldValue, T newValue) {
///     return true; // Always emit the update
///   }
/// }
///
/// // Usage
/// final counter = Reactive(0, middlewares: [LoggingMiddleware<int>()]);
/// ```
abstract class FluxivityMiddleware<T> {
  /// Called immediately before a value is updated.
  ///
  /// This method can be used to perform actions or validations before a state change occurs.
  /// It is called after the decision to update the value has been made but before the internal
  /// state is actually modified.
  ///
  /// Parameters:
  /// * [oldValue]: The current value before the update
  /// * [newValue]: The proposed new value for the update
  void beforeUpdate(T oldValue, T newValue);

  /// Called immediately after a value has been updated.
  ///
  /// This method can be used to perform actions or side effects after a state change has occurred.
  /// It is called after the internal state has been modified but before any notifications
  /// are sent to listeners.
  ///
  /// Parameters:
  /// * [oldValue]: The previous value before the update
  /// * [newValue]: The new current value after the update
  void afterUpdate(T oldValue, T newValue);

  /// Called when an error occurs during computation in a [Computed] instance.
  ///
  /// This method is only relevant for middleware attached to [Computed] instances.
  /// It is called when the compute function throws an error.
  ///
  /// Parameters:
  /// * [error]: The error that was thrown
  /// * [stackTrace]: The stack trace of the error
  void onError(Object error, StackTrace stackTrace);

  /// Determines whether a value change should trigger a notification to listeners.
  ///
  /// This method can be used to filter or throttle updates based on custom logic.
  /// If any middleware returns false, the update will not be emitted to the stream.
  ///
  /// Parameters:
  /// * [oldValue]: The previous value before the update
  /// * [newValue]: The new current value after the update
  ///
  /// Returns:
  /// * `true` if the update should be emitted to listeners
  /// * `false` if the update should be suppressed
  bool shouldEmit(T oldValue, T newValue);
}
