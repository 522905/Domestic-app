import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors_enhanced.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../domain/entities/offline_delivery/offline_delivery_company.dart';

class CompactCompanyPicker extends StatelessWidget {
  final List<OfflineDeliveryCompany> companies;
  final int? selectedId;
  final ValueChanged<int> onSelect;

  const CompactCompanyPicker({
    Key? key,
    required this.companies,
    this.selectedId,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (companies.isEmpty) {
      return const SizedBox.shrink();
    }

    if (companies.length == 1) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: companies.map((company) {
          final index = companies.indexOf(company);
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < companies.length - 1 ? AppSpacing.sm : 0,
              ),
              child: _buildCard(company),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCard(OfflineDeliveryCompany company) {
    final isSelected = selectedId == company.id;
    final shortCode = company.shortCode.isNotEmpty ? company.shortCode : '';
    final name = company.name;

    return GestureDetector(
      onTap: () => onSelect(company.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColorsEnhanced.brandBlue.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColorsEnhanced.brandBlue
                : AppColorsEnhanced.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (shortCode.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColorsEnhanced.brandBlue
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  shortCode,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColorsEnhanced.secondaryText,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Text(
                name,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColorsEnhanced.brandBlue
                      : AppColorsEnhanced.secondaryText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 18,
                color: AppColorsEnhanced.brandBlue,
              ),
          ],
        ),
      ),
    );
  }
}
