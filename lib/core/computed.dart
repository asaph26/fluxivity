import 'dart:async';
import 'package:async/async.dart';
import 'package:fluxivity/core/snapshot.dart';

import '../plugins/plugin_abstract.dart';
import 'reactive.dart';
import 'package:rxdart/rxdart.dart';

/// A Computed class that computes a value based on the values of one or more Reactive instances.
///
/// The computed value is updated whenever any of the source Reactive instances change,
/// and the change is propagated to its listeners.
class Computed<T> {
  final List<Reactive<dynamic>> _sources;
  final T Function(List<Reactive<dynamic>>) _compute;
  final List<FluxivityMiddleware<T>> _middlewares;

  int _batchUpdateCounter = 0;
  bool get _isBatchUpdate => _batchUpdateCounter > 0;
  final List<Snapshot<T>> _bufferedEvents = [];

  void startBatchUpdate() {
    _batchUpdateCounter++;
  }

  void endBatchUpdate({bool publishAll = false}) {
    if (_batchUpdateCounter > 0) {
      _batchUpdateCounter--;

      if (_batchUpdateCounter == 0) {
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

  /// Returns a stream of snapshots containing the computed value. New snapshots are emitted whenever the computed value changes.
  Stream<Snapshot<T>> get stream => _controller.stream;
  final _controller = BehaviorSubject<Snapshot<T>>();
  late T _value;

  /// Constructs a new Computed instance.
  ///
  /// [_sources] is a list of Reactive instances whose values are used to compute the new value.
  /// [_compute] is a function that takes the list of Reactive instances and computes the new value.
  /// [_middlewares] is a list of FluxivityMiddleware instances that can be used to add hooks or intercept the update process.
  Computed(this._sources, this._compute,
      {List<FluxivityMiddleware<T>>? middlewares})
      : _middlewares = middlewares ?? [] {
    _value = _compute(_sources);
    _controller.add(Snapshot(_value, _value));

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
  T get value => _value;

  /// Disposes of the internal stream controller.
  void dispose() {
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
