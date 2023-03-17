class Snapshot<T> {
  T oldValue;
  T newValue;

  Snapshot(this.oldValue, this.newValue);
}
