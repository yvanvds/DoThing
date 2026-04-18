import 'package:do_thing/agent/tools/tool_argument_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToolArgumentSchema.validate', () {
    test('accepts empty object for the empty schema', () {
      expect(
        ToolArgumentSchema.empty.validate(const <String, Object?>{}),
        isNull,
      );
    });

    test('rejects unknown properties by default (strict mode)', () {
      const schema = ToolArgumentSchema(<String, Object?>{
        'type': 'object',
        'properties': <String, Object?>{},
      });

      final error = schema.validate(const <String, Object?>{'foo': 1});

      expect(error, isNotNull);
      expect(error!.code, 'unknown_property');
      expect(error.path, ['foo']);
    });

    test('accepts unknown properties when additionalProperties is true', () {
      const schema = ToolArgumentSchema(<String, Object?>{
        'type': 'object',
        'additionalProperties': true,
        'properties': <String, Object?>{},
      });

      expect(schema.validate(const <String, Object?>{'foo': 1}), isNull);
    });

    test('flags missing required fields', () {
      const schema = ToolArgumentSchema(<String, Object?>{
        'type': 'object',
        'required': ['id'],
        'properties': <String, Object?>{
          'id': <String, Object?>{'type': 'string'},
        },
      });

      final error = schema.validate(const <String, Object?>{});

      expect(error, isNotNull);
      expect(error!.code, 'missing_required');
      expect(error.path, ['id']);
    });

    test('flags a type mismatch on a primitive property', () {
      const schema = ToolArgumentSchema(<String, Object?>{
        'type': 'object',
        'properties': <String, Object?>{
          'count': <String, Object?>{'type': 'integer'},
        },
      });

      final error = schema.validate(const <String, Object?>{'count': 'two'});

      expect(error, isNotNull);
      expect(error!.code, 'type_mismatch');
      expect(error.path, ['count']);
    });

    test('accepts valid primitive values', () {
      const schema = ToolArgumentSchema(<String, Object?>{
        'type': 'object',
        'required': ['id', 'unread'],
        'properties': <String, Object?>{
          'id': <String, Object?>{'type': 'string'},
          'unread': <String, Object?>{'type': 'boolean'},
        },
      });

      expect(
        schema.validate(const <String, Object?>{'id': 'abc', 'unread': true}),
        isNull,
      );
    });

    test('descends into nested object properties', () {
      const schema = ToolArgumentSchema(<String, Object?>{
        'type': 'object',
        'properties': <String, Object?>{
          'filter': <String, Object?>{
            'type': 'object',
            'properties': <String, Object?>{
              'limit': <String, Object?>{'type': 'integer'},
            },
          },
        },
      });

      final error = schema.validate(const <String, Object?>{
        'filter': <String, Object?>{'limit': 'many'},
      });

      expect(error, isNotNull);
      expect(error!.code, 'type_mismatch');
      expect(error.path, ['filter', 'limit']);
    });

    test('validates array items element-by-element', () {
      const schema = ToolArgumentSchema(<String, Object?>{
        'type': 'object',
        'properties': <String, Object?>{
          'ids': <String, Object?>{
            'type': 'array',
            'items': <String, Object?>{'type': 'string'},
          },
        },
      });

      final ok = schema.validate(const <String, Object?>{
        'ids': <String>['a', 'b'],
      });
      expect(ok, isNull);

      final error = schema.validate(const <String, Object?>{
        'ids': <Object?>['a', 2],
      });
      expect(error, isNotNull);
      expect(error!.code, 'type_mismatch');
      expect(error.path, ['ids', '[1]']);
    });

    test('enforces enum values on primitives', () {
      const schema = ToolArgumentSchema(<String, Object?>{
        'type': 'object',
        'properties': <String, Object?>{
          'mode': <String, Object?>{
            'type': 'string',
            'enum': ['reply', 'forward'],
          },
        },
      });

      expect(
        schema.validate(const <String, Object?>{'mode': 'reply'}),
        isNull,
      );
      final error = schema.validate(const <String, Object?>{'mode': 'noop'});
      expect(error, isNotNull);
      expect(error!.code, 'enum_mismatch');
    });

    test('reports schema_missing_type for a malformed schema', () {
      const schema = ToolArgumentSchema(<String, Object?>{
        'properties': <String, Object?>{},
      });

      final error = schema.validate(const <String, Object?>{});

      expect(error, isNotNull);
      expect(error!.code, 'schema_missing_type');
    });
  });
}
