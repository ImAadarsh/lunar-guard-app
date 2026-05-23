class DevicePosition {
  const DevicePosition({
    required this.lat,
    required this.lng,
    this.accuracyM,
  });

  final double lat;
  final double lng;
  final double? accuracyM;
}
