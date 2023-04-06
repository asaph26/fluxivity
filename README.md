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

## ReactiveListExtensions

ReactiveListExtensions is a powerful addition to the Fluxivity package that allows you to easily create and work with reactive lists in your Dart applications. With these extension methods, you can automatically track changes to your lists, and the package will handle the updates and emit a stream whenever the list is manipulated.

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

## License
MIT License at [LICENSE](LICENSE)