import 'package:collection/collection.dart';
import 'reactive.dart';
import 'snapshot.dart';

extension ReactiveListExtensions<E> on List<E> {
  Reactive<ReactiveListWrapper<E>> get reactive {
    final reactiveList =
        Reactive<ReactiveListWrapper<E>>(ReactiveListWrapper<E>(this));
    return reactiveList;
  }
}

class ReactiveListWrapper<E> extends DelegatingList<E> {
  final Reactive<List<E>> _reactiveList;

  ReactiveListWrapper(List<E> list)
      : _reactiveList = Reactive<List<E>>(list),
        super(list);

  @override
  void add(E value) {
    _reactiveList.value.add(value);
    _reactiveList.value =
        _reactiveList.value; // Notify listeners after adding the value
  }

  @override
  void addAll(Iterable<E> iterable) {
    _reactiveList.value.addAll(iterable);
    _reactiveList.value = _reactiveList.value;
  }

  @override
  void insert(int index, E element) {
    _reactiveList.value.insert(index, element);
    _reactiveList.value = _reactiveList.value;
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    _reactiveList.value.insertAll(index, iterable);
    _reactiveList.value = _reactiveList.value;
  }

  @override
  bool remove(Object? value) {
    int index = _reactiveList.value.indexOf(value as E);
    if (index != -1) {
      _reactiveList.value.removeAt(index);
      _reactiveList.value = _reactiveList.value;
      return true;
    }
    return false;
  }

  @override
  E removeAt(int index) {
    final removedElement = _reactiveList.value.removeAt(index);
    _reactiveList.value = _reactiveList.value;
    return removedElement;
  }

  @override
  E removeLast() {
    final removedElement = _reactiveList.value.removeLast();
    _reactiveList.value = _reactiveList.value;
    return removedElement;
  }

  @override
  void removeWhere(bool test(E element)) {
    _reactiveList.value.removeWhere(test);
    _reactiveList.value = _reactiveList.value;
  }

  @override
  void retainWhere(bool test(E element)) {
    _reactiveList.value.retainWhere(test);
    _reactiveList.value = _reactiveList.value;
  }

  @override
  void clear() {
    _reactiveList.value.clear();
    _reactiveList.value = _reactiveList.value;
  }

  @override
  void sort([int compare(E a, E b)?]) {
    _reactiveList.value.sort(compare);
    _reactiveList.value = _reactiveList.value;
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    _reactiveList.value.setRange(start, end, iterable, skipCount);
    _reactiveList.value = _reactiveList.value;
  }

  @override
  void removeRange(int start, int end) {
    _reactiveList.value.removeRange(start, end);
    _reactiveList.value = _reactiveList.value;
  }

  @override
  void replaceRange(int start, int end, Iterable<E> newContents) {
    _reactiveList.value.replaceRange(start, end, newContents);
    _reactiveList.value = _reactiveList.value;
  }

  @override
  void fillRange(int start, int end, [E? fillValue]) {
    _reactiveList.value.fillRange(start, end, fillValue);
    _reactiveList.value = _reactiveList.value;
  }

  @override
  void setAll(int index, Iterable<E> iterable) {
    _reactiveList.value.setAll(index, iterable);
    _reactiveList.value = _reactiveList.value;
  }

  @override
  void operator []=(int index, E value) {
    _reactiveList.value[index] = value;
    _reactiveList.value = _reactiveList.value;
  }

  @override
  set length(int newLength) {
    _reactiveList.value = List<E>.from(_reactiveList.value)..length = newLength;
    _reactiveList.value = _reactiveList.value;
  }

  Stream<Snapshot<List<E>>> get stream => _reactiveList.stream;

  void dispose() {
    _reactiveList.dispose();
  }

  List<E> unwrap() {
    return _reactiveList.value;
  }
}
