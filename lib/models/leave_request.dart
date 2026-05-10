class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.reason,
    this.managerComment,
  });

  final int id;
  final String leaveType;
  final String startDate;
  final String endDate;
  final String status;
  final String? reason;
  final String? managerComment;

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      leaveType: json['leaveType']?.toString() ?? 'other',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      reason: json['reason']?.toString(),
      managerComment: json['managerComment']?.toString(),
    );
  }
}
