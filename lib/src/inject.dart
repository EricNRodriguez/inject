import 'package:inject/inject.dart';
import 'package:inject/src/error.dart';

typedef Factory<T> = T Function(DependencyContainer container);

abstract class DependencyContainer {
  T get<T>({String key});
}

const _DEFAULT_RESOURCE_KEY =
    "internal default resource key, should never conflict with anything a user ever provides. Lol If you hit this";

class DependencyContainerBuilder {
  FactoryRegistry registry = FactoryRegistry();

  void withFactory<T>(Factory<T> factory,
      {String key = _DEFAULT_RESOURCE_KEY}) {
    registry.registerFactory<T>(key, factory);
  }

  void withSingleton<T>(T value, {String key = _DEFAULT_RESOURCE_KEY}) {
    registry.registerFactory<T>(key, (_) => value);
  }

  void withLazySingleton<T>(Factory<T> factory,
      {String key = _DEFAULT_RESOURCE_KEY}) {
    registry.registerFactory<T>(key, _FactoryUtils.memo(factory));
  }

  DependencyContainer build() {
    return _DependencyContainerImpl(registry);
  }
}

class FactoryRegistry {
  final Map<_FactoryRegistryKey, dynamic> _syncDependencies = {};

  void registerFactory<T>(String key, Factory<T> factory) {
    _FactoryRegistryKey registryKey = _FactoryRegistryKey(T, key);
    if (_syncDependencies.containsKey(registryKey)) {
      throw DuplicateRegistrationError(
          "dependency identified by (type: $T, key: $key) has already been registered");
    }

    factory = _FactoryUtils.wrapFactoryWithCycleDetection(factory, registryKey);

    _syncDependencies[registryKey] = factory;
  }

  Factory<T>? getFactory<T>(String key) {
    return _syncDependencies[_FactoryRegistryKey(T, key)];
  }
}

class _DependencyContainerImpl implements DependencyContainer {
  final FactoryRegistry _factoryRegistry;

  _DependencyContainerImpl(this._factoryRegistry);

  @override
  T get<T>({String key = _DEFAULT_RESOURCE_KEY}) {
    Factory<T>? factory = _factoryRegistry.getFactory<T>(key);
    if (factory == null) {
      throw UnknownFactoryError(
          "factory for dependency with type $T and key $key has not been registered");
    }

    return factory(this);
  }
}

class _FactoryRegistryKey {
  final Type type;
  final String key;

  _FactoryRegistryKey(this.type, this.key);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _FactoryRegistryKey &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          key == other.key;

  @override
  int get hashCode => type.hashCode ^ key.hashCode;

  @override
  String toString() {
    return '_FactoryRegistryKey{type: $type, name: $key}';
  }
}

class _FactoryUtils {
  // TODO(ericr): Figure out how to detect circular deps in async factories in a clean way
  static Factory<T> wrapFactoryWithCycleDetection<T>(
      Factory<T> function, _FactoryRegistryKey key) {
    bool isExecuting = false;
    return (DependencyContainer container) {
      if (isExecuting) {
        throw CircularDependencyError(
            "circular dependency detected for dependency $key");
      }

      try {
        isExecuting = true;
        return function(container);
      } finally {
        isExecuting = false;
      }
    };
  }

  static Factory<T> memo<T>(Factory<T> factory) {
    bool hasRun = false;
    T? value;

    return (DependencyContainer container) {
      if (!hasRun) {
        value = factory(container);
        hasRun = true;
      }

      return value as T;
    };
  }
}
