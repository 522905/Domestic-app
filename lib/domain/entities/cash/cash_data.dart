import 'package:equatable/equatable.dart';

class CashData extends Equatable {
  final double cashInHand;
  final DateTime lastUpdated;
  final int pendingApprovals;
  final double todayDeposits;
  final double todayHandovers;
  final double todayRefunds;
  final List<Map<String, dynamic>> customerOverview;

  const CashData({
    required this.cashInHand,
    required this.lastUpdated,
    this.pendingApprovals = 0,
    this.todayDeposits = 0,
    this.todayHandovers = 0,
    this.todayRefunds = 0,
    required this.customerOverview, // Initialize this field

  });

  @override
  List<Object?> get props => [
    cashInHand,
    lastUpdated,
    pendingApprovals,
    todayDeposits,
    todayHandovers,
    todayRefunds,
    customerOverview, // Include this field in props for equality checks
  ];

  CashData copyWith({
    double? cashInHand,
    DateTime? lastUpdated,
    int? pendingApprovals,
    double? todayDeposits,
    double? todayHandovers,
    double? todayRefunds,
  }) {
    return CashData(
      cashInHand: cashInHand ?? this.cashInHand,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      todayDeposits: todayDeposits ?? this.todayDeposits,
      todayHandovers: todayHandovers ?? this.todayHandovers,
      todayRefunds: todayRefunds ?? this.todayRefunds,
      customerOverview: List<Map<String, dynamic>>.from(customerOverview), // Ensure immutability
    );
  }
}