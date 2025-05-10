import 'dart:async';
import 'package:async/async.dart';
import 'package:fluxivity/core/snapshot.dart';

import '../plugins/plugin_abstract.dart';
import 'reactive.dart';
import 'package:rxdart/rxdart.dart';

/// A class that represents a derived value computed from one or more reactive sources.
///
/// The [Computed] class automatically tracks dependencies on [Reactive] instances
/// and recalculates its value whenever any of its sources change. This enables
/// creating a reactive dependency graph where changes propagate automatically.
///
/// Key features:
/// * Automatically updates when source values change
/// * Supports multiple reactive sources
/// * Provides both synchronous value access and reactive stream
/// * Supports middleware for customizing behavior
/// * Offers batch update control for optimizing multiple updates
///
/// Example usage:
/// ```dart
/// // Create source reactive values
/// final firstName = Reactive('John');
/// final lastName = Reactive('Doe');
///
/// // Create a computed value that depends on both sources
/// final fullName = Computed([firstName, lastName], (sources) {
///   return '${sources[0].value} ${sources[1].value}';
/// });
///
/// // Access the computed value
/// print(fullName.value); // "John Doe"
///
/// // When a source changes, the computed value updates automatically
/// firstName.value = 'Jane';
/// print(fullName.value); // "Jane Doe"
/// ```
///
/// You can also attach middleware to a [Computed] instance to customize its behavior:
/// ```dart
/// final formattedName = Computed([firstName, lastName], (sources) {
///   return '${sources[0].value} ${sources[1].value}';
/// }, middlewares: [LoggingMiddleware<String>()]);
/// ```
class Computed<T> {
  final List<Reactive<dynamic>> _sources;
  final T Function(List<Reactive<dynamic>>) _compute;
  final List<FluxivityMiddleware<T>> _middlewares;

  int _batchUpdateCounter = 0;
  bool get _isBatchUpdate => _batchUpdateCounter > 0;
  final List<Snapshot<T>> _bufferedEvents = [];

  /// Starts a batch update session for this computed instance.
  ///
  /// During a batch update, changes to the value are buffered and not immediately
  /// sent to listeners. This can be useful when you need to make multiple rapid
  /// changes to source values and want to minimize the number of notifications.
  ///
  /// Batch updates can be nested. The buffered updates will only be published when
  /// the outermost batch update is ended with [endBatchUpdate].
  ///
  /// Example usage:
  /// ```dart
  /// // Start batching updates
  /// computed.startBatchUpdate();
  ///
  /// // Make multiple changes to sources
  /// source1.value = 10;
  /// source2.value = 20;
  /// source3.value = 30;
  ///
  /// // End batching and publish the final update
  /// computed.endBatchUpdate();
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
  /// computed.startBatchUpdate();
  ///
  /// // Make multiple changes to sources
  /// source1.value = 10;
  /// source2.value = 20;
  /// source3.value = 30;
  ///
  /// // End batching and publish only the final state
  /// computed.endBatchUpdate();
  ///
  /// // Or, to publish all intermediate states:
  /// // computed.endBatchUpdate(publishAll: true);
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

  /// Returns a stream of snapshots containing the computed value.
  ///
  /// This stream emits a new [Snapshot] whenever the computed value changes due to changes
  /// in any of its source [Reactive] instances. The [Snapshot] contains both the previous
  /// value ([Snapshot.oldValue]) and the new value ([Snapshot.newValue]).
  ///
  /// The stream is a [BehaviorSubject], which means new subscribers immediately receive
  /// the current value.
  ///
  /// Example:
  /// ```dart
  /// final counter = Reactive(0);
  /// final doubled = Computed([counter], (sources) => sources[0].value * 2);
  ///
  /// // Subscribe to changes in the computed value
  /// doubled.stream.listen((snapshot) {
  ///   print('Doubled value changed from ${snapshot.oldValue} to ${snapshot.newValue}');
  /// });
  ///
  /// counter.value = 5; // Prints: "Doubled value changed from 0 to 10"
  /// ```
  Stream<Snapshot<T>> get stream => _controller.stream;
  final _controller = BehaviorSubject<Snapshot<T>>();
  late T _value;

  /// Constructs a new [Computed] instance that derives its value from reactive sources.
  ///
  /// The [Computed] instance automatically tracks changes to its sources and recalculates
  /// its value whenever any source changes. The compute function is responsible for
  /// transforming the source values into the computed value.
  ///
  /// Parameters:
  /// * [sources]: A list of [Reactive] instances that this computed value depends on.
  ///   The computed value will update whenever any of these sources change.
  /// * [compute]: A function that takes the list of source [Reactive] instances
  ///   and returns the computed value. This function should be pure and deterministic
  ///   (always return the same output for the same inputs).
  /// * [middlewares]: Optional list of [FluxivityMiddleware] instances that can intercept
  ///   and modify the behavior of this computed value.
  ///
  /// Example:
  /// ```dart
  /// final firstName = Reactive('John');
  /// final lastName = Reactive('Doe');
  ///
  /// // Create a computed full name that depends on both first and last name
  /// final fullName = Computed(
  ///   [firstName, lastName],
  ///   (sources) {
  ///     final first = sources[0].value as String;
  ///     final last = sources[1].value as String;
  ///     return '$first $last';
  ///   },
  /// );
  ///
  /// print(fullName.value); // "John Doe"
  ///
  /// // When a source changes, the computed value updates automatically
  /// firstName.value = 'Jane';
  /// print(fullName.value); // "Jane Doe"
  /// ```
  Computed(this._sources, this._compute,
      {List<FluxivityMiddleware<T>>? middlewares})
      : _middlewares = middlewares ?? [] {
    _value = _compute(_sources);
    _controller.add(Snapshot(_value, _value));

    _subscription =
        StreamGroup.merge(_sources.map((source) => source.stream)).listen((_) {
      final T newValue;
      try {
        newValue = _compute(_sources);
      } catch (e, st) {
        for (var middleware in _middlewares) {
          middleware.onError(e, st);
        }
        return;
      }
      final oldValue = _value;
      if (newValue != _value) {
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
    });
  }

  /// Returns the current computed value.
  ///
  /// This getter provides synchronous access to the most recent computed value.
  /// It returns the cached value without triggering a recomputation.
  ///
  /// Example:
  /// ```dart
  /// final counter = Reactive(10);
  /// final squared = Computed([counter], (sources) => sources[0].value * sources[0].value);
  ///
  /// print(squared.value); // 100
  ///
  /// counter.value = 5;
  /// print(squared.value); // 25 (automatically updated)
  /// ```
  T get value => _value;

  StreamSubscription<dynamic>? _subscription;

  /// Returns the list of source [Reactive] instances that this computed value depends on.
  ///
  /// This getter provides access to the source reactives passed in the constructor.
  /// It's primarily used internally for implementing memoization and by the
  /// [memoize] function.
  ///
  /// Example:
  /// ```dart
  /// final name = Reactive('John');
  /// final greeting = Computed([name], (sources) => 'Hello, ${sources[0].value}!');
  ///
  /// final sources = greeting.sources;
  /// print(sources.length); // 1
  /// print(sources[0].value); // "John"
  /// ```
  ///
  /// See also:
  /// * [memoize]: A function that creates a memoized version of a computed value.
  List<Reactive<dynamic>> get sources => _sources;

  /// Releases resources used by this computed instance.
  ///
  /// This method cancels the internal subscription to source changes and closes
  /// the stream controller. It should be called when the computed instance is
  /// no longer needed to avoid memory leaks.
  ///
  /// After calling [dispose], the computed value will no longer update in response
  /// to changes in its sources, and any attempt to listen to the [stream] will
  /// result in an error.
  ///
  /// Example:
  /// ```dart
  /// final counter = Reactive(0);
  /// final doubled = Computed([counter], (sources) => sources[0].value * 2);
  ///
  /// // Use the computed value...
  ///
  /// // When done with the computed value:
  /// doubled.dispose();
  /// ```
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _controller.close();
  }

  @override
  String toString() {
    return 'Computed: ${value.toString()}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Computed &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}
