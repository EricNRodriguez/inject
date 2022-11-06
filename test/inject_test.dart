import 'dart:math';

import 'package:inject/inject.dart';
import 'package:inject/src/error.dart';
import 'package:test/test.dart';

class ObjWithDeps {
  final String name;
  final ObjWithDeps? dep1;
  final ObjWithDeps? dep2;

  ObjWithDeps(this.name, this.dep1, this.dep2);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ObjWithDeps && runtimeType == other.runtimeType &&
              name == other.name && dep1 == other.dep1 && dep2 == other.dep2;

  @override
  int get hashCode => name.hashCode ^ dep1.hashCode ^ dep2.hashCode;
}

void main() {
  test('correctly constructs simple object graph', () {
    ObjWithDeps buildA(DependencyContainer container) {
      return ObjWithDeps(
          "aye",
          container<ObjWithDeps>(key: "B"),
          container<ObjWithDeps>(key: "C"),
      );
    }

    ObjWithDeps buildB(DependencyContainer container) {
      return ObjWithDeps(
        "bee",
        container<ObjWithDeps>(key: "C"),
        container<ObjWithDeps>(key: "D"),
      );
    }

    ObjWithDeps buildC(DependencyContainer container) {
      return ObjWithDeps(
        "see",
        container<ObjWithDeps>(key: "D"),
        null,
      );
    }

    ObjWithDeps buildD(DependencyContainer container) {
      return ObjWithDeps(
          "dee",
          null,
          null,
      );
    }

    DependencyContainerBuilder containerBuilder = DependencyContainerBuilder()
      ..withFactory(buildA, key: "A")
      ..withFactory(buildB, key: "B")
      ..withFactory(buildC, key: "C")
      ..withFactory(buildD, key: "D");

    DependencyContainer container = containerBuilder.build();

    ObjWithDeps expectedObjectGraph = ObjWithDeps(
      "aye",
      ObjWithDeps(
        "bee",
        ObjWithDeps(
          "see",
          ObjWithDeps(
            "dee",
            null,
            null,
          ),
          null,
        ),
        ObjWithDeps(
          "dee",
          null,
          null,
        )
      ),
      ObjWithDeps(
        "see",
          ObjWithDeps(
            "dee",
            null,
            null,
          ),
        null,
      )
    );

    ObjWithDeps constructedObjectGraph = container<ObjWithDeps>(key: "A");

    expect(constructedObjectGraph, equals(expectedObjectGraph));
  });

  test('only constructs singletons a single time', () {
    ObjWithDeps buildA(DependencyContainer container) {
      return ObjWithDeps(
        "aye",
        container<ObjWithDeps>(key: "B"),
        container<ObjWithDeps>(key: "B"),
      );
    }

    ObjWithDeps buildB(DependencyContainer container) {
      return ObjWithDeps(
        "bee",
        null,
        null,
      );
    }

    DependencyContainerBuilder containerBuilder = DependencyContainerBuilder()
      ..withFactory(buildA, key: "A")
      ..withLazySingleton(buildB, key: "B");

    DependencyContainer container = containerBuilder.build();

    ObjWithDeps constructedObj = container<ObjWithDeps>(key: "A");

    expect(constructedObj.dep1, isNotNull);
    expect(constructedObj.dep1, equals(constructedObj.dep2));
  });

  test('throws when cycle is detected', () {
    ObjWithDeps buildA(DependencyContainer container) {
      return ObjWithDeps(
        "aye",
        container<ObjWithDeps>(key: "B"),
        container<ObjWithDeps>(key: "B"),
      );
    }

    ObjWithDeps buildB(DependencyContainer container) {
      return ObjWithDeps(
        "bee",
        container<ObjWithDeps>(key: "C"),
        null,
      );
    }

    ObjWithDeps buildC(DependencyContainer container) {
      return ObjWithDeps(
        "see",
        container<ObjWithDeps>(key: "B"),
        null,
      );
    }


    DependencyContainerBuilder containerBuilder = DependencyContainerBuilder()
      ..withFactory(buildA, key: "A")
      ..withFactory(buildB, key: "B")
      ..withFactory(buildC, key: "C");

    DependencyContainer container = containerBuilder.build();

    expect(() => container<ObjWithDeps>(key: "A"), throwsCircularDependencyError);
    expect(() => container<ObjWithDeps>(key: "B"), throwsCircularDependencyError);
    expect(() => container<ObjWithDeps>(key: "C"), throwsCircularDependencyError);
  });
}

const isCircularDependencyError = TypeMatcher<CircularDependencyError>();
const Matcher throwsCircularDependencyError = Throws(isCircularDependencyError);

