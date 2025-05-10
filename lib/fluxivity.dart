/// A lightweight reactive state management library for Dart applications.
///
/// Fluxivity enables you to create reactive properties that automatically track state changes
/// and propagate updates to dependent components. It provides a simple yet powerful way to
/// build reactive applications with minimal boilerplate.
///
/// The library consists of several core components:
/// * [Reactive]: Represents a value that can be observed and modified, with changes automatically
///   tracked and propagated to listeners.
/// * [Computed]: Represents a derived value that automatically updates when its dependencies change.
/// * [Snapshot]: Contains the old and new values during a state change.
/// * Reactive Collections: Extensions for Lists, Maps, and Sets for reactive collection handling.
/// * Middleware: Extensible plugin system to add custom behaviors to reactive state changes.
///
/// Example usage:
/// ```dart
/// // Create reactive values
/// final count = Reactive(0);
/// final message = Reactive('Hello');
///
/// // Create a computed value that depends on other reactive values
/// final displayText = Computed([count, message], (sources) {
///   return '${sources[1].value} (${sources[0].value})';
/// });
///
/// // Access current values
/// print(count.value); // 0
/// print(displayText.value); // 'Hello (0)'
///
/// // Update values and watch changes propagate
/// count.value = 1;
/// print(displayText.value); // 'Hello (1)'
/// ```
library fluxivity;

export 'core/reactive.dart';
export 'core/computed.dart';
export 'core/snapshot.dart';
export 'core/reactive_list_simplified.dart';
export 'core/reactive_map.dart';
export 'core/reactive_set.dart';
export 'core/memoized_computed.dart';
export 'plugins/plugin_abstract.dart';
