import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'create.dart';
import 'update.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final pb = PocketBase('http://127.0.0.1:8090');
  final ScrollController _scrollController = ScrollController();
  final List<RecordModel> _products = [];

  final int _pageSize = 20;
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts(reset: true);

    // ✅ Realtime subscribe
    pb.collection('product').subscribe('*', (e) {
      setState(() {
        if (e.action == 'create' && e.record != null) {
          _products.insert(0, e.record!);
        } else if (e.action == 'update' && e.record != null) {
          final index = _products.indexWhere((p) => p.id == e.record!.id);
          if (index != -1) _products[index] = e.record!;
        } else if (e.action == 'delete' && e.record != null) {
          _products.removeWhere((p) => p.id == e.record!.id);
        }
      });
    });

    _scrollController.addListener(_onScroll);
  }

  Future<void> _fetchProducts({bool reset = false}) async {
    if (_isLoading) return;
    _isLoading = true;

    if (reset) {
      _products.clear();
      _page = 1;
      _hasMore = true;
    }

    try {
      final result = await pb.collection('product').getList(
            page: _page,
            perPage: _pageSize,
            sort: "-created",
          );

      setState(() {
        _products.addAll(result.items);
        if (result.items.length < _pageSize) _hasMore = false;
      });
    } catch (e) {
      print("Error fetching products: $e");
    }

    _isLoading = false;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_isLoading) {
      _page++;
      _fetchProducts();
    }
  }

  Future<void> _deleteProduct(RecordModel product) async {
    try {
      await pb.collection('product').delete(product.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Deleted: ${product.data['name']}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting: $e")),
      );
    }
  }

  @override
  void dispose() {
    pb.collection('product').unsubscribe('*');
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final created = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateProductPage()),
              );
              if (created != null) {
                _fetchProducts(reset: true);
              }
            },
          )
        ],
      ),
      body: _products.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              controller: _scrollController,
              itemCount: _products.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _products.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final product = _products[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Image.network(
                      product.data['image_url'] ?? '',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                    title: Text(product.data['name'] ?? ''),
                    subtitle: Text('฿${(product.data['price'] ?? 0).toString()}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UpdateProductPage(product: product),
                              ),
                            );
                            if (updated != null) {
                              _fetchProducts(reset: true);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteProduct(product);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
