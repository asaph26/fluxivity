# Fluxivity

Fluxivity is an experimental package to study the effect of building a reactive graph. The
code in the library can be improved to be better at code. 

**⚠️ Its important to note that this package hasn't been tested as it was hacked together on a whim. This notice will be removed once this condition is false**

Package is available on pub.dev [here](https://pub.dev/packages/fluxivity)

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

## Why this package

As state management solutions have exploded, I often find myself looking for simpler solutions 
that help with the following principles

* App state should be global
* View Models should only contain value/data accessors and not the data themselves
* It should be possible to construct a graph like structure of App state.
* It should be possible to access latest data without waiting on a value
* It should be possible to track changes to data if required
* Have a functional approach to dealing with changes

While people might disagree with the above principles, I believe there is a niche for them in the
ecosystem where it adds value, 

## Example Usage

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