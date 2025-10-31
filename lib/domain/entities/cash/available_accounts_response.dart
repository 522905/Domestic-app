class AvailableAccountsResponse {
  final String role;
  final List<AccountInfo> accounts;

  AvailableAccountsResponse({
    required this.role,
    required this.accounts,
  });

  factory AvailableAccountsResponse.fromJson(Map<String, dynamic> json) {
    return AvailableAccountsResponse(
      role: json['role'] ?? '',
      accounts: (json['accounts'] as List? ?? [])
          .map((acc) => AccountInfo.fromJson(acc))
          .toList(),
    );
  }
}

class AccountInfo {
  final int id;
  final String accountName;  // "Debtors - AG"
  final String accountLabel; // "Load Account"
  final String accountType;  // "receivable"

  AccountInfo({
    required this.id,
    required this.accountName,
    required this.accountLabel,
    required this.accountType,
  });

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      id: json['id'] ?? 0,
      accountName: json['account_name'] ?? '',
      accountLabel: json['account_label'] ?? '',
      accountType: json['account_type'] ?? '',
    );
  }
}