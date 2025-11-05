// lib/presentation/pages/sdms/sdms_transaction_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../data/models/sdms/sdms_transaction.dart';
import '../../../utils/error_handler.dart';
import '../../blocs/sdms/transaction/sdms_transaction_bloc.dart';
import '../../blocs/sdms/transaction/sdms_transaction_event.dart';
import '../../blocs/sdms/transaction/sdms_transaction_state.dart';
import '../../widgets/professional_snackbar.dart';
import '../../widgets/sdms/transaction_list_item.dart';
import 'sdms_transaction_detail_page.dart';
import 'sdms_create_transaction_page.dart';

class SDMSTransactionListPage extends StatefulWidget {
  const SDMSTransactionListPage({Key? key}) : super(key: key);

  @override
  State<SDMSTransactionListPage> createState() => _SDMSTransactionListPageState();
}

class _SDMSTransactionListPageState extends State<SDMSTransactionListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<SDMSTransactionBloc>().add(LoadTransactionsEvent());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-refresh when returning from create page
    ModalRoute.of(context)?.addScopedWillPopCallback(() async {
      context.read<SDMSTransactionBloc>().add(RefreshTransactionsEvent());
      return true;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SDMS Transactions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFF0E5CA8),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _navigateToCreate(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => context.read<SDMSTransactionBloc>().add(RefreshTransactionsEvent()),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          Expanded(
            child: BlocConsumer<SDMSTransactionBloc, SDMSTransactionState>(
              listener: (context, state) {
                if (state is SDMSTransactionError) {
                  ErrorHandler.showErrorSnackBar(context, state.message);
                }
              },
              builder: (context, state) {
                if (state is SDMSTransactionLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is SDMSTransactionLoaded) {
                  final filteredTransactions = _getFilteredTransactions(state.transactions);
                  if (filteredTransactions.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildTransactionList(filteredTransactions);
                }

                if (state is SDMSTransactionError) {
                  return _buildErrorState(state.message);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Order ID',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              textInputAction: TextInputAction.search,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            SizedBox(width: 8.w),
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              icon: const Icon(Icons.clear),
              tooltip: 'Clear search',
            ),
          ],
        ],
      ),
    );
  }

  List<SDMSTransaction> _getFilteredTransactions(List<SDMSTransaction> transactions) {
    if (_searchQuery.isEmpty) {
      return transactions;
    }
    return transactions.where((transaction) {
      return transaction.orderId.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Widget _buildDropdown(
      String label,
      String? value,
      List<String> options,
      Function(String?) onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 4.h),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          ),
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: TextStyle(fontSize: 14.sp),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          hint: Text(
            'Select $label',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
      String label,
      DateTime? date,
      Function(DateTime?) onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 4.h),
        InkWell(
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            onChanged(selectedDate);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.date_range,
                  size: 16.sp,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    date != null
                        ? DateFormat('dd/MM/yyyy').format(date)
                        : 'Select $label',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: date != null ? Colors.black : Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList(List<SDMSTransaction> transactions) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<SDMSTransactionBloc>().add(RefreshTransactionsEvent());
      },
      child: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return TransactionListItem(
            transaction: transaction,
            onTap: () => _navigateToDetail(transaction.id),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try adjusting your filters or create a new transaction',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _navigateToCreate,
            icon: const Icon(Icons.add),
            label: const Text('Create Transaction'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E5CA8),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: Colors.red[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'Error loading transactions',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () => context.read<SDMSTransactionBloc>().add(RefreshTransactionsEvent()),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E5CA8),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }


  void _navigateToDetail(String transactionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SDMSTransactionDetailPage(transactionId: transactionId),
      ),
    );
  }

  void _navigateToCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SDMSCreateTransactionPage(),
      ),
    );
  }
}