import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../plugins/plugin_abstract.dart';
import './snapshot.dart';

/// A reactive container that holds a value and notifies listeners when it changes.
///
/// The [Reactive] class is the foundation of Fluxivity's reactivity system. It wraps
/// a value and provides mechanisms to observe changes to that value. When the value
/// changes, all listeners are notified of the change.
///
/// Key features:
/// * Holds a value of type T that can be accessed synchronously with [value]
/// * Provides a [stream] of updates that emits a [Snapshot] whenever the value changes
/// * Supports [addEffect] for side-effect handling
/// * Can be wrapped with [FluxivityMiddleware] for additional behaviors
/// * Supports batched updates to optimize multiple changes
///
/// Example usage:
/// ```dart
/// // Create a reactive value
/// final counter = Reactive(0);
///
/// // Access the current value
/// print(counter.value); // 0
///
/// // Listen for changes
/// counter.stream.listen((snapshot) {
///   print('Counter changed from ${snapshot.oldValue} to ${snapshot.newValue}');
/// });
///
/// // Update the value
/// counter.value = 1; // Triggers notification: "Counter changed from 0 to 1"
/// ```
///
/// [Reactive] instances are often used as sources for [Computed] values:
/// ```dart
/// final doubledCounter = Computed([counter], (sources) {
///   return sources[0].value * 2;
/// });
/// ```
class Reactive<T> {
  Reactive(this._value, {List<FluxivityMiddleware<T>>? middlewares})
      : _middlewares = middlewares ?? [] {
    _controller.add(Snapshot(_value, _value));
  }

  int _batchUpdateCounter = 0;
  bool get _isBatchUpdate => _batchUpdateCounter > 0;
  final List<Snapshot<T>> _bufferedEvents = [];

  /// Starts a batch update session for this reactive instance.
  ///
  /// During a batch update, changes to the value are buffered and not immediately
  /// sent to listeners. This is useful when you need to make multiple changes
  /// to the value and only want to notify listeners once at the end.
  ///
  /// Batch updates can be nested. The buffered updates will only be published when
  /// the outermost batch update is ended with [endBatchUpdate].
  ///
  /// Example usage:
  /// ```dart
  /// // Start batching updates
  /// reactive.startBatchUpdate();
  ///
  /// // Make multiple changes
  /// reactive.value = 10;
  /// reactive.value = 20;
  /// reactive.value = 30;
  ///
  /// // End batching and publish the final update
  /// reactive.endBatchUpdate();
  /// ```
  ///
  /// See also:
  /// * [endBatchUpdate]: Ends a batch update session and publishes changes
  void startBatchUpdate() {
    _batchUpdateCounter++;
  }

  /// Ends a batch update session and optionally publishes the buffered changes.
  ///
  /// When the outermost batch update is ended (when the internal counter reaches zero),
  /// the buffered changes are published to listeners. By default, only the last change
  /// is published, but you can publish all buffered changes by setting [publishAll] to true.
  ///
  /// Parameters:
  /// * [publishAll]: If true, all buffered updates are published in sequence.
  ///                If false (default), only the most recent update is published.
  ///
  /// Example usage:
  /// ```dart
  /// // Start batching updates
  /// reactive.startBatchUpdate();
  ///
  /// // Make multiple changes
  /// reactive.value = 10;
  /// reactive.value = 20;
  /// reactive.value = 30;
  ///
  /// // End batching and publish only the final state
  /// reactive.endBatchUpdate();
  ///
  /// // Or, to publish all intermediate states:
  /// // reactive.endBatchUpdate(publishAll: true);
  /// ```
  ///
  /// See also:
  /// * [startBatchUpdate]: Starts a batch update session
  void endBatchUpdate({bool publishAll = false}) {
    if (_batchUpdateCounter > 0) {
      _batchUpdateCounter--;

      if (_batchUpdateCounter == 0 && _bufferedEvents.isNotEmpty) {
        if (publishAll) {
          for (var event in _bufferedEvents) {
            _controller.add(event);
          }
        } else {
          _controller.add(_bufferedEvents.last);
        }
        _bufferedEvents.clear();
      }
    }
  }

  final List<FluxivityMiddleware<T>> _middlewares;

  T _value;

  /// Gets the current value of this reactive instance.
  ///
  /// This provides synchronous access to the wrapped value without subscribing to changes.
  /// Accessing this property does not trigger any notifications.
  ///
  /// Example:
  /// ```dart
  /// final reactive = Reactive(42);
  /// print(reactive.value); // 42
  /// ```
  T get value => _value;

  /// Returns a stream of snapshots containing the old and new values after each change.
  ///
  /// The stream is a [BehaviorSubject], which means new subscribers immediately receive
  /// the current value. Each [Snapshot] emitted contains both the previous value
  /// ([Snapshot.oldValue]) and the new value ([Snapshot.newValue]).
  ///
  /// Example:
  /// ```dart
  /// final name = Reactive('John');
  ///
  /// // Subscribe to changes
  /// final subscription = name.stream.listen((snapshot) {
  ///   print('Name changed from "${snapshot.oldValue}" to "${snapshot.newValue}"');
  /// });
  ///
  /// name.value = 'Jane'; // Prints: Name changed from "John" to "Jane"
  ///
  /// // Don't forget to cancel the subscription when no longer needed
  /// subscription.cancel();
  /// ```
  Stream<Snapshot<T>> get stream => _controller.stream;
  final _controller = BehaviorSubject<Snapshot<T>>();

  /// Updates the value and notifies listeners if the value has changed.
  ///
  /// This setter compares the new value with the current value using the equality operator.
  /// If they are different, it:
  /// 1. Calls middleware [beforeUpdate] hooks
  /// 2. Updates the internal value
  /// 3. Calls middleware [afterUpdate] hooks
  /// 4. Checks if any middleware prevents emission with [shouldEmit]
  /// 5. If allowed, creates a [Snapshot] and either:
  ///    - Adds it to the buffer if in a batch update
  ///    - Emits it to the stream immediately otherwise
  ///
  /// No notifications are sent if the new value equals the current value.
  ///
  /// Example:
  /// ```dart
  /// final counter = Reactive(0);
  /// counter.value = 1; // Triggers notification
  /// counter.value = 1; // No notification (value unchanged)
  /// ```
  set value(T newValue) {
    T oldValue = _value;
    if (newValue != oldValue) {
      for (var middleware in _middlewares) {
        middleware.beforeUpdate(oldValue, newValue);
      }

      _value = newValue;
      for (var middleware in _middlewares) {
        middleware.afterUpdate(oldValue, newValue);
      }

      bool shouldPublish = _middlewares
          .map((e) => e.shouldEmit(oldValue, newValue))
          .fold(true, (value, element) => value && element);

      if (shouldPublish) {
        Snapshot<T> snapshot = Snapshot(oldValue, newValue);
        if (_isBatchUpdate) {
          _bufferedEvents.add(snapshot);
        } else {
          _controller.add(snapshot);
        }
      }
    }
  }

  /// Releases resources used by this reactive instance.
  ///
  /// This method closes the internal stream controller and should be called when the
  /// reactive instance is no longer needed to avoid memory leaks. After calling [dispose],
  /// any attempt to listen to the [stream] will result in an error.
  ///
  /// Example:
  /// ```dart
  /// final counter = Reactive(0);
  /// // ... use counter ...
  ///
  /// // When done with the reactive instance:
  /// counter.dispose();
  /// ```
  void dispose() {
    _controller.close();
  }

  @override
  String toString() {
    return 'Reactive: ${_value.toString()}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reactive &&
          runtimeType == other.runtimeType &&
          _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  /// Adds an effect function that gets called whenever the value changes.
  ///
  /// Effects are a way to perform side effects when a reactive value changes
  /// without modifying the value itself. The effect function receives a [Snapshot]
  /// containing both the old and new values.
  ///
  /// This method returns a [StreamSubscription] that can be used to cancel the
  /// effect if needed.
  ///
  /// Example:
  /// ```dart
  /// final counter = Reactive(0);
  ///
  /// // Add a logging effect
  /// counter.addEffect((snapshot) {
  ///   print('Counter changed from ${snapshot.oldValue} to ${snapshot.newValue}');
  /// });
  ///
  /// // Add a persistence effect
  /// counter.addEffect((snapshot) {
  ///   saveToLocalStorage('counter', snapshot.newValue);
  /// });
  ///
  /// counter.value = 1; // Both effects will be triggered
  /// ```
  ///
  /// Note: Effects are implemented using stream subscriptions. To avoid memory leaks,
  /// ensure you cancel any subscriptions when they're no longer needed, or dispose
  /// the reactive instance.
  StreamSubscription<Snapshot<T>> addEffect(Function(Snapshot<T>) effect) {
    return stream.listen((snapshot) {
      effect(snapshot);
    });
  }
}
