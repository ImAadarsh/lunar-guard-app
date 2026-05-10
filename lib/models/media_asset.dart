class MediaAsset {
  const MediaAsset({
    required this.id,
    required this.storageKey,
    this.publicUrl,
    this.mime,
    this.sizeBytes,
    this.kind,
  });

  final int id;
  final String storageKey;
  final String? publicUrl;
  final String? mime;
  final int? sizeBytes;
  final String? kind;

  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    return MediaAsset(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      storageKey: json['storageKey']?.toString() ?? '',
      publicUrl: json['publicUrl']?.toString(),
      mime: json['mime']?.toString(),
      sizeBytes: int.tryParse(json['sizeBytes']?.toString() ?? ''),
      kind: json['kind']?.toString(),
    );
  }
}
