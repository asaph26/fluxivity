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

## Reactive Collections

Fluxivity provides reactive collection extensions for Lists, Maps, and Sets, which allow you to easily create and work with reactive collections in your Dart applications. With these extension methods, you can automatically track changes to your collections, and the package will handle the updates and emit a stream whenever the collection is manipulated.

### Using Reactive Lists

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

### Using Reactive Maps

For key-value collections, you can use reactive maps:

```dart
import 'package:fluxivity/fluxivity.dart';

void main() {
  // Create a reactive map
  final userProfiles = <String, Map<String, dynamic>>{
    'user1': {'name': 'Alice', 'age': 28},
  }.reactive;

  // Subscribe to changes
  userProfiles.stream.listen((snapshot) {
    print('Map updated: ${snapshot.newValue}');
  });

  // Modify the map
  userProfiles.value['user2'] = {'name': 'Bob', 'age': 32};
  // Output: Map updated: {user1: {name: Alice, age: 28}, user2: {name: Bob, age: 32}}
  
  // Update an existing entry
  final bobProfile = Map<String, dynamic>.from(userProfiles.value['user2']!);
  bobProfile['age'] = 33;
  userProfiles.value['user2'] = bobProfile;
  // Output: Map updated: {user1: {name: Alice, age: 28}, user2: {name: Bob, age: 33}}
}
```

### Using Reactive Sets

For collections of unique values, you can use reactive sets:

```dart
import 'package:fluxivity/fluxivity.dart';

void main() {
  // Create a reactive set
  final activeUsers = <String>{'user1', 'user2'}.reactive;

  // Subscribe to changes
  activeUsers.stream.listen((snapshot) {
    print('Active users: ${snapshot.newValue}');
  });

  // Add a new unique value
  activeUsers.value.add('user3');
  // Output: Active users: {user1, user2, user3}
  
  // Adding a duplicate has no effect
  activeUsers.value.add('user2');
  // No output (set already contains 'user2')
  
  // Remove a value
  activeUsers.value.remove('user1');
  // Output: Active users: {user2, user3}
}
```

### Set Operations with Computed

Reactive sets work especially well with Computed for set operations:

```dart
import 'package:fluxivity/fluxivity.dart';

void main() {
  // Create two reactive sets
  final adminUsers = <String>{'alice', 'bob'}.reactive;
  final activeUsers = <String>{'alice', 'charlie', 'david'}.reactive;

  // Create a computed value for users who are both admins and active
  final activeAdmins = Computed<Set<String>>([adminUsers, activeUsers], (sources) {
    final admins = sources[0].value as Set<String>;
    final active = sources[1].value as Set<String>;
    return admins.intersection(active);
  });
  
  print(activeAdmins.value); // Output: {alice}
  
  // Update the admin set
  adminUsers.value = {'alice', 'bob', 'charlie'};
  print(activeAdmins.value); // Output: {alice, charlie}
}
```

### Unwrap Method

All reactive collections provide an unwrap method to retrieve the original collection. This is helpful when working with external libraries or APIs:

```dart
final nonReactiveList = reactiveList.unwrap();
final nonReactiveMap = reactiveMap.unwrap();
final nonReactiveSet = reactiveSet.unwrap();
```

### Adding Effects

All reactive collections support the addEffect method to define custom functions that will be executed on changes:

```dart
// For reactive lists
reactiveList.addEffect((snapshot) {
  print('List changed from ${snapshot.oldValue} to ${snapshot.newValue}');
});

// For reactive maps
reactiveMap.addEffect((snapshot) {
  print('Map changed with ${snapshot.newValue.length} entries');
});

// For reactive sets
reactiveSet.addEffect((snapshot) {
  final added = snapshot.newValue.difference(snapshot.oldValue);
  final removed = snapshot.oldValue.difference(snapshot.newValue);
  print('Added: $added, Removed: $removed');
});
```

## Collection Helper Methods and Extensions

Fluxivity's reactive collections can be enhanced with custom helper methods to streamline common operations while maintaining reactivity. Here are some examples you can implement:

### List Helper Methods

```dart
// Add these extension methods to enhance ReactiveListHelpers
extension EnhancedReactiveListHelpers<E> on Reactive<List<E>> {
  // Sort the list with a comparator and trigger reactivity
  void sort([int Function(E a, E b)? compare]) {
    final newList = List<E>.from(value);
    newList.sort(compare);
    value = newList;
  }
  
  // Filter the list and return a new reactive list
  Reactive<List<E>> where(bool Function(E) test) {
    return value.where(test).toList().reactive;
  }
  
  // Map the list to a new reactive list of different type
  Reactive<List<T>> mapToReactive<T>(T Function(E) convert) {
    return value.map(convert).toList().reactive;
  }
  
}
```

### Map Helper Methods

```dart
// Add these extension methods to enhance ReactiveMapHelpers
extension EnhancedReactiveMapHelpers<K, V> on Reactive<Map<K, V>> {
  // Create a new map containing only entries that satisfy a test
  Reactive<Map<K, V>> filter(bool Function(K key, V value) test) {
    final filteredMap = <K, V>{};
    value.forEach((key, value) {
      if (test(key, value)) {
        filteredMap[key] = value;
      }
    });
    return filteredMap.reactive;
  }
  
  // Transform all values in the map
  Reactive<Map<K, T>> mapValues<T>(T Function(V) transform) {
    final newMap = <K, T>{};
    value.forEach((key, val) {
      newMap[key] = transform(val);
    });
    return newMap.reactive;
  }
  
  // Add all entries from another map
  void addAll(Map<K, V> other) {
    final newMap = Map<K, V>.from(value);
    newMap.addAll(other);
    value = newMap;
  }
  
  // Remove all keys that satisfy a condition
  void removeKeysWhere(bool Function(K) test) {
    final newMap = Map<K, V>.from(value);
    newMap.removeWhere((key, _) => test(key));
    value = newMap;
  }
}
```

### Set Helper Methods

```dart
// Add these extension methods to enhance ReactiveSetHelpers
extension EnhancedReactiveSetHelpers<E> on Reactive<Set<E>> {
  // Compute set union with another set
  Reactive<Set<E>> union(Set<E> other) {
    return value.union(other).reactive;
  }
  
  // Compute set intersection with another set
  Reactive<Set<E>> intersection(Set<E> other) {
    return value.intersection(other).reactive;
  }
  
  // Compute set difference with another set
  Reactive<Set<E>> difference(Set<E> other) {
    return value.difference(other).reactive;
  }
  
  // Toggle an element (add if not present, remove if present)
  void toggle(E element) {
    final newSet = Set<E>.from(value);
    if (newSet.contains(element)) {
      newSet.remove(element);
    } else {
      newSet.add(element);
    }
    value = newSet;
  }
}
```

## Collection-Specific Middleware Examples

Fluxivity middleware can be customized to work specifically with collections. Here are some examples of collection-specific middleware implementations:

### Validation Middleware for Collections

```dart
// Middleware that validates list elements before updates
class ListValidationMiddleware<E> extends FluxivityMiddleware<List<E>> {
  final bool Function(E) validateElement;
  final void Function(E)? onInvalidElement;
  
  ListValidationMiddleware(this.validateElement, {this.onInvalidElement});
  
  @override
  void beforeUpdate(List<E> oldValue, List<E> newValue) {
    for (final element in newValue) {
      if (!validateElement(element)) {
        if (onInvalidElement != null) {
          onInvalidElement!(element);
        }
        throw ArgumentError('Invalid element: $element');
      }
    }
  }
  
  @override
  bool shouldEmit(List<E> oldValue, List<E> newValue) {
    return newValue.every(validateElement);
  }
}

// Usage example:
final numbersList = [1, 2, 3].toReactive(
  middlewares: [
    ListValidationMiddleware<int>(
      (number) => number >= 0, // Only allow positive numbers
      onInvalidElement: (number) => print('Invalid number: $number'),
    ),
  ],
);

// This will work
numbersList.value.add(4);

// This will throw an error
try {
  numbersList.value.add(-1);
} catch (e) {
  print(e); // ArgumentError: Invalid element: -1
}
```

### Deep Equality Middleware for Maps

```dart
// Middleware that checks for deep equality in maps
class DeepEqualityMapMiddleware<K, V> extends FluxivityMiddleware<Map<K, V>> {
  @override
  bool shouldEmit(Map<K, V> oldValue, Map<K, V> newValue) {
    // Check if they have the same keys
    if (oldValue.length != newValue.length || 
        !oldValue.keys.every((key) => newValue.containsKey(key))) {
      return true;
    }
    
    // Check if any value has changed deeply
    for (final key in oldValue.keys) {
      if (!_deepEquals(oldValue[key], newValue[key])) {
        return true;
      }
    }
    
    return false;
  }
  
  bool _deepEquals(dynamic a, dynamic b) {
    if (a == b) return true;
    
    if (a is Map && b is Map) {
      return a.length == b.length &&
          a.keys.every((key) => 
            b.containsKey(key) && _deepEquals(a[key], b[key]));
    }
    
    if (a is List && b is List) {
      return a.length == b.length &&
          List.generate(a.length, (i) => i).every((i) => 
            _deepEquals(a[i], b[i]));
    }
    
    return false;
  }
}

// Usage example:
final userSettings = {
  'theme': {'primary': '#007AFF', 'background': '#FFFFFF'},
  'notifications': {'email': true, 'push': true},
}.toReactive(
  middlewares: [DeepEqualityMapMiddleware<String, dynamic>()],
);

// This will emit an update because it's a deep change
final newTheme = Map<String, String>.from(userSettings.value['theme'] as Map<String, String>);
newTheme['primary'] = '#FF0000';
userSettings.value['theme'] = newTheme;
```

### Change Tracking Middleware for Sets

```dart
// Middleware that tracks element additions and removals in sets
class SetChangeTrackingMiddleware<E> extends FluxivityMiddleware<Set<E>> {
  final List<E> addedElements = [];
  final List<E> removedElements = [];
  
  @override
  void beforeUpdate(Set<E> oldValue, Set<E> newValue) {
    // Track elements that will be added
    addedElements.addAll(newValue.difference(oldValue));
    
    // Track elements that will be removed
    removedElements.addAll(oldValue.difference(newValue));
  }
  
  @override
  void afterUpdate(Set<E> oldValue, Set<E> newValue) {
    if (addedElements.isNotEmpty) {
      print('Added elements: $addedElements');
      addedElements.clear();
    }
    
    if (removedElements.isNotEmpty) {
      print('Removed elements: $removedElements');
      removedElements.clear();
    }
  }
}

// Usage example:
final tagSet = {'dart', 'flutter', 'reactive'}.toReactive(
  middlewares: [SetChangeTrackingMiddleware<String>()],
);

// This will track and print added elements
tagSet.value = {'dart', 'flutter', 'reactive', 'state-management'};
// Output: Added elements: [state-management]

// This will track and print removed elements
tagSet.value = {'dart', 'reactive', 'state-management'};
// Output: Removed elements: [flutter]
```

### Persistence Middleware for Any Collection

```dart
// Middleware that persists collection changes to local storage
class PersistenceMiddleware<T> extends FluxivityMiddleware<T> {
  final String storageKey;
  final Function(T) serialize;
  final Function(Map<String, dynamic>) deserialize;
  
  PersistenceMiddleware({
    required this.storageKey,
    required this.serialize,
    required this.deserialize,
  });
  
  @override
  void afterUpdate(T oldValue, T newValue) {
    // In a real app, you would use SharedPreferences, Hive, or other storage
    final serialized = serialize(newValue);
    print('Persisting to $storageKey: $serialized');
    
    // Example persistence code (pseudocode):
    // await SharedPreferences.getInstance().then((prefs) {
    //   prefs.setString(storageKey, jsonEncode(serialized));
    // });
  }
  
  // Method to load from storage (not part of middleware interface)
  Future<T?> loadFromStorage() async {
    // Example load code (pseudocode):
    // final prefs = await SharedPreferences.getInstance();
    // final data = prefs.getString(storageKey);
    // if (data != null) {
    //   return deserialize(jsonDecode(data));
    // }
    return null;
  }
}

// Usage example with a list:
final todoList = <String>[].toReactive(
  middlewares: [
    PersistenceMiddleware<List<String>>(
      storageKey: 'todo_list',
      serialize: (list) => {'items': list},
      deserialize: (data) => (data['items'] as List).cast<String>(),
    ),
  ],
);

// Adding an item will trigger persistence
todoList.value.add('Buy groceries');
todoList.value = List.from(todoList.value); // Force notification
```

## Advanced Collection Patterns

You can combine reactive collections with computed values and middleware to create powerful reactive patterns:

### Form Validation System

```dart
// A form validation system using reactive maps
void main() {
  // Field values
  final formFields = <String, String>{
    'name': '',
    'email': '',
    'age': '',
  }.reactive;
  
  // Validation rules
  final validators = <String, bool Function(String)>{
    'name': (value) => value.length >= 2,
    'email': (value) => value.contains('@') && value.contains('.'),
    'age': (value) => int.tryParse(value) != null && int.parse(value) >= 18,
  };
  
  // Computed validation errors
  final validationErrors = Computed<Map<String, String?>>([formFields], (sources) {
    final fields = sources[0].value as Map<String, String>;
    final errors = <String, String?>{};
    
    fields.forEach((key, value) {
      if (value.isEmpty) {
        errors[key] = null; // No error for empty fields until submitted
      } else if (!validators[key]!(value)) {
        errors[key] = 'Invalid $key';
      } else {
        errors[key] = null; // No error
      }
    });
    
    return errors;
  });
  
  // Computed form validity
  final isFormValid = Computed<bool>([formFields, validationErrors], (sources) {
    final fields = sources[0].value as Map<String, String>;
    final errors = sources[1].value as Map<String, String?>;
    
    // Form is valid if all fields have values and no errors
    return fields.values.every((v) => v.isNotEmpty) && 
           errors.values.every((e) => e == null);
  });
  
  // Submit function
  void submitForm() {
    if (isFormValid.value) {
      print('Form submitted: ${formFields.value}');
    } else {
      print('Cannot submit, form is invalid');
    }
  }
  
  // UI would update these values
  formFields.value = {
    'name': 'John Doe',
    'email': 'john@example.com',
    'age': '25',
  };
  
  print('Validation errors: ${validationErrors.value}');
  print('Is form valid: ${isFormValid.value}');
  submitForm();
}
```

### Filtered and Sorted Collection View

```dart
// Creating filtered and sorted views of collections
void main() {
  // Original todo items
  final todos = [
    {'id': 1, 'text': 'Buy groceries', 'completed': false, 'priority': 2},
    {'id': 2, 'text': 'Call mom', 'completed': true, 'priority': 1},
    {'id': 3, 'text': 'Finish project', 'completed': false, 'priority': 3},
    {'id': 4, 'text': 'Pay bills', 'completed': false, 'priority': 2},
  ].reactive;
  
  // Filter settings
  final showCompleted = false.reactive;
  
  // Sort settings
  final sortByPriority = true.reactive;
  
  // Computed filtered list
  final filteredTodos = Computed<List<Map<String, dynamic>>>([todos, showCompleted], (sources) {
    final allTodos = sources[0].value as List<Map<String, dynamic>>;
    final includeCompleted = sources[1].value as bool;
    
    if (includeCompleted) {
      return List.from(allTodos);
    } else {
      return allTodos.where((todo) => todo['completed'] == false).toList();
    }
  });
  
  // Computed sorted and filtered list
  final sortedFilteredTodos = Computed<List<Map<String, dynamic>>>(
    [filteredTodos, sortByPriority], 
    (sources) {
      final filtered = List<Map<String, dynamic>>.from(sources[0].value);
      final byPriority = sources[1].value as bool;
      
      if (byPriority) {
        filtered.sort((a, b) => (b['priority'] as int).compareTo(a['priority'] as int));
      } else {
        filtered.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
      }
      
      return filtered;
    }
  );
  
  // Display initial result
  print('Initial todos:');
  sortedFilteredTodos.value.forEach((todo) {
    print('${todo['text']} (Priority: ${todo['priority']})');
  });
  
  // Change filter settings
  showCompleted.value = true;
  
  // Display after filter change
  print('\nAfter showing completed:');
  sortedFilteredTodos.value.forEach((todo) {
    final status = todo['completed'] ? '✓' : '○';
    print('$status ${todo['text']} (Priority: ${todo['priority']})');
  });
  
  // Change sort settings
  sortByPriority.value = false;
  
  // Display after sort change
  print('\nAfter sorting by ID:');
  sortedFilteredTodos.value.forEach((todo) {
    final status = todo['completed'] ? '✓' : '○';
    print('$status ${todo['text']} (ID: ${todo['id']})');
  });
}
```

### Shopping Cart System

```dart
// A shopping cart system using reactive collections
void main() {
  // Product catalog
  final products = {
    'p1': {'name': 'T-shirt', 'price': 19.99, 'inventory': 10},
    'p2': {'name': 'Jeans', 'price': 49.99, 'inventory': 5},
    'p3': {'name': 'Hat', 'price': 14.99, 'inventory': 3},
  }.reactive;
  
  // Shopping cart - map of product IDs to quantities
  final cart = <String, int>{}.reactive;
  
  // Computed cart details
  final cartDetails = Computed<List<Map<String, dynamic>>>([cart, products], (sources) {
    final cartMap = sources[0].value as Map<String, int>;
    final productMap = sources[1].value as Map<String, Map<String, dynamic>>;
    
    return cartMap.entries.map((entry) {
      final productId = entry.key;
      final quantity = entry.value;
      final product = productMap[productId]!;
      
      return {
        'id': productId,
        'name': product['name'],
        'price': product['price'],
        'quantity': quantity,
        'total': (product['price'] as double) * quantity,
      };
    }).toList();
  });
  
  // Computed cart total
  final cartTotal = Computed<double>([cartDetails], (sources) {
    final details = sources[0].value as List<Map<String, dynamic>>;
    return details.fold(0.0, (sum, item) => sum + (item['total'] as double));
  });
  
  // Helper to add a product to cart
  void addToCart(String productId, [int quantity = 1]) {
    // Check inventory
    final inventory = (products.value[productId]?['inventory'] as int?) ?? 0;
    final currentQuantity = cart.value[productId] ?? 0;
    
    if (inventory >= currentQuantity + quantity) {
      final newCart = Map<String, int>.from(cart.value);
      newCart[productId] = currentQuantity + quantity;
      cart.value = newCart;
      
      // Update inventory
      final updatedProduct = Map<String, dynamic>.from(products.value[productId]!);
      updatedProduct['inventory'] = inventory - quantity;
      
      final newProducts = Map<String, Map<String, dynamic>>.from(products.value);
      newProducts[productId] = updatedProduct;
      products.value = newProducts;
      
      print('Added ${products.value[productId]?['name']} to cart');
    } else {
      print('Not enough inventory for ${products.value[productId]?['name']}');
    }
  }
  
  // Helper to remove a product from cart
  void removeFromCart(String productId, [int quantity = 1]) {
    final currentQuantity = cart.value[productId] ?? 0;
    if (currentQuantity <= 0) return;
    
    final newCart = Map<String, int>.from(cart.value);
    
    if (currentQuantity <= quantity) {
      newCart.remove(productId);
    } else {
      newCart[productId] = currentQuantity - quantity;
    }
    
    cart.value = newCart;
    
    // Update inventory
    final inventory = (products.value[productId]?['inventory'] as int?) ?? 0;
    final quantityToReturn = currentQuantity < quantity ? currentQuantity : quantity;
    
    final updatedProduct = Map<String, dynamic>.from(products.value[productId]!);
    updatedProduct['inventory'] = inventory + quantityToReturn;
    
    final newProducts = Map<String, Map<String, dynamic>>.from(products.value);
    newProducts[productId] = updatedProduct;
    products.value = newProducts;
    
    print('Removed ${products.value[productId]?['name']} from cart');
  }
  
  // Simulating user actions
  addToCart('p1', 2);
  addToCart('p2', 1);
  
  // Display cart status
  print('\nCart contents:');
  cartDetails.value.forEach((item) {
    print('${item['name']} x ${item['quantity']} = \$${item['total'].toStringAsFixed(2)}');
  });
  print('Total: \$${cartTotal.value.toStringAsFixed(2)}');
  
  // Update an item quantity
  addToCart('p1', 1);
  
  // Display updated cart
  print('\nUpdated cart:');
  cartDetails.value.forEach((item) {
    print('${item['name']} x ${item['quantity']} = \$${item['total'].toStringAsFixed(2)}');
  });
  print('Total: \$${cartTotal.value.toStringAsFixed(2)}');
  
  // Check inventory
  print('\nInventory status:');
  products.value.forEach((id, product) {
    print('${product['name']}: ${product['inventory']} left');
  });
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
Reactive<String> reactive = Reactive('test', middlewares: [LoggingMiddleware<String>()]);
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

## Memoization

Fluxivity provides a memoization utility for `Computed` instances to optimize performance by caching computation results. This is especially useful for expensive computations that depend on reactive values that might change to the same values repeatedly.

### Basic Usage

The `memoize` function creates a memoized version of a `Computed` instance that caches the results based on the values of its source reactives:

```dart
import 'package:fluxivity/fluxivity.dart';

// Create a normal computed instance
final count = Reactive(0);
final expensiveComputation = Computed([count], (sources) {
  // This could be an expensive operation
  print('Computing value...');
  return sources[0].value * 100;
});

// Create a memoized version with a cache size of 5
final memoizedComputation = memoize(expensiveComputation, cacheSize: 5);

// When accessed with the same input values, the cached result is returned
memoizedComputation.value; // Prints: "Computing value..." and returns 0
memoizedComputation.value; // Returns 0 without printing (cached)

// When the source value changes, it recomputes
count.value = 1;
memoizedComputation.value; // Prints: "Computing value..." and returns 100

// If we change back to a previously computed value, it uses the cache
count.value = 0;
memoizedComputation.value; // Returns 0 without printing (cached)
```

The memoization implementation uses an LRU cache strategy

```dart
// Create with different cache sizes based on your needs
final smallCache = memoize(computed, cacheSize: 1);  // Default size
final mediumCache = memoize(computed, cacheSize: 10);
final largeCache = memoize(computed, cacheSize: 100);
```

### When to Use Memoization

Memoization is most beneficial when:

1. The computation is expensive (complex calculations, string formatting, etc.)
2. The input values repeat frequently
3. The computed output is used in multiple places

For simple computations or when values rarely repeat, the overhead of memoization might outweigh its benefits.

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
