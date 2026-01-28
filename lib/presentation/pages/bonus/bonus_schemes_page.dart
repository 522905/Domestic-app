import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../blocs/bonus_schemes/bonus_schemes_bloc.dart';
import '../../blocs/bonus_schemes/bonus_schemes_event.dart';
import '../../blocs/bonus_schemes/bonus_schemes_state.dart';
import '../../widgets/bonus/bonus_scheme_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';

/// Page to display available bonus schemes
class BonusSchemesPage extends StatelessWidget {
  const BonusSchemesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.bonusSchemesTitle, style: TextStyle(fontSize: 20.sp)),
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 24.sp),
            onPressed: () {
              context.read<BonusSchemesBloc>().add(const RefreshBonusSchemes());
            },
          ),
        ],
      ),
      body: BlocBuilder<BonusSchemesBloc, BonusSchemesState>(
        builder: (context, state) {
          if (state is BonusSchemesLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is BonusSchemesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60.sp, color: Colors.red),
                  SizedBox(height: 16.h),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<BonusSchemesBloc>().add(const LoadBonusSchemes());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is BonusSchemesLoaded) {
            if (state.schemes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 60.sp, color: Colors.grey),
                    SizedBox(height: 16.h),
                    Text(
                      'No bonus schemes available',
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<BonusSchemesBloc>().add(const RefreshBonusSchemes());
              },
              child: ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: state.schemes.length,
                itemBuilder: (context, index) {
                  final scheme = state.schemes[index];
                  return BonusSchemeCard(scheme: scheme);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
