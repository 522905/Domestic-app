import 'package:equatable/equatable.dart';

class BonusScheme extends Equatable {
  final int id;
  final String name;
  final String description;
  final bool isActive;
  final BonusSchemeConfig config;
  final BonusSchemeConfig? partnerOverrides;

  const BonusScheme({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.config,
    this.partnerOverrides,
  });

  // Computed properties that prefer partner overrides
  double get targetPostingRatio =>
      partnerOverrides?.targetPostingRatio ?? config.targetPostingRatio;

  double get bonusPercentage =>
      partnerOverrides?.bonusPercentage ?? config.bonusPercentage;

  int get validityDays =>
      partnerOverrides?.validityDays ?? config.validityDays;

  bool get hasPartnerOverrides => partnerOverrides != null;

  factory BonusScheme.fromJson(Map<String, dynamic> json) {
    return BonusScheme(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isActive: json['is_active'] ?? false,
      config: BonusSchemeConfig.fromJson(json['config'] ?? {}),
      partnerOverrides: json['partner_overrides'] != null
          ? BonusSchemeConfig.fromJson(json['partner_overrides'])
          : null,
    );
  }

  @override
  List<Object?> get props => [id, name, description, isActive, config, partnerOverrides];
}

class BonusSchemeConfig extends Equatable {
  final double targetPostingRatio;
  final double bonusPercentage;
  final int validityDays;

  const BonusSchemeConfig({
    required this.targetPostingRatio,
    required this.bonusPercentage,
    required this.validityDays,
  });

  factory BonusSchemeConfig.fromJson(Map<String, dynamic> json) {
    return BonusSchemeConfig(
      targetPostingRatio: (json['target_posting_ratio'] ?? 0).toDouble(),
      bonusPercentage: (json['bonus_percentage'] ?? 0).toDouble(),
      validityDays: json['validity_days'] ?? 0,
    );
  }

  @override
  List<Object> get props => [targetPostingRatio, bonusPercentage, validityDays];
}
