/// Strict JSON-schema validator for a tool's arguments.
///
/// The subset implemented here is intentionally minimal — enough to
/// validate the argument shapes the agent tools actually use today:
///   - object with `properties`, `required`, `additionalProperties`
///   - primitive types: string, integer, number, boolean
///   - homogeneous `array` with an `items` schema
///   - optional `enum` for primitives
///
/// We lean strict by default: unknown keys are rejected unless
/// `additionalProperties: true` is set explicitly on the schema.
class ToolArgumentSchema {
  const ToolArgumentSchema(this.jsonSchema);

  /// A valid schema for tools that take no arguments.
  static const ToolArgumentSchema empty = ToolArgumentSchema(
    <String, Object?>{'type': 'object', 'properties': <String, Object?>{}},
  );

  /// The raw JSON schema document. Exposed verbatim so the transport
  /// layer can forward it to the model's tool-definition payload.
  final Map<String, Object?> jsonSchema;

  /// Validates [args] against [jsonSchema]. Returns `null` on success,
  /// or a structured error describing the first failure.
  ToolArgumentValidationError? validate(Map<String, Object?> args) {
    return _validate(jsonSchema, args, const <String>[]);
  }

  static ToolArgumentValidationError? _validate(
    Map<String, Object?> schema,
    Object? value,
    List<String> path,
  ) {
    final type = schema['type'];
    if (type is! String) {
      return ToolArgumentValidationError(
        path: path,
        code: 'schema_missing_type',
        message: 'Schema at ${_joinPath(path)} has no "type" declaration.',
      );
    }

    switch (type) {
      case 'object':
        return _validateObject(schema, value, path);
      case 'array':
        return _validateArray(schema, value, path);
      case 'string':
        if (value is! String) {
          return _typeError(path, 'string', value);
        }
        return _validateEnum(schema, value, path);
      case 'integer':
        if (value is! int) {
          return _typeError(path, 'integer', value);
        }
        return _validateEnum(schema, value, path);
      case 'number':
        if (value is! num) {
          return _typeError(path, 'number', value);
        }
        return _validateEnum(schema, value, path);
      case 'boolean':
        if (value is! bool) {
          return _typeError(path, 'boolean', value);
        }
        return null;
      default:
        return ToolArgumentValidationError(
          path: path,
          code: 'schema_unsupported_type',
          message: 'Unsupported schema type "$type" at ${_joinPath(path)}.',
        );
    }
  }

  static ToolArgumentValidationError? _validateObject(
    Map<String, Object?> schema,
    Object? value,
    List<String> path,
  ) {
    if (value is! Map<String, Object?>) {
      return _typeError(path, 'object', value);
    }

    final properties = schema['properties'];
    final propertyMap = properties is Map<String, Object?>
        ? properties
        : const <String, Object?>{};

    final required = schema['required'];
    if (required is List) {
      for (final key in required) {
        if (key is! String) continue;
        if (!value.containsKey(key)) {
          return ToolArgumentValidationError(
            path: [...path, key],
            code: 'missing_required',
            message: 'Required property "$key" is missing.',
          );
        }
      }
    }

    final allowAdditional = schema['additionalProperties'] == true;
    if (!allowAdditional) {
      for (final key in value.keys) {
        if (!propertyMap.containsKey(key)) {
          return ToolArgumentValidationError(
            path: [...path, key],
            code: 'unknown_property',
            message: 'Unknown property "$key" is not allowed.',
          );
        }
      }
    }

    for (final entry in propertyMap.entries) {
      if (!value.containsKey(entry.key)) continue;
      final childSchema = entry.value;
      if (childSchema is! Map<String, Object?>) continue;
      final childError = _validate(
        childSchema,
        value[entry.key],
        [...path, entry.key],
      );
      if (childError != null) return childError;
    }

    return null;
  }

  static ToolArgumentValidationError? _validateArray(
    Map<String, Object?> schema,
    Object? value,
    List<String> path,
  ) {
    if (value is! List) {
      return _typeError(path, 'array', value);
    }
    final items = schema['items'];
    if (items is! Map<String, Object?>) {
      return null;
    }
    for (var i = 0; i < value.length; i++) {
      final error = _validate(items, value[i], [...path, '[$i]']);
      if (error != null) return error;
    }
    return null;
  }

  static ToolArgumentValidationError? _validateEnum(
    Map<String, Object?> schema,
    Object value,
    List<String> path,
  ) {
    final allowed = schema['enum'];
    if (allowed is! List) return null;
    if (!allowed.contains(value)) {
      return ToolArgumentValidationError(
        path: path,
        code: 'enum_mismatch',
        message:
            'Value $value at ${_joinPath(path)} is not one of the allowed enum values.',
      );
    }
    return null;
  }

  static ToolArgumentValidationError _typeError(
    List<String> path,
    String expected,
    Object? actual,
  ) {
    return ToolArgumentValidationError(
      path: path,
      code: 'type_mismatch',
      message:
          'Expected $expected at ${_joinPath(path)} but got ${actual.runtimeType}.',
    );
  }

  static String _joinPath(List<String> path) {
    if (path.isEmpty) return '<root>';
    return path.join('.');
  }
}

/// Structured description of a validation failure. Short enough to be
/// fed back to the model as a tool-result error so it can self-correct.
class ToolArgumentValidationError {
  const ToolArgumentValidationError({
    required this.path,
    required this.code,
    required this.message,
  });

  final List<String> path;
  final String code;
  final String message;

  Map<String, Object?> toJson() => {
    'path': path,
    'code': code,
    'message': message,
  };

  @override
  String toString() => 'ToolArgumentValidationError($code @ ${path.join('.')})';
}
