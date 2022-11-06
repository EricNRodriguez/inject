import 'package:inject/inject.dart';
import 'package:test/test.dart';

class A {
  final String name;

  static A buildWithEric(DependencyContainer container) {
    return A(container<String>(key: "eric"));
  }

  static A buildWithCarl(DependencyContainer container) {
    return A(container<String>(key: "carl"));
  }

  static A buildWithNone(DependencyContainer container) {
    return A("none:((");
  }

  A(this.name);

  @override
  String toString() {
    return "A\n\t\t\t$name";
  }
}

class B {
  final A a;

  static B build(DependencyContainer container) {
    return B(container<A>());
  }

  B(this.a);

  @override
  String toString() {
    return "B\n\t\t$a";
  }
}

class C {
  final A? a;
  final B? b;

  static C buildWithCarlA(DependencyContainer container) {
    return C(container<A>(key: "carl"), container<B>());
  }

  static C buildWithEricA(DependencyContainer container) {
    return C(container<A>(key: "eric"), container<B>());
  }

  static Future<C> buildAsync(DependencyContainer container) {
    return Future.value(C(container<A>(), container<B>()));
  }

  C(this.a, this.b);

  @override
  String toString() {
    return "C\n\t$a\n\t$b\n";
  }
}

void main() {
  test('duplicate singletons', () {
    DependencyContainerBuilder builder = DependencyContainerBuilder()
      ..withSingleton<String>("HI", key: "greeting")
      ..withFactory((container) => "HI", key: "greetin2g");

    DependencyContainer container = builder.build();
  });
  test('throwaway', () async {
    DependencyContainerBuilder builder = DependencyContainerBuilder()
      ..withSingleton<String>("eric!!!!!!!", key: "eric")
      ..withFactory<String>((_) => "carl!!!!!!!", key: "carl")
      ..withFactory<C>(C.buildWithCarlA, key: "carl")
      ..withFactory<C>(C.buildWithEricA, key: "eric")
      ..withFactory<Future<C>>(C.buildAsync)
      ..withFactory<B>(B.build)
      ..withFactory<A>(A.buildWithCarl, key: "carl")
      ..withSingleton<A>(A("eric!!!!!!!"), key: "eric")
      ..withSingleton<A>(A("eric!!!!!!!"), key: "erizzzzc")
      ..withFactory((container) => A("eric!!!!!!!2"));

    DependencyContainer container = builder.build();

    C c1 = container<C>(key: "carl");
    C c2 = container<C>(key: "carl");

    print(c1.a == c2.a);

    C c3 = container<C>(key: "eric");
    C c4 = container<C>(key: "eric");

    print(c3.a == c4.a);
  });
}
