import 'package:equatable/equatable.dart';

class BonusFilters extends Equatable {
  final String status;
  final String? itemCode;
  final String? scheme;
  final String sort;
  final int page;
  final int pageSize;

  const BonusFilters({
    this.status = 'all',
    this.itemCode,
    this.scheme,
    this.sort = '-earned_date',
    this.page = 1,
    this.pageSize = 20,
  });

  // Copy with method for updating filters
  BonusFilters copyWith({
    String? status,
    String? itemCode,
    String? scheme,
    String? sort,
    int? page,
    int? pageSize,
  }) {
    return BonusFilters(
      status: status ?? this.status,
      itemCode: itemCode ?? this.itemCode,
      scheme: scheme ?? this.scheme,
      sort: sort ?? this.sort,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  // Reset to default filters
  BonusFilters reset() {
    return const BonusFilters();
  }

  // Convert to query parameters map
  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'status': status,
      'sort': sort,
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    if (itemCode != null) {
      params['item_code'] = itemCode;
    }
    if (scheme != null) {
      params['scheme'] = scheme;
    }

    return params;
  }

  @override
  List<Object?> get props => [status, itemCode, scheme, sort, page, pageSize];
}
