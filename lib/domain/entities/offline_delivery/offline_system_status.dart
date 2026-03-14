import 'package:equatable/equatable.dart';

class OfflineSystemStatus extends Equatable {
  final String mode;
  final String modeLabel;
  final bool sdmsActive;
  final bool bookingChannelsActive;
  final bool otpChannelsActive;
  final bool requireDacCode;
  final bool allowBookingCreation;
  final String? notes;
  final DateTime? updatedAt;

  const OfflineSystemStatus({
    required this.mode,
    required this.modeLabel,
    required this.sdmsActive,
    required this.bookingChannelsActive,
    required this.otpChannelsActive,
    required this.requireDacCode,
    required this.allowBookingCreation,
    this.notes,
    this.updatedAt,
  });

  bool get isManual => mode == 'MANUAL';
  bool get isAssisted => mode == 'ASSISTED';
  bool get isVerified => mode == 'VERIFIED';

  factory OfflineSystemStatus.fromJson(Map<String, dynamic> json) {
    return OfflineSystemStatus(
      mode: json['mode'] ?? 'MANUAL',
      modeLabel: json['mode_label'] ?? '',
      sdmsActive: json['sdms_active'] ?? false,
      bookingChannelsActive: json['booking_channels_active'] ?? false,
      otpChannelsActive: json['otp_channels_active'] ?? false,
      requireDacCode: json['require_dac_code'] ?? false,
      allowBookingCreation: json['allow_booking_creation'] ?? false,
      notes: json['notes'],
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
    mode, modeLabel, sdmsActive, bookingChannelsActive,
    otpChannelsActive, requireDacCode, allowBookingCreation,
    notes, updatedAt,
  ];
}
