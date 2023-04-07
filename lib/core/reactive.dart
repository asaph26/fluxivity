import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../plugins/plugin_abstract.dart';
import './snapshot.dart';

/// A Reactive class that represents a value that can be observed.
///
/// The value can be updated, and the change is propagated to its listeners.
/// [_middlewares] is a list of FluxivityMiddleware instances that can be used to add hooks or intercept the update process.
/// [_value] is the initial value of the Reactive instance.
class Reactive<T> {
  Reactive(this._value, {List<FluxivityMiddleware<T>>? middlewares})
      : _middlewares = middlewares ?? [] {
    _controller.add(Snapshot(_value, _value));
  }

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

  final List<FluxivityMiddleware<T>> _middlewares;

  T _value;
  T get value => _value;

  /// Returns a stream of snapshots containing the current and new values.
  Stream<Snapshot<T>> get stream => _controller.stream;
  final _controller = BehaviorSubject<Snapshot<T>>();

  /// Updates the value and notifies listeners if the value has changed.
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
  void addEffect(Function(Snapshot<T>) effect) {
    stream.listen((snapshot) {
      effect(snapshot);
    });
  }
}
