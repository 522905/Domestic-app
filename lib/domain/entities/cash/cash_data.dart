import 'package:equatable/equatable.dart';
import 'partner_balance.dart';

class CashData extends Equatable {
  final double cashInHand;
  final DateTime lastUpdated;
  final int pendingApprovals;
  final double todayDeposits;
  final double todayHandovers;
  final double todayRefunds;
  final List<Map<String, dynamic>> customerOverview;
  final List<PartnerBalance> partners;
  final int totalPartners;
  final List<Map<String, dynamic>> cashierAccounts;

  const CashData({
    required this.cashInHand,
    required this.lastUpdated,
    this.pendingApprovals = 0,
    this.todayDeposits = 0,
    this.todayHandovers = 0,
    this.todayRefunds = 0,
    required this.customerOverview,
    this.partners = const [],
    this.totalPartners = 0,
    this.cashierAccounts = const [], // Add default value
  });

  @override
  List<Object?> get props => [
    cashInHand,
    lastUpdated,
    pendingApprovals,
    todayDeposits,
    todayHandovers,
    todayRefunds,
    customerOverview,
    partners,
    totalPartners,
    cashierAccounts, // Add this
  ];

  CashData copyWith({
    double? cashInHand,
    DateTime? lastUpdated,
    int? pendingApprovals,
    double? todayDeposits,
    double? todayHandovers,
    double? todayRefunds,
    List<Map<String, dynamic>>? customerOverview,
    List<PartnerBalance>? partners,
    int? totalPartners,
    List<Map<String, dynamic>>? cashierAccounts, // Add this
  }) {
    return CashData(
      cashInHand: cashInHand ?? this.cashInHand,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      todayDeposits: todayDeposits ?? this.todayDeposits,
      todayHandovers: todayHandovers ?? this.todayHandovers,
      todayRefunds: todayRefunds ?? this.todayRefunds,
      customerOverview: customerOverview ?? List<Map<String, dynamic>>.from(this.customerOverview),
      partners: partners ?? this.partners,
      totalPartners: totalPartners ?? this.totalPartners,
      cashierAccounts: cashierAccounts ?? List<Map<String, dynamic>>.from(this.cashierAccounts), // Add this
    );
  }
}