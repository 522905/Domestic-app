import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/defect_inspection/master_data.dart';
import '../models/defect_inspection/purchase_invoice.dart';
import '../models/defect_inspection/dir_item.dart';
import '../models/defect_inspection/defect_inspection_report.dart';
import '../network/api_client.dart';

/// Service for Defect Inspection management
class DefectService {
  final ApiClient apiClient;

  DefectService(this.apiClient);

  /// Get master data for defect inspection
  /// [warehouse] - Required warehouse name
  /// [purchaseInvoice] - Optional PI filter
  Future<MasterDataResponse> getMasterData({
    required String warehouse,
    String? purchaseInvoice,
  }) async {
    try {
      final queryParams = {
        'warehouse': warehouse,
        if (purchaseInvoice != null && purchaseInvoice.isNotEmpty)
          'purchase_invoice': purchaseInvoice,
      };

      final response = await apiClient.get(
        apiClient.endpoints.defectMasterData,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        if (response.data['success'] == true) {
          return MasterDataResponse.fromJson(response.data['data']);
        } else {
          throw Exception(response.data['error'] ?? 'Failed to fetch master data');
        }
      } else {
        throw Exception('Failed to fetch master data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('DefectService.getMasterData error: $e');
      rethrow;
    }
  }

  /// Get purchase invoices for warehouse
  /// [warehouse] - Required warehouse name
  /// [limit] - Max records (default 50)
  Future<List<PurchaseInvoice>> getPurchaseInvoices({
    required String warehouse,
    int limit = 50,
  }) async {
    try {
      final queryParams = {
        'warehouse': warehouse,
        'limit': limit,
      };

      final response = await apiClient.get(
        apiClient.endpoints.defectPurchaseInvoices,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        if (response.data['success'] == true) {
          return (response.data['data'] as List<dynamic>)
              .map((json) => PurchaseInvoice.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(response.data['error'] ?? 'Failed to fetch purchase invoices');
        }
      } else {
        throw Exception('Failed to fetch purchase invoices: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('DefectService.getPurchaseInvoices error: $e');
      rethrow;
    }
  }

  /// Create and submit Defect Inspection Report
  /// Returns the DIR name (e.g., "DIR-REP-2025-00042")
  Future<String> createDIR(CreateDIRRequest request) async {
    try {
      final response = await apiClient.post(
        apiClient.endpoints.defectInspectionReports,
        data: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (response.data['success'] == true) {
          return response.data['data']['name'] as String;
        } else {
          throw DIRValidationException(
            message: response.data['error'] ?? 'Failed to create inspection report',
            details: response.data['details'],
          );
        }
      } else {
        throw Exception('Failed to create inspection report: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('DefectService.createDIR DioException: ${e.message}');

      if (e.response?.statusCode == 400) {
        // Validation error - throw custom exception
        throw DIRValidationException(
          message: e.response?.data['error']?.toString() ?? 'Validation failed',
          details: e.response?.data['details'],
        );
      }
      rethrow;
    } catch (e) {
      debugPrint('DefectService.createDIR error: $e');
      rethrow;
    }
  }

  /// Get list of inspection reports
  /// [warehouse] - Optional warehouse filter
  /// [limit] - Max records (default 50)
  Future<List<InspectionReport>> getInspectionReports({
    String? warehouse,
    int limit = 50,
  }) async {
    try {
      final queryParams = {
        if (warehouse != null && warehouse.isNotEmpty) 'warehouse': warehouse,
        'limit': limit,
      };

      final response = await apiClient.get(
        apiClient.endpoints.defectInspectionReportsList,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        if (response.data['success'] == true) {
          return (response.data['data'] as List<dynamic>)
              .map((json) => InspectionReport.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(response.data['error'] ?? 'Failed to fetch inspection reports');
        }
      } else {
        throw Exception('Failed to fetch inspection reports: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('DefectService.getInspectionReports error: $e');
      rethrow;
    }
  }

  /// Get detailed inspection report
  /// [name] - DIR name (e.g., "DIR-REP-2025-00042")
  Future<InspectionReportDetail> getInspectionReportDetail({
    required String name,
  }) async {
    try {
      final response = await apiClient.get(
        apiClient.endpoints.defectInspectionReportDetail(name),
      );

      if (response.statusCode == 200) {
        if (response.data['success'] == true) {
          return InspectionReportDetail.fromJson(response.data['data']);
        } else {
          throw Exception(response.data['error'] ?? 'Failed to fetch inspection report details');
        }
      } else if (response.statusCode == 404) {
        throw NotFoundException('Inspection report not found');
      } else {
        throw Exception('Failed to fetch inspection report details: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('DefectService.getInspectionReportDetail error: $e');
      rethrow;
    }
  }
}

/// Custom exception for DIR validation errors
class DIRValidationException implements Exception {
  final String message;
  final dynamic details;

  DIRValidationException({
    required this.message,
    this.details,
  });

  @override
  String toString() => message;

  /// Get formatted error message with details
  String getFullMessage() {
    if (details != null) {
      return '$message\n\nDetails:\n${details.toString()}';
    }
    return message;
  }
}

/// Custom exception for not found errors
class NotFoundException implements Exception {
  final String message;

  NotFoundException(this.message);

  @override
  String toString() => message;
}
