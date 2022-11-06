class DuplicateRegistrationError extends Error {
  final String _msg;

  DuplicateRegistrationError(this._msg);

  @override
  String toString() {
    return "DuplicateRegistrationError($_msg)";
  }
}

class UnknownFactoryError extends Error {
  final String _msg;

  UnknownFactoryError(this._msg);

  @override
  String toString() {
    return "UnknownFactoryError($_msg)";
  }
}

class CircularDependencyError extends Error {
  final String _msg;

  CircularDependencyError(this._msg);

  @override
  String toString() {
    return "CircularDependencyError($_msg)";
  }
}
