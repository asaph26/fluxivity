# Fluxivity

Fluxivity is an experimental package to study the effect of building a reactive graph. 

Package is available on pub.dev [here](https://pub.dev/packages/fluxivity)

## Why this package

Despite the availability of a lot of state management solutions, I often find myself 
looking for simpler solutions that are bound by the following principles

* Global app state
* View Models should only contain value/data accessors and not the data themselves
* It should be possible to construct a graph like structure of App state.
* It should be possible to access latest data without waiting on a value
* It should be possible to track changes to data if required
* Have a functional approach to dealing with changes

**Note**: 2023-04-07: I recently saw an implementation with the package being used with traditional view models. While I am not a huge fan of encapsulating data in view models, I do see the value in this approach. I will be adding an example of this in the future.

## Basic functionality

There are 2 core classes

* Reactive
* Computed

A reactive class creates a reactive property and keeps track of its state publishing updates as 
the value changes through a stream. The latest value is always available as a static value 
without the need to call `await` or `listen`. However there is a stream available that can be 
listened to in case you want to listen for updates. The reactive class also contains a `addEffect`
method to handle side effects as part of the mutation of the value. For example, updating data in 
a offline store, or syncing data to the backend.

There is an associated computed class that functions similar to a reactive class, however its value
is always dependent on the classes it depends on for its value. The value of a computed class gets
updated everytime the value of the dependent classes change. This can be used where derived values 
are necessary. 

## Example Usage

You can also refer to the test files for example usage. I will add additional example apps when I 
find more time

```dart
CurrentPage page = CurrentPage({location: 'test'});

Reactive<String> appId = Reactve('app_123456789');
Reactive<CurrentPage> currentPage = Reactive(page);
Computed<String> location = Computed([currentPage], (List<Reactive<CurrentPage>> cpl ) {
    Reactive<CurrentPage> page = cpl.first();
    return page.location
})

currentPage.value.location;
// test
location.value
// test

page = CurrentPage({location: 'newLocation'});
currentPage.value = page;

currentPage.stream.listen((Snapshot<CurrentPage> snapshot) {
    snapshot.oldValue.location;
    //  test
    snapshot.newValue.location;
    // newLocation
})


currentPage.value.location;
// newLocation
location.value
// newLocation

```

## ReactiveExtensions

ReactiveExtensions are extensions on top of native lists which allow you to easily create and work with reactive lists in your Dart applications. With these extension methods, you can automatically track changes to your lists, and the package will handle the updates and emit a stream whenever the list is manipulated.

> NOTE: Reactive Maps and Sets are coming soon.

### Usage

To create a reactive list, use the reactive getter on a regular list:

```dart
import 'package:fluxivity/fluxivity.dart';

void main() {
  final reactiveList = [1, 2, 3].reactive;

  // You can subscribe to changes in the list
  reactiveList.stream.listen((snapshot) {
    print('List updated: ${snapshot.newValue}');
  });

  // Use the regular list methods to manipulate the list
  reactiveList.value.add(4); // Output: List updated: [1, 2, 3, 4]
}
```

### Unwrap

The unwrap method is useful when you want to retrieve the original non-reactive list from a reactive list. This can be helpful when working with external libraries or APIs that don't understand reactive objects.

**Example:**

```dart
final nonReactiveList = reactiveList.unwrap();
print(nonReactiveList); // Output: [1, 2, 3, 4]
```

### addEffects

Similar to the addEffects feature available in reactives, you can define custom functions (effects) that will automatically be executed whenever the list is modified. This enables you to perform additional tasks or side effects in response to list manipulations.

**Example:**

To use addEffects, first create a reactive list using the reactive getter on a regular list. Then, define a custom function that accepts a Snapshot<List<E>> as a parameter. This function will be executed whenever the list is modified:

```dart
import 'package:fluxivity/fluxivity.dart';

void main() {
  final reactiveList = [1, 2, 3].reactive;

  // Define a custom effect function
  void logUpdate(Snapshot<List<int>> snapshot) {
    print('List updated: ${snapshot.newValue}');
  }

  // Add the effect to the reactive list
  reactiveList.addEffect(logUpdate);

  // Use the regular list methods to manipulate the list
  reactiveList.value.add(4); // Output: List updated: [1, 2, 3, 4]
}

```

## Example Use Cases of Fluxivity
Read more examples at [example/README.md](example/README.md)

# Advanced Usage

The following is a list of functions that are not part of regular day to day usage, but are useful in certain scenarios where you want to have extended control over how fluxivity functions.

## Middlewares

Middlewares allow you to extend the package with custom functionality. Fluxivity Middlewares should extend the `FluxivityMiddleware` class and implement the methods in them. Other than the `shouldEmit` method, the other methods return void. The shouldEmit method returns a boolean value which controls whether the stream should emit the new value or not. This can be used to implement custom logic to control when the stream should emit a new value. Middlewares function for both Reactive and Computed classes. The extension methods since they rely on the actual reactive class get these by extension. However you will have to use the `toReactive` method to pass in the middleware instead of the `.reactive` extension method.

### onError
The onError method of the plugin is used only within the Computed class to handle errors arising out of the compute function. In the case of error, the value of the computed method does not change and the error is passed to the onError method of the middleware. The middleware can then handle the error as required. You can write a custom error handler to deal with this case.

### Example

```dart
import 'package:fluxivity/fluxivity.dart';

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
```

To use the middleware in your code, you can initialise a reactive with the middleware as follows:

```dart
Reactive<String> reactive = Reactive('test', { middlewares: [LoggingMiddleware<String>()] });
```


## Batched Updates

Fluxivity allows you to listen to updates in a batched mode instead of listening to individual events. This is useful when you want to perform multiple operations on a reactive value and only want to listen to the final value. This batched updates also work alongside the middlewares. If a middleware prevents the stream from emitting, the batched update will not be emitted. Batched updates can be used with both Reactive and Computed classes. It is also available for all extension methods. You can also nest batched updates, in which case, the updates are only emitted when the outermost batched update is ended.

```dart
final reactive = Reactive<int>(0);

// Start a batch update
reactive.startBatchUpdate();

// Perform multiple updates
reactive.value = 1;
reactive.value = 2;
reactive.value = 3;
reactive.value = 4;

// End the batch update, which will emit the last buffered value
reactive.endBatchUpdate(); // Output: 4

// Start a batch update
reactive.startBatchUpdate();

reactive.value = 5;
reactive.value = 6;
reactive.value = 7;
reactive.value = 8;

// End the batch update, which will emit the last buffered value
reactive.endBatchUpdate(publishAll: true); // Output: 5, 6, 7, 8
```

## Usage along with storage providers

Fluxivity can be used along with existing storage providers like Hive, Shared Preferences, etc. The following is an example of how you can use Fluxivity along with Hive. This assumes you have setup Hive and its type adapters, you could create a custom class called HiveReactive which extends the Reactive class and implements the methods to save and load from Hive.

```dart
import 'package:fluxivity/core/reactive.dart';
import 'package:hive/hive.dart';

class HiveReactive<T> extends Reactive<T> {
  final String boxName;
  final String key;

  HiveReactive(this.boxName, this.key, T initialValue) : super(initialValue) {
    _loadFromHive();
  }

  @override
  set value(T newValue) {
    super.value = newValue;
    _saveToHive();
  }

  Future<void> _loadFromHive() async {
    final box = await Hive.openBox<T>(boxName);
    if (box.containsKey(key)) {
      super.value = box.get(key);
    }
  }

  Future<void> _saveToHive() async {
    final box = await Hive.openBox<T>(boxName);
    box.put(key, value);
  }
}
```  

## License
MIT License at [LICENSE](LICENSE)