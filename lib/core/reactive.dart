import 'dart:async';

import 'package:rxdart/rxdart.dart';

import './snapshot.dart';

/// A Reactive class that represents a value that can be observed.
///
/// The value can be updated, and the change is propagated to its listeners.
class Reactive<T> {
  Reactive(this._value) {
    _controller.add(Snapshot(_value, _value));
  }

  T _value;
  T get value => _value;

  final Map<String, List<Reactive<dynamic>>> _children = {};

  /// Returns a stream of snapshots containing the current and new values.
  Stream<Snapshot<T>> get stream => _controller.stream;
  final _controller = BehaviorSubject<Snapshot<T>>();

  /// Updates the value and notifies listeners if the value has changed.
  set value(T newValue) {
    if (newValue != _value) {
      _value = newValue;
      _controller.add(Snapshot(_value, newValue));
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

  /// Adds a parent to the current instance and associates the current [Reactive] with an accessor. This is used to create a tree of [Reactive] instances.
  void addParent(String childAccessor, Reactive parent) {
    _setChildren(parent, this, childAccessor);
  }

  void _setChildren(Reactive parent, Reactive child, String accessor) {
    if (parent._children.containsKey(accessor)) {
      parent._children[accessor]?.add(child);
    } else {
      parent._children[accessor] = [child];
    }
  }

  /// Returns the first child of the specified type associated with the given accessor.
  Reactive<ChildType> getOneChild<ChildType>(String accessor) {
    if (_children.containsKey(accessor)) {
      return _children[accessor]?.first as Reactive<ChildType>;
    }
    throw Exception('No child found with accessor: $accessor');
  }

  /// Returns all children of the specified type associated with the given accessor.
  List<Reactive<ChildType>> getAllChildren<ChildType>(String accessor) {
    if (_children.containsKey(accessor)) {
      return _children[accessor] as List<Reactive<ChildType>>;
    }
    throw Exception('No child found with accessor: $accessor');
  }

  /// Adds an effect function that gets called whenever the value changes.
  void addEffect(Function(T) effect) {
    stream.listen((snapshot) {
      effect(snapshot.newValue);
    });
  }
}
