A nofrills DI container for Dart that does not use reflection, rather taking advantage of reified generics.

## Features

- support for both sync and async factories
- support for lazy loading singletons
- support for keys  (ie multiple instances of the same type, de-duped by key)

## Usage

```dart
import 'package:inject/inject.dart';
import 'package:test/test.dart';

class A {
  final String name;

  A(this.name);
}

class B {
  final A a;

  B(this.a);
}

class C {
  final A a;
  final B b;

  C(this.a, this.b);
}

void main() {
  test('example', ()
  {
    DependencyContainerBuilder containerBuilder = DependencyContainerBuilder()
      ..withSingleton("our-super-secret-api-key", key: "api-key")
      ..withSingleton(5, key: "api-key-expiry-days")
      ..withLazySingleton((container) => A(container.get<String>(key: "api-key")))
      ..withFactory((container) => B(container.get<A>()))
      ..withFactory((container) => C(container.get<A>(), container.get<B>()));

    DependencyContainer container = containerBuilder.build();

    C c1 = container.get<C>();
    C c2 = container.get<C>();

    expect(c1 == c2, isFalse);
    expect(c1.b == c2.b, isFalse);
    expect(c1.a == c2.a, isTrue);
    expect(c1.a == c1.b.a, isTrue);
  });
}

```