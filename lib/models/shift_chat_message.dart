class ShiftChatMessage {
  const ShiftChatMessage({
    required this.id,
    required this.senderUserId,
    required this.messageType,
    this.body,
    this.lat,
    this.lng,
    this.createdAt,
    this.senderName,
    this.pending = false,
  });

  final int id;
  final int senderUserId;
  final String messageType;
  final String? body;
  final double? lat;
  final double? lng;
  final DateTime? createdAt;
  final String? senderName;
  final bool pending;

  bool get isPing => messageType == 'ping';
  bool get isText => messageType == 'text';

  ShiftChatMessage copyWith({
    int? id,
    int? senderUserId,
    String? messageType,
    String? body,
    double? lat,
    double? lng,
    DateTime? createdAt,
    String? senderName,
    bool? pending,
  }) {
    return ShiftChatMessage(
      id: id ?? this.id,
      senderUserId: senderUserId ?? this.senderUserId,
      messageType: messageType ?? this.messageType,
      body: body ?? this.body,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      pending: pending ?? this.pending,
    );
  }

  factory ShiftChatMessage.fromJson(Map<String, dynamic> json) {
    return ShiftChatMessage(
      id: _int(json['id']),
      senderUserId: _int(json['senderUserId']),
      messageType: json['messageType']?.toString() ?? 'text',
      body: json['body']?.toString(),
      lat: _dbl(json['lat']),
      lng: _dbl(json['lng']),
      createdAt: _dt(json['createdAt']),
      senderName: json['senderName']?.toString(),
    );
  }

  static int _int(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
  static double? _dbl(dynamic v) {
    if (v == null) return null;
    return double.tryParse(v.toString());
  }

  static DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());
}
