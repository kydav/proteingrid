import 'package:hive/hive.dart';

class ProteinLog {
  ProteinLog({
    required this.id,
    required this.grams,
    required this.timestamp,
    this.label,
  });

  final String id;
  final double grams;
  final String? label;
  final DateTime timestamp;
}

class ProteinLogAdapter extends TypeAdapter<ProteinLog> {
  @override
  final int typeId = 0;

  @override
  ProteinLog read(BinaryReader reader) {
    final id = reader.readString();
    final grams = reader.readDouble();
    final hasLabel = reader.readBool();
    final label = hasLabel ? reader.readString() : null;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    return ProteinLog(id: id, grams: grams, label: label, timestamp: timestamp);
  }

  @override
  void write(BinaryWriter writer, ProteinLog obj) {
    writer.writeString(obj.id);
    writer.writeDouble(obj.grams);
    writer.writeBool(obj.label != null);
    if (obj.label != null) writer.writeString(obj.label!);
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
  }
}
