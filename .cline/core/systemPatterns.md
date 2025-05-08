# System Patterns: Fluxivity

## Architectural Overview

Fluxivity implements a reactive programming architecture based on the Observer pattern and functional reactive programming (FRP) principles. The system is built around the following core patterns:

### 1. Observable Pattern

The Observable pattern forms the foundation of Fluxivity's reactivity system:

```mermaid
classDiagram
    class Reactive~T~ {
        -T _value
        -BehaviorSubject _controller
        +T value
        +Stream~Snapshot~ stream
        +startBatchUpdate()
        +endBatchUpdate()
        +addEffect()
    }
    class Observer {
        +onNext(Snapshot)
    }
    Reactive --> Observer : notifies
```

- **Observable**: Represented by `Reactive<T>` and `Computed<T>`
- **Observer**: Any listener subscribed to the `stream` property
- **Notification**: Delivered via the `Snapshot<T>` objects containing old and new values

This implementation allows for:
- Type-safe reactivity
- Declarative subscriptions
- Granular update notifications

### 2. Computed Properties Pattern

Computed values implement a derivation pattern where values are calculated based on dependencies:

```mermaid
flowchart TD
    A[Reactive A] --> C[Computed X]
    B[Reactive B] --> C
    C --> D[UI Component]
```

Key aspects:
- Automatic dependency tracking
- Lazy evaluation (compute only when requested)
- Efficient updates (only when dependencies change)
- Caching of computed results

### 3. Middleware Pattern

The middleware pattern enables extensible behavior chains for reactive updates:

```mermaid
sequenceDiagram
    participant V as Value
    participant M1 as Middleware 1
    participant M2 as Middleware 2
    participant S as Subscribers
    
    V->>M1: beforeUpdate
    M1->>M2: beforeUpdate
    M2->>V: Update Value
    M2->>M1: afterUpdate
    M1->>S: Notify if shouldEmit
```

This design allows for:
- Separation of concerns
- Extensible behavior
- Aspect-oriented programming techniques
- Pluggable cross-cutting concerns

### 4. Batch Processing Pattern

The batch update pattern allows grouping multiple updates to optimize performance:

```mermaid
sequenceDiagram
    participant A as Application
    participant R as Reactive
    participant S as Subscribers
    
    A->>R: startBatchUpdate()
    A->>R: value = newValue1
    Note over R,S: No notification sent
    A->>R: value = newValue2
    Note over R,S: No notification sent
    A->>R: endBatchUpdate()
    R->>S: Single notification
```

Benefits include:
- Reduced notification overhead
- Consistent snapshots
- Atomic updates
- Prevention of UI thrashing

### 5. Reactive Collection Pattern

Collections are made reactive through a delegation and wrapper pattern:

```mermaid
classDiagram
    class List~E~ {
        +add(E)
        +remove(E)
        +operator[](int)
    }
    class ReactiveListWrapper~E~ {
        -Reactive~List~ _reactiveList
        +add(E)
        +remove(E)
        +operator[](int)
    }
    List <|-- ReactiveListWrapper : delegates to
    ReactiveListWrapper --> List : wraps
```

This pattern allows:
- Standard collection API
- Transparent reactivity
- Operation-level notifications
- Efficient collection manipulation

## Data Flow Architecture

Fluxivity implements a unidirectional data flow architecture:

```mermaid
flowchart LR
    A[Action] --> B[Reactive State]
    B --> C[Computed State]
    subgraph Middleware
    D[Before Update]
    E[After Update]
    end
    B -.-> D
    D -.-> E
    E -.-> B
    C --> F[UI]
    F --> A
```

1. **Action**: User interaction or system event triggers a state change
2. **Middleware Processing**: Intercepts updates for processing
3. **State Update**: Reactive state is modified
4. **Propagation**: Changes flow to computed values
5. **Rendering**: UI components respond to state changes

## Composability Model

Fluxivity is designed for composition rather than inheritance:

```mermaid
flowchart TD
    A[Reactive A] --> X[Computed X]
    B[Reactive B] --> X
    C[Reactive C] --> Y[Computed Y]
    X --> Z[Computed Z]
    Y --> Z
```

Components are composed through:
- Function composition
- Stream transformation
- Reactive dependencies
- Middleware chains

This approach facilitates:
- Code reuse
- Testability
- Separation of concerns
- Scalable complexity management

## Error Handling Pattern

Error management follows a consistent pattern throughout the library:

```mermaid
flowchart TD
    A[Operation] --> B{Success?}
    B -->|Yes| C[Continue]
    B -->|No| D[Middleware.onError]
    D --> E[Propagate or Handle]
```

Errors are:
1. Captured in try/catch blocks
2. Passed to middleware for handling
3. Optionally propagated or suppressed
4. Documented in the resulting state

## Implementation Principles

The implementation of Fluxivity adheres to several core principles:

1. **Immutability**: State changes create new snapshots rather than mutating existing state
2. **Transparency**: All reactivity is explicit and visible, avoiding "magic" behavior
3. **Minimal API Surface**: Core functionality is exposed through a small, focused API
4. **Composition Over Inheritance**: Building complex behaviors from simple components
5. **Strong Typing**: Leveraging Dart's type system for safety and editor support
