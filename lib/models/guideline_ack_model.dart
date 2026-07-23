class GuidelineAckStatus {
  final bool general;
  final bool freelancer;
  final bool client;

  const GuidelineAckStatus({
    this.general = false,
    this.freelancer = false,
    this.client = false,
  });

  factory GuidelineAckStatus.fromJson(Map<String, dynamic> json) =>
      GuidelineAckStatus(
        general: json['general'] as bool? ?? false,
        freelancer: json['freelancer'] as bool? ?? false,
        client: json['client'] as bool? ?? false,
      );

  GuidelineAckStatus copyWith({
    bool? general,
    bool? freelancer,
    bool? client,
  }) => GuidelineAckStatus(
    general: general ?? this.general,
    freelancer: freelancer ?? this.freelancer,
    client: client ?? this.client,
  );
}
