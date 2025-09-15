import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketbase/pocketbase.dart';
import 'products/list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final pb = PocketBase('http://127.0.0.1:8090');
  late final RecordService _service;
  final ScrollController _scrollController = ScrollController();
  final List<RecordModel> _topProducts = [];
  bool _isLoading = false;
  UnsubscribeFunc? _unsubscribeRealtime;

  @override
  void initState() {
    super.initState();
    _service = pb.collection('product');
    _fetchTopProducts();

    // subscribe realtime
    pb.realtime.subscribe("collections.product.records", (msg) {
      try {
        final data = jsonDecode(msg.data);
        final action = data["action"];
        final record = RecordModel.fromJson(data["record"]);

        setState(() {
          if (action == "create") {
            _topProducts.insert(0, record);
          } else if (action == "update") {
            final index = _topProducts.indexWhere((p) => p.id == record.id);
            if (index != -1) {
              _topProducts[index] = record;
            }
          } else if (action == "delete") {
            _topProducts.removeWhere((p) => p.id == record.id);
          }

          // sort ใหม่ล่าสุดอยู่บน
          _topProducts.sort((a, b) =>
              (b.updated ?? b.created).compareTo(a.updated ?? a.created));
        });
      } catch (e) {
        print("Home realtime error: $e");
      }
    }).then((unsubscribe) {
      _unsubscribeRealtime = unsubscribe;
    });
  }

  Future<void> _fetchTopProducts() async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      final result =
          await _service.getList(page: 1, perPage: 10, sort: "-created");
      setState(() {
        _topProducts
          ..clear()
          ..addAll(result.items);
      });
    } catch (e) {
      print("Error fetching top products: $e");
    }
    _isLoading = false;
  }

  @override
  void dispose() {
    _unsubscribeRealtime?.call();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 200,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 200,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('DSSiShop',
            style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ProductListPage()),
              );
            },
            icon: const Icon(Icons.list, color: Colors.white),
            label: Text('All Products',
                style: GoogleFonts.prompt(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : width * 0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Products
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Top Products',
                      style: GoogleFonts.prompt(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios,
                              color: Colors.deepPurple),
                          onPressed: _scrollLeft,
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios,
                              color: Colors.deepPurple),
                          onPressed: _scrollRight,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: isMobile ? 160 : 180,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _topProducts.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final product = _topProducts[index];
                          return Container(
                            width: isMobile ? 120 : 140,
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                    child: Image.network(
                                      product.data['image_url'] ?? '',
                                      height: isMobile ? 70 : 90,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      product.data['name'] ?? '',
                                      style: GoogleFonts.prompt(
                                          fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Text(
                                      '฿${product.data['price']}',
                                      style: GoogleFonts.prompt(
                                          color: Colors.deepPurple,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
