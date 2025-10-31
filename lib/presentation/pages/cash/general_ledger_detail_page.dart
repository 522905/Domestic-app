import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/services/User.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../core/services/service_provider.dart';
import '../../../domain/entities/cash/general_ledger_response.dart';
import '../../../domain/entities/cash/available_accounts_response.dart';

class GeneralLedgerDetailPage extends StatefulWidget {
  final String? accountNames;
  final String? accountLabel;

  const GeneralLedgerDetailPage({
    Key? key,
    this.accountNames,
    this.accountLabel,
  }) : super(key: key);

  @override
  State<GeneralLedgerDetailPage> createState() => _GeneralLedgerDetailPageState();
}

class _GeneralLedgerDetailPageState extends State<GeneralLedgerDetailPage> {
  late ApiServiceInterface _apiService;
  bool _isLoading = true;
  GeneralLedgerResponse? _ledgerData;
  String? _errorMessage;
  bool _isDeliveryBoy = false;

  List<AccountInfo> _availableAccounts = [];

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _toDate = DateTime.now();

  List<String> _selectedAccounts = [];

  final currencyFormat = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 0,
    locale: 'en_IN',
  );

  @override
  void initState() {
    super.initState();
    if (widget.accountNames != null && widget.accountNames!.isNotEmpty) {
      _selectedAccounts = [widget.accountNames!];
    }
    _initializeAndFetch();
  }

  Future<void> _initializeAndFetch() async {
    try {
      _apiService = await ServiceProvider.getApiService();

      final roles = await User().getUserRoles();
      final userRoleList = roles.map((role) => role.role).toList();
      _isDeliveryBoy = userRoleList.contains('Delivery Boy');

      if (_isDeliveryBoy) {
        await _fetchAvailableAccounts();
      }

      await _fetchLedgerData();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAvailableAccounts() async {
    try {
      final response = await _apiService.getAvailableAccounts();
      final accountsResponse = AvailableAccountsResponse.fromJson(response);

      setState(() {
        _availableAccounts = accountsResponse.accounts;
      });
    } catch (e) {
      print('Error fetching available accounts: $e');
    }
  }

  Future<void> _fetchLedgerData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fromDateStr = DateFormat('yyyy-MM-dd').format(_fromDate);
      final toDateStr = DateFormat('yyyy-MM-dd').format(_toDate);

      String? accountNamesParam;
      if (_isDeliveryBoy && _selectedAccounts.isNotEmpty) {
        accountNamesParam = _selectedAccounts.join(',');
      }

      final response = await _apiService.getGeneralLedger(
        fromDate: fromDateStr,
        toDate: toDateStr,
        accountNames: accountNamesParam,
      );

      setState(() {
        _ledgerData = GeneralLedgerResponse.fromJson(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load ledger data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF0E5CA8),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      await _fetchLedgerData();
    }
  }

  void _showAccountSelector() {
    if (_availableAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No accounts available')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Accounts',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _fetchLedgerData();
                        },
                        child: Text('Apply'),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  ..._availableAccounts.map((accountInfo) {
                    final isSelected = _selectedAccounts.contains(accountInfo.accountName);

                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(
                        accountInfo.accountLabel,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      subtitle: Text(
                        accountInfo.accountName,
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                      ),
                      activeColor: Color(0xFF0E5CA8),
                      onChanged: (bool? value) {
                        setModalState(() {
                          if (value == true) {
                            if (!_selectedAccounts.contains(accountInfo.accountName)) {
                              _selectedAccounts.add(accountInfo.accountName);
                            }
                          } else {
                            _selectedAccounts.remove(accountInfo.accountName);
                          }
                        });
                        setState(() {});
                      },
                    );
                  }).toList(),
                  SizedBox(height: 8.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getDisplayNameForAccount(String accountName) {
    final account = _availableAccounts.firstWhere(
          (acc) => acc.accountName == accountName,
      orElse: () => AccountInfo(
        id: 0,
        accountName: accountName,
        accountLabel: accountName.replaceAll(' - AG', ''),
        accountType: '',
      ),
    );
    return account.accountLabel;
  }

  Future<void> _openVoucherPDF(GeneralLedgerTransaction tx) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16.h),
                Text('Loading PDF...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Fetch PDF bytes using API service
      final pdfBytes = await _apiService.getVoucherPDF(
        voucherType: tx.voucherType,
        voucherNo: tx.voucherNo,
      );

      // Close loading dialog
      Navigator.pop(context);

      // Save PDF to temp directory
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${tx.voucherNo}.pdf');
      await file.writeAsBytes(pdfBytes);

      // Open PDF viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerPage(
            pdfPath: file.path,
            title: tx.voucherNo,
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E5CA8),
        title: Text(widget.accountLabel ?? 'Transaction History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchLedgerData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _ledgerData == null
          ? const Center(child: Text('No data available'))
          : RefreshIndicator(
        onRefresh: _fetchLedgerData,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              _errorMessage ?? 'Unknown error',
              style: TextStyle(fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _fetchLedgerData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final data = _ledgerData!;

    final groupedTransactions = <String, List<GeneralLedgerTransaction>>{};
    for (var tx in data.transactions) {
      final dateKey = DateFormat('MMMM d, yyyy').format(tx.date);
      groupedTransactions.putIfAbsent(dateKey, () => []).add(tx);
    }

    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('MMMM d, yyyy').parse(a);
        final dateB = DateFormat('MMMM d, yyyy').parse(b);
        return dateB.compareTo(dateA);
      });

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
          _buildAccountFilterCard(),
          SizedBox(height: 12.h),
        _buildDateFilterCard(),
        SizedBox(height: 12.h),
        _buildSummaryCard(data),
        SizedBox(height: 16.h),
        if (data.transactions.isEmpty)
          _buildEmptyState()
        else
          ...sortedDates.map((dateKey) {
            final transactions = groupedTransactions[dateKey]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Text(
                    dateKey,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                ...transactions.map((tx) => _buildTransactionCard(tx)),
                SizedBox(height: 8.h),
              ],
            );
          }).toList(),
      ],
    );
  }

  Widget _buildAccountFilterCard() {
    final selectedCount = _selectedAccounts.length;
    String displayText;

    if (selectedCount == 0) {
      displayText = 'Select accounts';
    } else if (selectedCount == 1) {
      displayText = _getDisplayNameForAccount(_selectedAccounts[0]);
    } else {
      displayText = '$selectedCount accounts selected';
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: InkWell(
        onTap: _showAccountSelector,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Color(0xFF0E5CA8), size: 20.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accounts',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      displayText,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilterCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: InkWell(
        onTap: _selectDateRange,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              Icon(Icons.date_range, color: Color(0xFF0E5CA8), size: 20.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date Range',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${DateFormat('MMM d, yyyy').format(_fromDate)} - ${DateFormat('MMM d, yyyy').format(_toDate)}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(GeneralLedgerResponse data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            _buildSummaryRow('Opening Balance', data.openingBalance, false),
            _buildSummaryRow('Total Debit', data.totalDebit, false),
            _buildSummaryRow('Total Credit', data.totalCredit, false),
            Divider(height: 24.h, thickness: 1),
            _buildSummaryRow('Closing Balance', data.closingBalance, true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, bool isBold) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              color: Colors.grey[700],
            ),
          ),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(GeneralLedgerTransaction tx) {
    final isDebit = tx.debit > 0;
    final amount = isDebit ? tx.debit : tx.credit;

    // Role-based colors
    // Delivery Boy: Debit=GREEN (money given), Credit=RED (money returned)
    // Others: Debit=RED (money out), Credit=GREEN (money in)
    final Color amountColor;
    final Color badgeColor;
    final String badgeText;

    if (_isDeliveryBoy) {
      if (isDebit) {
        amountColor = Color(0xFFF44336); // RED
        badgeColor = Color(0xFFF44336);
        badgeText = 'DEBIT';
      } else {
        amountColor = Color(0xFF4CAF50); // GREEN
        badgeColor = Color(0xFF4CAF50);
        badgeText = 'CREDIT';
      }
    } else {
      if (isDebit) {
        amountColor = Color(0xFF4CAF50); // GREEN
        badgeColor = Color(0xFF4CAF50);
        badgeText = 'DEBIT';
      } else {
        amountColor = Color(0xFFF44336); // RED
        badgeColor = Color(0xFFF44336);
        badgeText = 'CREDIT';
      }
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: InkWell(
        onTap: () => _openVoucherPDF(tx),
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tx.voucherNo,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show "Against" only for Delivery Boy
                        if (_isDeliveryBoy && tx.against != null) ...[
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 14.sp, color: Colors.grey[600]),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  'From: ${tx.against}',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                        ],
                        // Voucher type
                        Text(
                          '${tx.voucherType}${tx.voucherSubtype != null ? ' - ${tx.voucherSubtype}' : ''}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Remarks' '${tx.remarks != null && tx.remarks!.isNotEmpty ? '' : ' (No remarks)'}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        // Show remarks if available
                        if (tx.remarks != null && tx.remarks!.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Text(
                            tx.remarks!,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(amount),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Balance: ${currencyFormat.format(tx.balance)}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // SizedBox(height: 8.h),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.end,
              //   children: [
              //     Icon(Icons.picture_as_pdf, size: 14.sp, color: Colors.grey[400]),
              //     SizedBox(width: 4.w),
              //     Text(
              //       'Tap to view receipt',
              //       style: TextStyle(
              //         fontSize: 11.sp,
              //         color: Colors.grey[500],
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Try selecting a different date range',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// PDF Viewer Page
class PDFViewerPage extends StatefulWidget {
  final String pdfPath;
  final String title;

  const PDFViewerPage({
    Key? key,
    required this.pdfPath,
    required this.title,
  }) : super(key: key);

  @override
  State<PDFViewerPage> createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E5CA8),
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.pdfPath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: false,
            pageFling: true,
            pageSnap: true,
            onRender: (pages) {
              setState(() {
                pages = pages;
                isReady = true;
              });
            },
            onError: (error) {
              setState(() {
                errorMessage = error.toString();
              });
            },
            onPageError: (page, error) {
              setState(() {
                errorMessage = '$page: ${error.toString()}';
              });
            },
            onPageChanged: (int? page, int? total) {
              setState(() {
                currentPage = page;
              });
            },
          ),
          errorMessage.isEmpty
              ? !isReady
              ? Center(
            child: CircularProgressIndicator(),
          )
              : Container()
              : Center(
            child: Text(errorMessage),
          )
        ],
      ),
    );
  }
}