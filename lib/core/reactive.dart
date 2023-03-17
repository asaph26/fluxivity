import 'dart:async';

import './snapshot.dart';

class Reactive<T> {
  Reactive(this._value);
  T _value;
  T get value => _value;

  final Map<String, List<Reactive<dynamic>>> _children = {};

  Stream<Snapshot<T>> get stream => _controller.stream;
  final _controller = StreamController<Snapshot<T>>.broadcast();

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

  void addParent(String accessor, Reactive parent) {
    _setChildren(parent, this, accessor);
  }

  void _setChildren(Reactive parent, Reactive child, String accessor) {
    if (parent._children.containsKey(accessor)) {
      parent._children[accessor]?.add(child);
    } else {
      parent._children[accessor] = [child];
    }
  }

  Reactive<ChildType> getOneChild<ChildType>(String accessor) {
    if (_children.containsKey(accessor)) {
      return _children[accessor]?.first as Reactive<ChildType>;
    }
    throw Exception('No child found with accessor: $accessor');
  }

  List<Reactive<ChildType>> getAllChildren<ChildType>(String accessor) {
    if (_children.containsKey(accessor)) {
      return _children[accessor] as List<Reactive<ChildType>>;
    }
    throw Exception('No child found with accessor: $accessor');
  }

  void addEffect(Function(T) effect) {
    stream.listen((snapshot) {
      effect(snapshot.newValue);
    });
  }
}
