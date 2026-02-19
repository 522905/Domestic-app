import 'package:equatable/equatable.dart';
import '../../../domain/entities/credit_extension/credit_extension.dart';

abstract class CreditExtensionListState extends Equatable {
  const CreditExtensionListState();

  @override
  List<Object?> get props => [];
}

class CreditExtensionListInitial extends CreditExtensionListState {}

class CreditExtensionListLoading extends CreditExtensionListState {}

class CreditExtensionListLoaded extends CreditExtensionListState {
  final List<CreditExtension> extensions;
  final String? currentStatus;
  final bool hasMore;
  final int currentPage;

  const CreditExtensionListLoaded({
    required this.extensions,
    this.currentStatus,
    this.hasMore = false,
    this.currentPage = 1,
  });

  CreditExtensionListLoaded copyWith({
    List<CreditExtension>? extensions,
    String? currentStatus,
    bool? hasMore,
    int? currentPage,
  }) {
    return CreditExtensionListLoaded(
      extensions: extensions ?? this.extensions,
      currentStatus: currentStatus ?? this.currentStatus,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [extensions, currentStatus, hasMore, currentPage];
}

class CreditExtensionListLoadingMore extends CreditExtensionListState {
  final List<CreditExtension> currentExtensions;
  final String? currentStatus;
  final int currentPage;

  const CreditExtensionListLoadingMore({
    required this.currentExtensions,
    this.currentStatus,
    required this.currentPage,
  });

  @override
  List<Object?> get props => [currentExtensions, currentStatus, currentPage];
}

class CreditExtensionListError extends CreditExtensionListState {
  final String message;

  const CreditExtensionListError(this.message);

  @override
  List<Object?> get props => [message];
}
