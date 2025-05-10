import 'dart:async';

import '../plugins/plugin_abstract.dart';
import 'reactive.dart';
import 'snapshot.dart';

/// Extension methods on [Map] to create reactive maps.
///
/// These extensions allow regular Dart maps to be converted into reactive maps
/// that automatically track changes and emit notifications when the map is modified.
///
/// Example usage:
/// ```dart
/// // Create a reactive map
/// final userPrefs = {'theme': 'dark', 'fontSize': 14}.reactive;
///
/// // Listen for changes
/// userPrefs.stream.listen((snapshot) {
///   print('Preferences changed!');
///   print('Old: ${snapshot.oldValue}');
///   print('New: ${snapshot.newValue}');
/// });
///
/// // Modify the map (triggers notification)
/// userPrefs.value['fontSize'] = 16;
/// userPrefs.value = Map.from(userPrefs.value); // Trigger notification
/// ```
extension ReactiveMapExtensions<K, V> on Map<K, V> {
  /// Creates a reactive map from this map.
  ///
  /// The returned [Reactive] instance will contain a copy of the original map,
  /// so modifications to the original map won't affect the reactive map.
  ///
  /// Example:
  /// ```dart
  /// final user = {'name': 'John', 'age': 30}.reactive;
  /// print(user.value); // {name: John, age: 30}
  ///
  /// // Update the reactive map
  /// user.value['email'] = 'john@example.com';
  /// user.value = Map.from(user.value); // Trigger notification
  /// print(user.value); // {name: John, age: 30, email: john@example.com}
  /// ```
  ///
  /// Note: When you modify a reactive map's entries, you need to reassign the map
  /// to trigger a notification, since maps are mutable objects.
  Reactive<Map<K, V>> get reactive {
    return Reactive<Map<K, V>>(Map<K, V>.from(this));
  }

  /// Creates a reactive map with custom middleware from this map.
  ///
  /// This method is similar to [reactive], but allows you to provide middleware
  /// to customize the behavior of the reactive map.
  ///
  /// Parameters:
  /// * [middlewares]: A list of [FluxivityMiddleware] instances to apply to the reactive map.
  ///
  /// Example:
  /// ```dart
  /// // Create a reactive map with logging middleware
  /// final settings = {'notifications': true, 'darkMode': false}.toReactive(
  ///   middlewares: [LoggingMiddleware<Map<String, bool>>()],
  /// );
  ///
  /// settings.value['sound'] = true; // This will be logged by the middleware
  /// settings.value = Map.from(settings.value); // Trigger notification and logging
  /// ```
  Reactive<Map<K, V>> toReactive(
      {List<FluxivityMiddleware<Map<K, V>>>? middlewares}) {
    return Reactive<Map<K, V>>(Map<K, V>.from(this), middlewares: middlewares);
  }
}

/// Helper extension methods for reactive maps.
///
/// These extensions provide utility methods for working with reactive maps,
/// such as adding effects and unwrapping the reactive container.
extension ReactiveMapHelpers<K, V> on Reactive<Map<K, V>> {
  /// Adds an effect that runs whenever the map changes.
  ///
  /// An effect is a function that gets called when the map changes. It receives
  /// a [Snapshot] containing both the old and new map values.
  ///
  /// Example:
  /// ```dart
  /// final profile = {'name': 'Alice'}.reactive;
  ///
  /// // Add an effect to log changes
  /// profile.addEffect((snapshot) {
  ///   print('Profile changed:');
  ///   snapshot.newValue.forEach((key, value) {
  ///     if (snapshot.oldValue[key] != value) {
  ///       print('  $key: ${snapshot.oldValue[key]} -> $value');
  ///     }
  ///   });
  /// });
  ///
  /// profile.value['age'] = 28;
  /// profile.value = Map.from(profile.value); // Effect will trigger
  /// ```
  ///
  /// Note: To make modifications trigger effects, you must assign the modified map
  /// back to the reactive value, typically using `value = Map.from(value)`.
  StreamSubscription<Snapshot<Map<K, V>>> addEffect(
      Function(Snapshot<Map<K, V>>) effect) {
    return stream.listen(effect);
  }

  /// Returns the non-reactive map value.
  ///
  /// This method provides direct access to the underlying map. It's useful
  /// when you need to pass the map to APIs that don't work with [Reactive].
  ///
  /// Note: Changes to the returned map won't automatically trigger notifications.
  /// You need to trigger a notification manually by reassigning the map to the
  /// reactive value, for example: `reactive.value = Map.from(reactive.value)`.
  ///
  /// Example:
  /// ```dart
  /// final config = {'debug': true, 'logLevel': 'info'}.reactive;
  ///
  /// // Get the raw map
  /// final rawMap = config.unwrap();
  /// print(rawMap); // {debug: true, logLevel: info}
  ///
  /// // Use with APIs that require a regular map
  /// someFunction(config.unwrap());
  /// ```
  Map<K, V> unwrap() {
    return value;
  }
}
