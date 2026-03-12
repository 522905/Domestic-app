import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/dac_order/dac_order_entry.dart';

class DacOrderStorageService {
  static const String _key = 'dac_orders_list';
  static const String _slipCounterKey = 'dac_orders_next_slip_number';

  Future<List<DacOrderEntry>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final entries = list
          .map((e) => DacOrderEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return entries;
    } catch (_) {
      return [];
    }
  }

  Future<int> _getNextSlipNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_slipCounterKey) ?? 1;
    await prefs.setInt(_slipCounterKey, current + 1);
    return current;
  }

  Future<DacOrderEntry> add(DacOrderEntry entry) async {
    final slipNumber = await _getNextSlipNumber();
    final numberedEntry = entry.copyWith(slipNumber: slipNumber);

    final prefs = await SharedPreferences.getInstance();
    final entries = await getAll();
    entries.insert(0, numberedEntry);
    final jsonList = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
    return numberedEntry;
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getAll();
    entries.removeWhere((e) => e.id == id);
    final jsonList = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_slipCounterKey);
  }

  // TODO: Add sync method when API endpoint available
}
