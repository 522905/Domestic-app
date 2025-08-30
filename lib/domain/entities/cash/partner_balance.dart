import 'package:equatable/equatable.dart';

class PartnerBalance extends Equatable {
  final String partnerId;
  final String partnerName;
  final List<AccountBalance> balanceData;

  const PartnerBalance({
    required this.partnerId,
    required this.partnerName,
    required this.balanceData,
  });

  factory PartnerBalance.fromJson(Map<String, dynamic> json) {
    return PartnerBalance(
      partnerId: json['partner_id'] ?? '',
      partnerName: json['partner_name'] ?? '',
      balanceData: (json['balance_data'] as List<dynamic>? ?? [])
          .map((item) => AccountBalance.fromJson(item))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [partnerId, partnerName, balanceData];
}

class AccountBalance extends Equatable {
  final String account;
  final double ledgerBalance;
  final double openSalesOrders;
  final double availableBalance;

  const AccountBalance({
    required this.account,
    required this.ledgerBalance,
    required this.openSalesOrders,
    required this.availableBalance,
  });

  factory AccountBalance.fromJson(Map<String, dynamic> json) {
    return AccountBalance(
      account: json['account'] ?? '',
      ledgerBalance: (json['ledger_balance'] as num?)?.toDouble() ?? 0.0,
      openSalesOrders: (json['open_sales_orders'] as num?)?.toDouble() ?? 0.0,
      availableBalance: (json['available_balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [account, ledgerBalance, openSalesOrders, availableBalance];
}