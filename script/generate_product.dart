import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import 'package:faker/faker.dart';

Future<void> main() async {
  final pb = PocketBase('http://127.0.0.1:8090');
  final faker = Faker();
  final random = Random();

  try {
    // Authenticate as admin
    await pb.admins
        .authWithPassword('methasit.ka.65@ubu.ac.th', 'Methasit66-99');
    print('Connected as admin');
  } catch (e) {
    print('Failed to authenticate admin: $e');
    return;
  }

  for (int i = 0; i < 100; i++) {
    final name = faker.food.dish(); // ชื่ออาหารแบบสุ่ม
    final price = (random.nextDouble() * 500 + 50).toStringAsFixed(2);

    // เรียก API จาก Foodish
    String imageUrl = '';
    try {
      final res = await http.get(Uri.parse('https://foodish-api.com/api/'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        imageUrl = data['image'];
      } else {
        imageUrl = 'https://via.placeholder.com/200'; // fallback
      }
    } catch (e) {
      imageUrl = 'https://via.placeholder.com/200'; // fallback
    }

    try {
      final record = await pb.collection('product').create(body: {
        'name': name,
        'price': double.parse(price),
        'image_url': imageUrl,
      });
      print('Created: ${record.id} - $name');
    } catch (e, st) {
      print('Error creating $name: $e');
      print(st);
    }
  }

  print('Finished generating 100 food products into PocketBase.');
}
