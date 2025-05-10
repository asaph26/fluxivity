import 'dart:async';

import '../plugins/plugin_abstract.dart';
import 'reactive.dart';
import 'snapshot.dart';

/// Extension methods on [List] to create reactive lists.
///
/// These extensions allow regular Dart lists to be converted into reactive lists
/// that automatically track changes and emit notifications when the list is modified.
///
/// Example usage:
/// ```dart
/// // Create a reactive list
/// final numbers = [1, 2, 3].reactive;
///
/// // Listen for changes
/// numbers.stream.listen((snapshot) {
///   print('List changed from ${snapshot.oldValue} to ${snapshot.newValue}');
/// });
///
/// // Modify the list (triggers notification)
/// numbers.value.add(4);
/// numbers.value = [...numbers.value, 5, 6]; // Replace the entire list
/// ```
extension ReactiveListExtensions<E> on List<E> {
  /// Creates a reactive list from this list.
  ///
  /// The returned [Reactive] instance will contain a copy of the original list,
  /// so modifications to the original list won't affect the reactive list.
  ///
  /// Example:
  /// ```dart
  /// final fruits = ['apple', 'banana', 'orange'].reactive;
  /// print(fruits.value); // [apple, banana, orange]
  ///
  /// // Update the reactive list
  /// fruits.value.add('grape');
  /// fruits.value = [...fruits.value];  // Trigger notification
  /// print(fruits.value); // [apple, banana, orange, grape]
  /// ```
  Reactive<List<E>> get reactive {
    return Reactive<List<E>>(List<E>.from(this));
  }

  /// Creates a reactive list with custom middleware from this list.
  ///
  /// This method is similar to [reactive], but allows you to provide middleware
  /// to customize the behavior of the reactive list.
  ///
  /// Parameters:
  /// * [middlewares]: A list of [FluxivityMiddleware] instances to apply to the reactive list.
  ///
  /// Example:
  /// ```dart
  /// // Create a reactive list with logging middleware
  /// final tasks = ['Buy groceries', 'Clean house'].toReactive(
  ///   middlewares: [LoggingMiddleware<List<String>>()],
  /// );
  ///
  /// tasks.value.add('Pay bills'); // This will be logged by the middleware
  /// tasks.value = [...tasks.value];  // Trigger notification and logging
  /// ```
  Reactive<List<E>> toReactive(
      {List<FluxivityMiddleware<List<E>>>? middlewares}) {
    return Reactive<List<E>>(List<E>.from(this), middlewares: middlewares);
  }
}

/// Helper extension methods for reactive lists.
///
/// These extensions provide utility methods for working with reactive lists,
/// such as adding effects and unwrapping the reactive container.
extension ReactiveListHelpers<E> on Reactive<List<E>> {
  /// Adds an effect that runs whenever the list changes.
  ///
  /// An effect is a function that gets called when the list changes. It receives
  /// a [Snapshot] containing both the old and new list values.
  ///
  /// Example:
  /// ```dart
  /// final items = ['Item 1'].reactive;
  ///
  /// // Add an effect to log changes
  /// items.addEffect((snapshot) {
  ///   print('List changed: ${snapshot.oldValue} -> ${snapshot.newValue}');
  /// });
  ///
  /// // Add an effect to persist changes
  /// items.addEffect((snapshot) {
  ///   saveToStorage('items', snapshot.newValue);
  /// });
  ///
  /// items.value.add('Item 2');
  /// items.value = [...items.value]; // Both effects will trigger
  /// ```
  StreamSubscription<Snapshot<List<E>>> addEffect(
      Function(Snapshot<List<E>>) effect) {
    return stream.listen(effect);
  }

  /// Returns the non-reactive list value.
  ///
  /// This method provides direct access to the underlying list. It's useful
  /// when you need to pass the list to APIs that don't work with [Reactive].
  ///
  /// Note: Changes to the returned list won't automatically trigger notifications.
  /// You need to trigger a notification manually by reassigning the list to the
  /// reactive value, for example: `reactive.value = List.from(reactive.value)`.
  ///
  /// Example:
  /// ```dart
  /// final items = ['Item 1', 'Item 2'].reactive;
  ///
  /// // Get the raw list
  /// final rawList = items.unwrap();
  /// print(rawList); // [Item 1, Item 2]
  ///
  /// // Use with APIs that require a regular list
  /// final sorted = items.unwrap()..sort();
  /// ```
  List<E> unwrap() {
    return value;
  }
}
