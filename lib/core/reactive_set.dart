import 'dart:async';

import '../plugins/plugin_abstract.dart';
import 'reactive.dart';
import 'snapshot.dart';

/// Extension methods on [Set] to create reactive sets.
///
/// These extensions allow regular Dart sets to be converted into reactive sets
/// that automatically track changes and emit notifications when the set is modified.
/// Sets are particularly useful for collections where each element should be unique.
///
/// Example usage:
/// ```dart
/// // Create a reactive set
/// final activeUsers = {'user1', 'user2', 'admin'}.reactive;
///
/// // Listen for changes
/// activeUsers.stream.listen((snapshot) {
///   final added = snapshot.newValue.difference(snapshot.oldValue);
///   final removed = snapshot.oldValue.difference(snapshot.newValue);
///   print('Added: $added, Removed: $removed');
/// });
///
/// // Modify the set (triggers notification)
/// activeUsers.value.add('user3');
/// activeUsers.value = Set.from(activeUsers.value); // Trigger notification
/// ```
extension ReactiveSetExtensions<E> on Set<E> {
  /// Creates a reactive set from this set.
  ///
  /// The returned [Reactive] instance will contain a copy of the original set,
  /// so modifications to the original set won't affect the reactive set.
  ///
  /// Example:
  /// ```dart
  /// final tags = {'dart', 'flutter', 'reactive'}.reactive;
  /// print(tags.value); // {dart, flutter, reactive}
  ///
  /// // Update the reactive set
  /// tags.value.add('state');
  /// tags.value = Set.from(tags.value); // Trigger notification
  /// print(tags.value); // {dart, flutter, reactive, state}
  ///
  /// // Adding a duplicate has no effect (sets only contain unique elements)
  /// tags.value.add('dart');
  /// print(tags.value); // {dart, flutter, reactive, state}
  /// ```
  ///
  /// Note: When you modify a reactive set's elements, you need to reassign the set
  /// to trigger a notification, since sets are mutable objects.
  Reactive<Set<E>> get reactive {
    return Reactive<Set<E>>(Set<E>.from(this));
  }

  /// Creates a reactive set with custom middleware from this set.
  ///
  /// This method is similar to [reactive], but allows you to provide middleware
  /// to customize the behavior of the reactive set.
  ///
  /// Parameters:
  /// * [middlewares]: A list of [FluxivityMiddleware] instances to apply to the reactive set.
  ///
  /// Example:
  /// ```dart
  /// // Create a reactive set with logging middleware
  /// final selectedItems = {'item1', 'item3'}.toReactive(
  ///   middlewares: [LoggingMiddleware<Set<String>>()],
  /// );
  ///
  /// selectedItems.value.add('item4'); // This will be logged by the middleware
  /// selectedItems.value = Set.from(selectedItems.value); // Trigger notification and logging
  /// ```
  Reactive<Set<E>> toReactive(
      {List<FluxivityMiddleware<Set<E>>>? middlewares}) {
    return Reactive<Set<E>>(Set<E>.from(this), middlewares: middlewares);
  }
}

/// Helper extension methods for reactive sets.
///
/// These extensions provide utility methods for working with reactive sets,
/// such as adding effects and unwrapping the reactive container.
extension ReactiveSetHelpers<E> on Reactive<Set<E>> {
  /// Adds an effect that runs whenever the set changes.
  ///
  /// An effect is a function that gets called when the set changes. It receives
  /// a [Snapshot] containing both the old and new set values.
  ///
  /// Example:
  /// ```dart
  /// final permissions = {'read', 'write'}.reactive;
  ///
  /// // Add an effect to log changes
  /// permissions.addEffect((snapshot) {
  ///   final added = snapshot.newValue.difference(snapshot.oldValue);
  ///   final removed = snapshot.oldValue.difference(snapshot.newValue);
  ///
  ///   if (added.isNotEmpty) {
  ///     print('Added permissions: $added');
  ///   }
  ///   if (removed.isNotEmpty) {
  ///     print('Removed permissions: $removed');
  ///   }
  /// });
  ///
  /// permissions.value.add('admin');
  /// permissions.value = Set.from(permissions.value); // Effect will trigger
  /// ```
  ///
  /// Note: To make modifications trigger effects, you must assign the modified set
  /// back to the reactive value, typically using `value = Set.from(value)`.
  StreamSubscription<Snapshot<Set<E>>> addEffect(
      Function(Snapshot<Set<E>>) effect) {
    return stream.listen(effect);
  }

  /// Returns the non-reactive set value.
  ///
  /// This method provides direct access to the underlying set. It's useful
  /// when you need to pass the set to APIs that don't work with [Reactive].
  ///
  /// Note: Changes to the returned set won't automatically trigger notifications.
  /// You need to trigger a notification manually by reassigning the set to the
  /// reactive value, for example: `reactive.value = Set.from(reactive.value)`.
  ///
  /// Example:
  /// ```dart
  /// final roles = {'user', 'editor'}.reactive;
  ///
  /// // Get the raw set
  /// final rawSet = roles.unwrap();
  /// print(rawSet); // {user, editor}
  ///
  /// // Use with APIs that require a regular set
  /// final intersection = rawSet.intersection(otherSet);
  /// ```
  Set<E> unwrap() {
    return value;
  }
}
