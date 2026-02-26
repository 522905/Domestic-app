import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../domain/entities/ujjwala/ujjwala_installation.dart';
import '../../widgets/ujjwala/installation_card.dart';
import '../../widgets/ujjwala/installation_search_bar.dart';
import '../../widgets/professional/professional_empty_state.dart';
import '../../widgets/professional/professional_widgets.dart';

class MyUploadsPage extends StatefulWidget {
  const MyUploadsPage({Key? key}) : super(key: key);

  @override
  State<MyUploadsPage> createState() => _MyUploadsPageState();
}

class _MyUploadsPageState extends State<MyUploadsPage> {
  String _searchQuery = '';
  String? _selectedStatus;
  bool _isLoading = true;
  String? _error;
  List<UjjwalaInstallation> _allUploads = [];
  List<UjjwalaInstallation> _filteredUploads = [];

  @override
  void initState() {
    super.initState();
    _loadUploads();
  }

  Future<void> _loadUploads() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiServiceInterface>();
      final response = await apiService.getMyUjjwalaUploads(status: _selectedStatus);
      final uploads = response
          .map((json) => UjjwalaInstallation.fromJson(json))
          .toList();

      setState(() {
        _allUploads = uploads;
        _filteredUploads = uploads;
        _isLoading = false;
      });

      // Apply search filter if query exists
      if (_searchQuery.isNotEmpty) {
        _applySearchFilter();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchPressed(String query) {
    setState(() {
      _searchQuery = query;
    });

    // Apply search filter immediately (no debounce)
    _applySearchFilter();
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredUploads = _allUploads;
      });
      return;
    }

    final query = _searchQuery.toLowerCase().trim();
    setState(() {
      _filteredUploads = _allUploads.where((installation) {
        return installation.consumerName.toLowerCase().contains(query) ||
            installation.applicationNumber.toLowerCase().contains(query) ||
            installation.mobileNumber.toLowerCase().contains(query) ||
            installation.consumerNumber.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _onStatusFilterChanged(String? status) {
    if (_selectedStatus == status) return;

    setState(() {
      _selectedStatus = status;
      _searchQuery = '';
    });

    _loadUploads();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Uploads'),
        backgroundColor: AppColorsEnhanced.brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Status filter chips with better styling
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColorsEnhanced.background,
              border: Border(
                bottom: BorderSide(
                  color: AppColorsEnhanced.border,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Status',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColorsEnhanced.secondaryText,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null),
                      SizedBox(width: AppSpacing.sm),
                      _buildFilterChip('Pending Review', 'PENDING_REVIEW'),
                      SizedBox(width: AppSpacing.sm),
                      _buildFilterChip('Accepted', 'ACCEPTED'),
                      SizedBox(width: AppSpacing.sm),
                      _buildFilterChip('Rejected', 'REJECTED'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          InstallationSearchBar(
            onSearchPressed: _onSearchPressed,
            hintText: 'Search by name, app#, mobile...',
          ),

          // Result count with better styling
          if (_searchQuery.isNotEmpty || _selectedStatus != null)
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColorsEnhanced.brandBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16.r,
                    color: AppColorsEnhanced.brandBlue,
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    _buildResultCountText(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColorsEnhanced.brandBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? statusValue) {
    final isSelected = _selectedStatus == statusValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onStatusFilterChanged(statusValue),
      backgroundColor: Colors.white,
      selectedColor: AppColorsEnhanced.brandBlue,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColorsEnhanced.brandBlue : AppColorsEnhanced.border,
        width: isSelected ? 2 : 1,
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColorsEnhanced.secondaryText,
        fontSize: 13.sp,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      elevation: isSelected ? 2 : 0,
    );
  }

  String _buildResultCountText() {
    final statusText = _selectedStatus != null
        ? ' (${_selectedStatus!.replaceAll('_', ' ').toLowerCase()})'
        : '';
    return 'Showing ${_filteredUploads.length} of ${_allUploads.length} uploads$statusText';
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColorsEnhanced.brandBlue,
        ),
      );
    }

    if (_error != null) {
      return ProfessionalEmptyState(
        icon: Icons.error_outline,
        message: 'Error loading uploads',
        description: _error!,
        actionText: 'Retry',
        onAction: _loadUploads,
      );
    }

    if (_filteredUploads.isEmpty) {
      return ProfessionalEmptyState(
        icon: _searchQuery.isNotEmpty ? Icons.search_off : Icons.cloud_upload_outlined,
        message: _searchQuery.isNotEmpty
            ? 'No uploads found'
            : 'No uploads yet',
        description: _searchQuery.isNotEmpty
            ? 'Try searching with different keywords'
            : _selectedStatus != null
                ? 'No uploads with this status'
                : 'Your submitted installations will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUploads,
      color: AppColorsEnhanced.brandBlue,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: _filteredUploads.length,
        itemBuilder: (context, index) {
          final installation = _filteredUploads[index];
          return InstallationCard(
            installation: installation,
            onTap: () {
              // Navigate to read-only view (can be implemented later)
              // For now, just show a snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Viewing ${installation.consumerName}'),
                  backgroundColor: AppColorsEnhanced.brandBlue,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
