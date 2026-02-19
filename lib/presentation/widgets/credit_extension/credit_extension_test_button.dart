import 'package:flutter/material.dart';
import '../../pages/credit_extension/extension_list_page.dart';

/// Simple test button to navigate to Credit Extension features
/// Add this to your home page, profile page, or drawer to test the feature
class CreditExtensionTestButton extends StatelessWidget {
  const CreditExtensionTestButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.card_giftcard,
            color: Colors.blue.shade700,
          ),
        ),
        title: const Text(
          'Credit Extensions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Request stock when quota is low'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ExtensionListPage(),
            ),
          );
        },
      ),
    );
  }
}
