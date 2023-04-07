import '../plugin_abstract.dart';

class LoggingMiddleware<T> extends FluxivityMiddleware<T> {
  @override
  void beforeUpdate(T oldValue, T newValue) {
    print("Before update: $oldValue -> $newValue");
  }

  @override
  void afterUpdate(T oldValue, T newValue) {
    print("After update: $oldValue -> $newValue");
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    print("Error: $error\n$stackTrace");
  }

  @override
  bool shouldEmit(T oldValue, T newValue) {
    return true;
  }
}
