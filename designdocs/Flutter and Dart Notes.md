# Flutter and Dart notes

This document serves as a Q&A while I'm simultaneously learning Flutter and Dart

### What are Keys?

Keys are unique identifiers for widgets in the widget tree. They help Flutter track, move, or replace widgets during rebuilds.

Flutter's rendering is declarative: "The UI = result of my current state."

When state changes -> Flutter rebuilds widgets.

### What is {super.key} for?

This is Dart's way of handling widget keys with named parameters.

In Flutter, Key is a special object you can use to identify widgets in the tree (for optimization, animations, preserving state).

It's passing the key up to the parent class (StatelessWidget or StatefulWidget)

### Stateless vs Stateful Widgets

StatelessWidget:

- Immutable
- Displays UI based solely on input parameters
- Never changes one built

StatefulWidget:

- Has mutable internal state
- Can rebuild when state changes

### What are the underscores in front of variables or classes?

The underscore in Dart is used to mark private members in a file. This is encapsulation, and Dart does not have "public" or "private" like Java.

### What is Scaffold?

It provides a standard structure to the app's UI.

### What is `late` in Dart?

`late` is a keyword in Dart that tells the compiler: "I promise to assign this variable before I use it."

- It's for non-nullable variables that can't be assigned at declaration time, but will be assigned later.

Why do we need it for controllers?
A `TextEditingController` must be initialized with something, but in Flutter's StatefulWidget:

- You often don't have access to BuildContext or Provider in the constructor
- Instead, you want to set it up in initState();

### What is initState()? Why override it?

initState() is a lifecycle method in StatefulWidget's State class

- It's called once when the State object is first inserted into the widget tree

You override it to do one-time setup:

- Initialize controllers
- Fetch initial data
- Subscribe to streams

### What is TextEditingController?

TextEditingController is a helper class in Flutter that:

- Controls the content of a TextField
- Lets you read, set, and listen to text changes

### What is dispose()?

Another lifecycle method for StatefulWidget

- Called once when the State object is permanently removed from the widget tree.

Override it to clean up resources:

- Close streams
- Remove listeners
- Dipose of conrollers

### What is SnackBar and ScaffoldMessenger?

SnackBar is a Material Design component in Flutter for showing temporary, unobtrusive mesages at the bottom of the screen.

- Notify users of simple feedback.
- Confirm actions
- Show errors without blocking UI

ScaffoldMessenger is a Flutter widget introduced to manage showing SnackBars (and other transient UI like banners) in the app.
It lives above your Scaffold in the widget tree.

- Manages queueing multiple SnackBars
- Makes SnackBars survive route changes (navigation)
- Controls showing, hiding and dismissing SnackBars centrally.

### What are the question marks next to the parameter types?

In Dart, the "?" means the type is nullable

### What do the double question marks mean?

This is Dart's null-coalescing operation

a ?? b means: "If a is not null, use a. Else, use b."
