import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:proteingrid/data/protein_log.dart';

void main() {
  group('ProteinLog model', () {
    test('constructs with required fields', () {
      final ts = DateTime(2024, 1, 15, 9, 30);
      final log = ProteinLog(id: 'abc-123', grams: 35.0, timestamp: ts);

      expect(log.id, 'abc-123');
      expect(log.grams, 35.0);
      expect(log.label, isNull);
      expect(log.timestamp, ts);
    });

    test('constructs with optional label', () {
      final log = ProteinLog(
        id: 'xyz-456',
        grams: 50.0,
        timestamp: DateTime.now(),
        label: 'Chicken breast',
      );
      expect(log.label, 'Chicken breast');
    });

    test('label can be null', () {
      final log = ProteinLog(
        id: 'no-label',
        grams: 25.0,
        timestamp: DateTime.now(),
      );
      expect(log.label, isNull);
    });

    test('grams supports decimal values', () {
      final log = ProteinLog(id: 'dec', grams: 27.5, timestamp: DateTime.now());
      expect(log.grams, 27.5);
    });

    test('grams can be zero', () {
      final log = ProteinLog(id: 'zero', grams: 0, timestamp: DateTime.now());
      expect(log.grams, 0.0);
    });

    test('distinct instances are independent', () {
      final ts = DateTime(2024, 6);
      final a = ProteinLog(id: 'a', grams: 10, timestamp: ts, label: 'Egg');
      final b = ProteinLog(id: 'b', grams: 20, timestamp: ts);

      expect(a.id, isNot(b.id));
      expect(a.grams, isNot(b.grams));
      expect(a.label, isNotNull);
      expect(b.label, isNull);
    });
  });

  group('ProteinLogAdapter', () {
    test('typeId is 0', () {
      expect(ProteinLogAdapter().typeId, 0);
    });

    test('round-trips log with label through write/read', () {
      final adapter = ProteinLogAdapter();
      final ts = DateTime.fromMillisecondsSinceEpoch(1_700_000_000_000);
      final original = ProteinLog(
        id: 'round-trip',
        grams: 42.0,
        label: 'Greek yogurt',
        timestamp: ts,
      );

      final writer = _FakeWriter();
      adapter.write(writer, original);
      final reader = _FakeReader(writer.values);
      final restored = adapter.read(reader);

      expect(restored.id, original.id);
      expect(restored.grams, original.grams);
      expect(restored.label, original.label);
      expect(
        restored.timestamp.millisecondsSinceEpoch,
        original.timestamp.millisecondsSinceEpoch,
      );
    });

    test('round-trips log without label', () {
      final adapter = ProteinLogAdapter();
      final ts = DateTime.fromMillisecondsSinceEpoch(1_700_000_000_001);
      final original = ProteinLog(
        id: 'no-label-trip',
        grams: 30.0,
        timestamp: ts,
      );

      final writer = _FakeWriter();
      adapter.write(writer, original);
      final reader = _FakeReader(writer.values);
      final restored = adapter.read(reader);

      expect(restored.id, original.id);
      expect(restored.grams, original.grams);
      expect(restored.label, isNull);
      expect(
        restored.timestamp.millisecondsSinceEpoch,
        original.timestamp.millisecondsSinceEpoch,
      );
    });

    test('write encodes 5 values when label is non-null', () {
      final adapter = ProteinLogAdapter();
      final writer = _FakeWriter();
      adapter.write(
        writer,
        ProteinLog(
          id: 'a',
          grams: 10,
          timestamp: DateTime.now(),
          label: 'Eggs',
        ),
      );
      // id, grams, hasLabel=true, label, timestampMs
      expect(writer.values.length, 5);
      expect(writer.values[2], isTrue); // hasLabel flag
    });

    test('write encodes 4 values when label is null', () {
      final adapter = ProteinLogAdapter();
      final writer = _FakeWriter();
      adapter.write(
        writer,
        ProteinLog(id: 'b', grams: 10, timestamp: DateTime.now()),
      );
      // id, grams, hasLabel=false, timestampMs (no label string)
      expect(writer.values.length, 4);
      expect(writer.values[2], isFalse); // hasLabel flag
    });
  });
}

// ---------------------------------------------------------------------------
// Minimal in-memory BinaryWriter / BinaryReader that satisfy the Hive 2.x
// abstract class contracts and only implement the methods that
// ProteinLogAdapter actually uses.
// ---------------------------------------------------------------------------

// ignore_for_file: must_be_immutable
class _FakeWriter extends BinaryWriter {
  final List<dynamic> values = [];

  @override
  void writeString(
    String value, {
    bool writeByteCount = true,
    Converter<String, List<int>> encoder = BinaryWriter.utf8Encoder,
  }) => values.add(value);

  @override
  void writeDouble(double value) => values.add(value);

  @override
  void writeBool(bool value) => values.add(value);

  @override
  void writeInt(int value) => values.add(value);

  // Remaining stubs — never called by ProteinLogAdapter.
  @override
  void writeByte(int byte) => throw UnimplementedError();
  @override
  void writeWord(int value) => throw UnimplementedError();
  @override
  void writeInt32(int value) => throw UnimplementedError();
  @override
  void writeUint32(int value) => throw UnimplementedError();
  @override
  void writeByteList(List<int> bytes, {bool writeLength = true}) =>
      throw UnimplementedError();
  @override
  void writeIntList(List<int> list, {bool writeLength = true}) =>
      throw UnimplementedError();
  @override
  void writeDoubleList(List<double> list, {bool writeLength = true}) =>
      throw UnimplementedError();
  @override
  void writeBoolList(List<bool> list, {bool writeLength = true}) =>
      throw UnimplementedError();
  @override
  void writeStringList(
    List<String> list, {
    bool writeLength = true,
    Converter<String, List<int>> encoder = BinaryWriter.utf8Encoder,
  }) => throw UnimplementedError();
  @override
  void writeList(List list, {bool writeLength = true}) =>
      throw UnimplementedError();
  @override
  void writeMap(Map map, {bool writeLength = true}) =>
      throw UnimplementedError();
  @override
  // ignore: experimental_member_use
  void writeHiveList(HiveList list, {bool writeLength = true}) =>
      throw UnimplementedError();
  @override
  void write<T>(T value, {bool writeTypeId = true}) =>
      throw UnimplementedError();
}

class _FakeReader extends BinaryReader {
  _FakeReader(this._values);
  final List<dynamic> _values;
  int _cursor = 0;

  dynamic _next() => _values[_cursor++];

  @override
  String readString([
    int? byteCount,
    Converter<List<int>, String> decoder = BinaryReader.utf8Decoder,
  ]) => _next() as String;

  @override
  double readDouble() => (_next() as num).toDouble();

  @override
  bool readBool() => _next() as bool;

  @override
  int readInt() => _next() as int;

  // Getters
  @override
  int get availableBytes => _values.length - _cursor;
  @override
  int get usedBytes => _cursor;

  // Remaining stubs.
  @override
  void skip(int bytes) => throw UnimplementedError();
  @override
  int readByte() => throw UnimplementedError();
  @override
  Uint8List viewBytes(int bytes) => throw UnimplementedError();
  @override
  Uint8List peekBytes(int bytes) => throw UnimplementedError();
  @override
  int readWord() => throw UnimplementedError();
  @override
  int readInt32() => throw UnimplementedError();
  @override
  int readUint32() => throw UnimplementedError();
  @override
  Uint8List readByteList([int? length]) => throw UnimplementedError();
  @override
  List<int> readIntList([int? length]) => throw UnimplementedError();
  @override
  List<double> readDoubleList([int? length]) => throw UnimplementedError();
  @override
  List<bool> readBoolList([int? length]) => throw UnimplementedError();
  @override
  List<String> readStringList([
    int? length,
    Converter<List<int>, String> decoder = BinaryReader.utf8Decoder,
  ]) => throw UnimplementedError();
  @override
  List readList([int? length]) => throw UnimplementedError();
  @override
  Map readMap([int? length]) => throw UnimplementedError();
  @override
  dynamic read([int? typeId]) => throw UnimplementedError();
  @override
  // ignore: experimental_member_use
  HiveList readHiveList([int? length]) => throw UnimplementedError();
}
