abstract class FluxivityMiddleware<T> {
  void beforeUpdate(T oldValue, T newValue);
  void afterUpdate(T oldValue, T newValue);
  void onError(Object error, StackTrace stackTrace);
  bool shouldEmit(T oldValue, T newValue);
}
