## 1.0.0

* Initial Version with the Reactive and Computed Classes

## 1.0.1

* Updated Readme and added License

## 1.1.0

* Both Reactive and Computed classes emits initial event on subscription. This adds an additional dependency on the `rxdart` package.
* Tests are added. Use `dart test` to run these
* Added class documentation internally
* Updated readme

## 1.1.1
* Downgraded async package to not clash with flutter_test's async package version
* Included example app
* Exported Snapshot class to be usable in Streams

## 1.2.0
* Removed the graph dependency methods from reactive to be implemented later
* Added the temperature conversion example code

## 1.3.0  - 2023-04-07
* Added: ReactiveListExtensions for providing reactive capabilities to regular lists, allowing users to seamlessly observe and react to list changes.
  * The reactive getter has been added to the List class, enabling conversion of regular lists into reactive lists.
  * ReactiveListExtensions includes overrides for common list manipulation methods, ensuring that the reactive list emits updates when modified.
  * A new addEffect method allows users to define custom functions (effects) that will be executed automatically whenever the list is modified.
  * The unwrap method has been introduced to convert a reactive list back to a regular list when needed.

## [1.4.0] - 2023-04-07

### Added
- Support for middlewares in the Fluxivity package, allowing users to add custom logic as part of the reactive chain.
- Error handling in computed flow, providing a more robust implementation and better error handling for users when working with computed values.
- Batched updates functionality, enabling users to perform multiple updates to reactive values without triggering an update for each individual change. This reduces unnecessary computations and improves performance.
- Example usage with the Hive package, demonstrating how to integrate Fluxivity with Hive for efficient and reactive data storage and retrieval in Flutter applications.

## [1.5.0] - 2025-05-08

### Updated
- Dependency versions for collections, async and rxdart

## [1.6.0] - 2025-05-08

### Added
- Improved batch update handling with empty list protection
- Enhanced subscription management in Computed class
- Better resource cleanup with more robust disposal methods

### Changed
- Simplified ReactiveList implementation for better reliability. Replaced complex wrapper approach with a more direct implementation
- Improved stability for deeply nested reactive structures

### Fixed
- Resolved issues with list mutation notifications
- Fixed "Bad state: No element" errors in batch updates
- Addressed timing issues in asynchronous operations

## [1.7.0] - 2025-05-09

### Added
- Added support for reactive Maps through the `ReactiveMapExtensions`
- Added support for reactive Sets through the `ReactiveSetExtensions`

### Changed
- Standardized the reactive collection API pattern across Lists, Maps, and Sets
- Enhanced documentation for all reactive collection types

### Fixed
- Fixed middleware integration with collection operations

## [1.8.0] - 2025-05-10

### Added
- Memoization support for `Computed` instances through the `memoize` function
- LRU (Least Recently Used) cache implementation with configurable cache size
- Delegation pattern for memoized computed values to preserve the original API

### Changed
- Exposed `sources` getter in the `Computed` class to support memoization
- Enhanced README with documentation for the memoization feature
