import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class DeleteProductPage extends StatelessWidget {
  final RecordModel product;
  final pb = PocketBase('http://127.0.0.1:8090');

  DeleteProductPage({super.key, required this.product});

  Future<void> _deleteProduct(BuildContext context) async {
    try {
      await pb.collection('product').delete(product.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Product deleted successfully")),
      );

      Navigator.pop(context, true); // ส่ง true กลับเพื่อบอกว่าลบแล้ว
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Delete Product"),
      content: Text("Are you sure you want to delete '${product.data["name"]}'?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () => _deleteProduct(context),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text("Delete"),
        ),
      ],
    );
  }
}
