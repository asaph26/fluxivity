import 'dart:async';
import 'package:fluxivity/core/computed.dart';
import 'package:fluxivity/core/snapshot.dart';
import 'package:fluxivity/core/reactive.dart';

/// A function that returns a memoized version of the provided [Computed] instance.
///
/// The memoized version will cache the last [cacheSize] unique computed values and their
/// corresponding source values. When the sources change to previously seen values,
/// the cached result will be returned instead of recomputing.
///
/// ```dart
/// final count = Reactive(0);
/// final expensive = Computed([count], (sources) {
///   // Expensive computation
///   return sources[0].value * 100;
/// });
///
/// // Create a memoized version with a cache size of 5
/// final memoizedExpensive = memoize(expensive, cacheSize: 5);
/// ```
Computed<T> memoize<T>(Computed<T> computed, {int cacheSize = 1}) {
  return _MemoizedComputed<T>(computed, cacheSize: cacheSize);
}

/// Private implementation of a memoized Computed instance.
class _MemoizedComputed<T> implements Computed<T> {
  final Computed<T> _original;
  final int _cacheSize;
  final Map<String, T> _cache = {};
  final List<String> _accessOrder = [];

  _MemoizedComputed(this._original, {required int cacheSize})
      : _cacheSize = cacheSize;

  /// Generates a cache key based on the current values of all sources.
  String _generateCacheKey() {
    return _original.sources
        .map((source) => source.value.hashCode.toString())
        .join('-');
  }

  /// Get the current value from the original Computed instance.
  /// This is used when we know the value has changed and we need to update the cache.
  T _getCurrentValue() {
    final result = _original.value;
    return result;
  }

  /// Updates the access order for the given key, marking it as most recently used.
  void _updateAccessOrder(String key) {
    _accessOrder.remove(key);
    _accessOrder.add(key);

    // Remove least recently used entry if cache exceeds size limit
    if (_accessOrder.length > _cacheSize) {
      final lruKey = _accessOrder.removeAt(0);
      _cache.remove(lruKey);
    }
  }

  @override
  T get value {
    final key = _generateCacheKey();

    // Check if value is cached
    if (_cache.containsKey(key)) {
      _updateAccessOrder(key);
      return _cache[key]!;
    }

    // Get value from original Computed - trigger the computation
    final result = _getCurrentValue();

    // Cache the result
    _cache[key] = result;
    _updateAccessOrder(key);

    return result;
  }

  // Delegate other properties and methods to the original Computed

  @override
  Stream<Snapshot<T>> get stream => _original.stream;

  @override
  List<Reactive<dynamic>> get sources => _original.sources;

  @override
  void startBatchUpdate() => _original.startBatchUpdate();

  @override
  void endBatchUpdate({bool publishAll = false}) =>
      _original.endBatchUpdate(publishAll: publishAll);

  @override
  void dispose() => _original.dispose();

  @override
  String toString() => 'Memoized(${_original.toString()})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MemoizedComputed &&
          runtimeType == other.runtimeType &&
          _original == other._original;

  @override
  int get hashCode => _original.hashCode;
}
