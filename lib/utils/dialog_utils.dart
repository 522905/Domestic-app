// lib/utils/dialog_utils.dart
import 'package:flutter/material.dart';

class DialogUtils {
  static void showAccountSelectionDialog({
    required BuildContext context,
    required bool isLoading,
    required List<Map<String, dynamic>> accounts,
    required Function(String?) onAccountSelected,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        if (isLoading) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        } else if (accounts.isEmpty) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No accounts available'),
            ),
          );
        }

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select paid to account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      return ListTile(
                        title: Text(account['value'] ?? 'Unknown Account'),
                        onTap: () {
                          onAccountSelected(account['value']);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}