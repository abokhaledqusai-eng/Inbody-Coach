import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../../../core/app_colors.dart';
import '../../../core/services/api_service.dart';

class StoreController extends GetxController {
  final isLoading = false.obs;
  final isSubmittingOrder = false.obs;
  final isLoadingOrders = false.obs;
  final products = <Map<String, dynamic>>[].obs;
  final orders = <Map<String, dynamic>>[].obs;
  final cartItems = <Map<String, dynamic>>[].obs;
  final selectedCategory = 'الكل'.obs;
  final searchQuery = ''.obs;
  final searchTextController = TextEditingController();
  final categories = <String>['الكل'].obs;
  final checkoutPhone = ''.obs;
  final checkoutAddress = ''.obs;

  String _normalizeCategory(String category) {
    return category.trim().toLowerCase();
  }

  String _normalizeSearchTerm(String value) {
    return value.trim().toLowerCase();
  }

  String _productSearchText(Map<String, dynamic> product) {
    final fields = [
      product['name'],
      product['category'],
      product['description'],
      product['volume'],
      if (product['sizes'] is List) ...(product['sizes'] as List),
    ];
    return fields
        .map((field) => _normalizeSearchTerm(field?.toString() ?? ''))
        .where((field) => field.isNotEmpty)
        .join(' ');
  }

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
    fetchProducts();
    loadCheckoutProfile();
  }

  Future<void> fetchCategories() async {
    try {
      final response = await ApiService.get('/store/categories');
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final parsed = response.data as Map<String, dynamic>;
        final List<dynamic> rawList = parsed['data'] ?? [];
        final list = rawList
            .map((e) => e.toString().trim())
            .where((e) => e.toString().trim().isNotEmpty)
            .toList()
          ..sort();
        categories.value = ['الكل', ...list];
        if (!categories.contains(selectedCategory.value)) {
          selectedCategory.value = 'الكل';
        }
      }
    } catch (_) {}
  }

  Future<void> fetchProducts() async {
    isLoading.value = true;
    try {
      final response = await ApiService.get('/store/products');
      if (response.statusCode == 200) {
        final raw = response.data;
        List<dynamic> data;

        // نتأكد من شكل البيانات سواء كانت Map أو List مباشرة
        if (raw is Map<String, dynamic>) {
          data = (raw['data'] as List?) ?? [];
        } else if (raw is List) {
          data = raw;
        } else {
          throw Exception('شكل استجابة غير متوقع: ${raw.runtimeType}');
        }

        products.value = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        if (categories.length <= 1) {
          final categoryMap = <String, String>{};
          for (final product in products) {
            final displayCategory =
                (product['category']?.toString() ?? '').trim();
            if (displayCategory.isEmpty) {
              continue;
            }
            categoryMap.putIfAbsent(
                _normalizeCategory(displayCategory), () => displayCategory);
          }
          final dynamicCategories = categoryMap.values.toList()..sort();
          categories.value = ['الكل', ...dynamicCategories];
        }
      } else {
        throw Exception('رمز استجابة غير متوقع: ${response.statusCode}');
      }
    } catch (e) {
      products.clear();
      Get.snackbar(
        'خطأ',
        'تعذر جلب منتجات المتجر: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCheckoutProfile() async {
    try {
      final response = await ApiService.get('/me');
      if (response.statusCode == 200) {
        final user = response.data['data'] as Map<String, dynamic>?;
        final profile = user?['profile'] as Map<String, dynamic>?;
        checkoutPhone.value = (user?['phone']?.toString() ?? '').trim();
        checkoutAddress.value =
            (profile?['delivery_address']?.toString() ?? '').trim();
      }
    } catch (_) {}
  }

  void setCategory(String category) {
    selectedCategory.value = category.trim();
  }

  void setSearchQuery(String query) {
    searchQuery.value = query.trim();
  }

  void clearSearchQuery() {
    searchTextController.clear();
    searchQuery.value = '';
  }

  List<Map<String, dynamic>> get filteredProducts {
    final normalizedQuery = _normalizeSearchTerm(searchQuery.value);
    return products.where((p) {
      final productCategory = p['category']?.toString() ?? '';
      final matchesCategory = selectedCategory.value == 'الكل' ||
          _normalizeCategory(productCategory) ==
              _normalizeCategory(selectedCategory.value);
      if (!matchesCategory) {
        return false;
      }
      if (normalizedQuery.isEmpty) {
        return true;
      }
      return _productSearchText(p).contains(normalizedQuery);
    }).toList();
  }

  void addToCart(Map<String, dynamic> product,
      {String? selectedSize, int quantity = 1}) {
    final productId = product['id'];
    final key = '${productId}_${selectedSize ?? ''}';
    final index = cartItems.indexWhere((item) => item['key'] == key);
    final unitPrice = _effectivePriceForSelection(product, selectedSize: selectedSize);
    final available =
        _effectiveStockForSelection(product, selectedSize: selectedSize);
    final currentQty = index >= 0 ? (cartItems[index]['quantity'] as int) : 0;
    final remaining = available - currentQty;
    if (remaining <= 0) {
      Get.snackbar('المخزون', 'الكمية المطلوبة غير متوفرة',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    final addQty = quantity > remaining ? remaining : quantity;
    if (index >= 0) {
      final updated = Map<String, dynamic>.from(cartItems[index]);
      updated['quantity'] = (updated['quantity'] as int) + addQty;
      cartItems[index] = updated;
    } else {
      cartItems.add({
        'key': key,
        'product_id': productId,
        'name': product['name'],
        'price_syp': unitPrice,
        'image_url': product['image_url'],
        'selected_size': selectedSize,
        'quantity': addQty,
      });
    }
  }

  void increaseCartQuantity(int index) {
    final current = cartItems[index];
    final productId = current['product_id'];
    Map<String, dynamic>? product;
    try {
      product = products.firstWhere((p) => p['id'] == productId);
    } catch (_) {
      product = null;
    }
    if (product == null) {
      final updated = Map<String, dynamic>.from(current);
      updated['quantity'] = (updated['quantity'] as int) + 1;
      cartItems[index] = updated;
      return;
    }
    final selectedSize = current['selected_size']?.toString();
    final available =
        _effectiveStockForSelection(product, selectedSize: selectedSize);
    final currentQty = current['quantity'] as int;
    if (currentQty >= available) {
      Get.snackbar(
          'المخزون', 'لا تتوفر كمية إضافية من هذا المنتج',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    final updated = Map<String, dynamic>.from(current);
    updated['quantity'] = currentQty + 1;
    cartItems[index] = updated;
  }

  void decreaseCartQuantity(int index) {
    final current = cartItems[index];
    final quantity = current['quantity'] as int;
    if (quantity <= 1) {
      cartItems.removeAt(index);
      return;
    }
    final updated = Map<String, dynamic>.from(current);
    updated['quantity'] = quantity - 1;
    cartItems[index] = updated;
  }

  double get cartTotal {
    return cartItems.fold<double>(0, (sum, item) {
      final price = (item['price_syp'] as num).toDouble();
      final quantity = item['quantity'] as int;
      return sum + (price * quantity);
    });
  }

  Future<bool> submitOrder({
    required String contactPhone,
    required String deliveryAddress,
    String? customerNote,
  }) async {
    if (cartItems.isEmpty) {
      Get.snackbar('السلة', 'السلة فارغة حالياً',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return false;
    }

    isSubmittingOrder.value = true;
    try {
      final payload = {
        'contact_phone': contactPhone.trim(),
        'delivery_address': deliveryAddress.trim(),
        if (customerNote != null && customerNote.trim().isNotEmpty)
          'customer_note': customerNote.trim(),
        'items': cartItems.map((item) {
          return {
            'product_id': item['product_id'],
            'quantity': item['quantity'],
            if (item['selected_size'] != null)
              'selected_size': item['selected_size'],
          };
        }).toList(),
      };

      final response = await ApiService.post('/store/orders', payload);
      if (response.statusCode == 201) {
        checkoutPhone.value = contactPhone.trim();
        checkoutAddress.value = deliveryAddress.trim();
        cartItems.clear();
        await fetchOrders();
        return true;
      }
    } catch (e) {
      final message = e.toString().contains('401')
          ? 'يرجى تسجيل الدخول لإتمام الشراء'
          : 'تعذر اتمام الطلب حالياً';
      Get.snackbar('خطأ', message,
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSubmittingOrder.value = false;
    }
    return false;
  }

  Future<void> fetchOrders() async {
    isLoadingOrders.value = true;
    try {
      final response = await ApiService.get('/store/orders');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        orders.value = data.whereType<Map<String, dynamic>>().toList();
      }
    } catch (_) {
      orders.clear();
      Get.snackbar('الفواتير', 'تعذر جلب الفواتير، تأكد من تسجيل الدخول',
          backgroundColor: Colors.orange, colorText: Colors.white);
    } finally {
      isLoadingOrders.value = false;
    }
  }

  @override
  void onClose() {
    searchTextController.dispose();
    super.onClose();
  }
}

class StoreView extends StatelessWidget {
  StoreView({super.key});

  final StoreController controller = Get.put(StoreController());

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchAndFilter(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                final displayProducts = controller.filteredProducts;
                if (displayProducts.isEmpty) {
                  return _buildEmptyState(context);
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    await controller.fetchCategories();
                    await controller.fetchProducts();
                  },
                  child: GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: displayProducts.length,
                    itemBuilder: (context, index) {
                      final product = displayProducts[index];
                      return _ProductCard(
                        product: product,
                        onTap: () {
                          Get.to(() => ProductDetailsView(
                              controller: controller, product: product));
                        },
                        onAdd: () => _openAddToCartSheet(product),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.shopping_bag_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'المتجر المميز',
              style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87),
            ),
          ),
          _buildHeaderIcon(Icons.refresh_rounded, () {
            controller.fetchCategories();
            controller.fetchProducts();
          }),
          const SizedBox(width: 8),
          _buildHeaderIcon(Icons.receipt_long_rounded, () {
            Get.to(() => InvoicesView(controller: controller));
          }),
          const SizedBox(width: 8),
          Obx(() => Stack(
            children: [
              _buildHeaderIcon(Icons.shopping_cart_rounded, () {
                Get.to(() => CartView(controller: controller));
              }),
              if (controller.cartItems.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                      '${controller.cartItems.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Search Bar (70%)
          Expanded(
            flex: 7,
            child: Obx(() => TextField(
              controller: controller.searchTextController,
              onChanged: controller.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'ابحث...',
                hintStyle: GoogleFonts.cairo(fontSize: 13, color: Colors.grey),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                suffixIcon: controller.searchQuery.value.isEmpty
                    ? null
                    : IconButton(
                        onPressed: controller.clearSearchQuery, 
                        icon: const Icon(Icons.close, size: 18),
                        padding: EdgeInsets.zero,
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1),
                ),
              ),
            )),
          ),
          const SizedBox(width: 8),
          // Category Dropdown (30%)
          Expanded(
            flex: 3,
            child: Obx(() => Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.selectedCategory.value,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 18),
                  style: GoogleFonts.cairo(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
                  onChanged: (val) { if (val != null) controller.setCategory(val); },
                  items: controller.categories.map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(cat, overflow: TextOverflow.ellipsis),
                  )).toList(),
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyState(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await controller.fetchCategories();
        await controller.fetchProducts();
      },
      child: ListView(
        children: [
          SizedBox(height: Get.height * 0.2),
          const Icon(Icons.search_off_rounded, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          Center(
            child: Text(
              controller.searchQuery.value.isEmpty ? 'لا يوجد منتجات حالياً' : 'لا توجد نتائج مطابقة للبحث',
              style: GoogleFonts.cairo(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }


  void _openAddToCartSheet(Map<String, dynamic> product) {
    final sizeStocks = _extractSizeStocks(product);
    final sizeOptions = _resolveSizeOptions(product, sizeStocks);
    final stock = _effectiveProductStock(product);

    if (stock <= 0) {
      Get.snackbar('المخزون', 'الكمية منتهية',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (sizeOptions.isEmpty) {
      final qty = 1.obs;
      Get.bottomSheet(
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('الكمية',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Obx(() => Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (qty.value > 1) qty.value -= 1;
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(qty.value.toString()),
                        IconButton(
                          onPressed: () {
                            if (qty.value < stock) {
                              qty.value += 1;
                            } else {
                              Get.snackbar('المخزون', 'تخطيت الكمية المتاحة',
                                  backgroundColor: Colors.orange,
                                  colorText: Colors.white);
                            }
                          },
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    )),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (stock <= 0) {
                        Get.snackbar('المخزون', 'الكمية منتهية',
                            backgroundColor: Colors.red,
                            colorText: Colors.white);
                        return;
                      }
                      controller.addToCart(product, quantity: qty.value);
                      Get.back();
                      Get.snackbar('السلة', 'تمت إضافة المنتج إلى السلة',
                          backgroundColor: AppColors.success,
                          colorText: Colors.white);
                    },
                    child: const Text('إضافة للسلة'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    final formatter = NumberFormat('#,##0.00');
    final selectedSize = RxnString();
    final qty = 1.obs;
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('اختر المقاس',
                  style: GoogleFonts.cairo(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Obx(() => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sizeOptions.map((size) {
                      final isSelected = selectedSize.value == size;
                      final sizePrice = _effectivePriceForSelection(product, selectedSize: size);
                      return ChoiceChip(
                        label: Text('$size - ${formatter.format(sizePrice)} ل.س'),
                        selected: isSelected,
                        onSelected: (_) => selectedSize.value = size,
                      );
                    }).toList(),
                  )),
              const SizedBox(height: 12),
              Obx(() {
                final sel = selectedSize.value;
                final available = sel == null
                    ? 0
                    : _effectiveStockForSelection(product, selectedSize: sel);
                final selectedPrice = sel == null
                    ? null
                    : _effectivePriceForSelection(product, selectedSize: sel);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectedPrice != null)
                      Text(
                        'السعر للمقاس المحدد: ${formatter.format(selectedPrice)} ل.س',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (selectedPrice != null) const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('الكمية',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: sel == null
                              ? null
                              : () {
                                  if (qty.value > 1) qty.value -= 1;
                                },
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(qty.value.toString()),
                        IconButton(
                          onPressed: sel == null
                              ? null
                              : () {
                                  if (qty.value < available) {
                                    qty.value += 1;
                                  } else {
                                    Get.snackbar(
                                        'المخزون', 'تخطيت الكمية المتاحة',
                                        backgroundColor: Colors.orange,
                                        colorText: Colors.white);
                                  }
                                },
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (selectedSize.value == null) {
                      Get.snackbar('المقاس', 'يرجى اختيار المقاس',
                          backgroundColor: Colors.orange,
                          colorText: Colors.white);
                      return;
                    }
                    final selectedStock = _effectiveStockForSelection(
                      product,
                      selectedSize: selectedSize.value,
                    );
                    if (selectedStock <= 0) {
                      Get.snackbar('المخزون', 'الكمية منتهية لهذا المقاس',
                          backgroundColor: Colors.red, colorText: Colors.white);
                      return;
                    }
                    if (qty.value > selectedStock) {
                      Get.snackbar('المخزون', 'الكمية المطلوبة غير متوفرة',
                          backgroundColor: Colors.red, colorText: Colors.white);
                      return;
                    }
                    controller.addToCart(product,
                        selectedSize: selectedSize.value, quantity: qty.value);
                    Get.back();
                    Get.snackbar('السلة', 'تمت إضافة المنتج إلى السلة',
                        backgroundColor: AppColors.success,
                        colorText: Colors.white);
                  },
                  child: const Text('إضافة للسلة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Map<String, int> _extractSizeStocks(Map<String, dynamic> product) {
  final sizeStocksRaw = product['size_stocks'];
  final sizeStocks = <String, int>{};
  if (sizeStocksRaw is Map) {
    for (final entry in sizeStocksRaw.entries) {
      final key = entry.key.toString().trim();
      if (key.isEmpty) {
        continue;
      }
      sizeStocks[key] = _toNonNegativeInt(entry.value);
    }
  } else if (sizeStocksRaw is List) {
    for (final item in sizeStocksRaw) {
      if (item is! Map) {
        continue;
      }
      final sizeKey = (item['size_key'] ??
              item['size'] ??
              item['label'] ??
              item['size_label'] ??
              '')
          .toString()
          .trim();
      if (sizeKey.isEmpty) {
        continue;
      }
      sizeStocks[sizeKey] = _toNonNegativeInt(item['quantity']);
    }
  }
  return sizeStocks;
}

Map<String, double> _extractSizePrices(Map<String, dynamic> product) {
  final raw = product['size_prices'];
  final prices = <String, double>{};

  if (raw is Map) {
    for (final entry in raw.entries) {
      final key = entry.key.toString().trim();
      if (key.isEmpty) continue;
      final value = entry.value;
      final parsed = value is num ? value.toDouble() : double.tryParse(value.toString());
      if (parsed != null && parsed >= 0) {
        prices[key] = parsed;
      }
    }
  }

  if (prices.isNotEmpty) {
    return prices;
  }

  final sizeStocksRaw = product['size_stocks'];
  if (sizeStocksRaw is List) {
    for (final item in sizeStocksRaw) {
      if (item is! Map) {
        continue;
      }
      final sizeKey = (item['size_key'] ??
              item['size'] ??
              item['label'] ??
              item['size_label'] ??
              '')
          .toString()
          .trim();
      if (sizeKey.isEmpty) {
        continue;
      }
      final parsedPrice = item['price_syp'] is num
          ? (item['price_syp'] as num).toDouble()
          : double.tryParse(item['price_syp']?.toString() ?? '');
      if (parsedPrice != null && parsedPrice >= 0) {
        prices[sizeKey] = parsedPrice;
      }
    }
  }

  return prices;
}

List<String> _extractSizes(Map<String, dynamic> product) {
  if (product['sizes'] is List) {
    return List<String>.from(product['sizes']
        .map((e) => e.toString().trim())
        .where((e) => e.toString().trim().isNotEmpty));
  }
  return <String>[];
}

int _toNonNegativeInt(dynamic value) {
  if (value is num) {
    return value.toInt() < 0 ? 0 : value.toInt();
  }
  if (value is String) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 0;
    }
    return parsed < 0 ? 0 : parsed;
  }
  return 0;
}

List<String> _resolveSizeOptions(
    Map<String, dynamic> product, Map<String, int> sizeStocks) {
  final availableSizeKeys =
      sizeStocks.entries.where((e) => e.value > 0).map((e) => e.key).toSet();

  final allSizes = _extractSizes(product);
  if (allSizes.isNotEmpty) {
    return allSizes.where((size) => availableSizeKeys.contains(size)).toList();
  }

  return availableSizeKeys.toList();
}

int _effectiveProductStock(Map<String, dynamic> product) {
  final baseStock = (product['stock'] as num?)?.toInt() ?? 0;
  final sizeStocks = _extractSizeStocks(product);
  if (sizeStocks.isEmpty) {
    return baseStock;
  }
  return sizeStocks.values.fold<int>(0, (sum, qty) => sum + qty);
}

int _effectiveStockForSelection(Map<String, dynamic> product,
    {String? selectedSize}) {
  final sizeStocks = _extractSizeStocks(product);
  if (sizeStocks.isEmpty || selectedSize == null || selectedSize.trim().isEmpty) {
    return _effectiveProductStock(product);
  }

  final normalizedSelected = selectedSize.trim().toLowerCase().replaceAll(' ', '');
  for (final entry in sizeStocks.entries) {
    final normalizedKey = entry.key.trim().toLowerCase().replaceAll(' ', '');
    if (normalizedKey == normalizedSelected) {
      return entry.value;
    }
  }

  return 0;
}

double _effectivePriceForSelection(Map<String, dynamic> product,
    {String? selectedSize}) {
  final basePrice = (product['price_syp'] as num?)?.toDouble() ?? 0;
  final sizePrices = _extractSizePrices(product);
  if (sizePrices.isEmpty || selectedSize == null || selectedSize.trim().isEmpty) {
    return basePrice;
  }

  final normalizedSelected = selectedSize.trim().toLowerCase().replaceAll(' ', '');
  for (final entry in sizePrices.entries) {
    final normalizedKey = entry.key.trim().toLowerCase().replaceAll(' ', '');
    if (normalizedKey == normalizedSelected) {
      return entry.value;
    }
  }

  return basePrice;
}

double _minimumSelectablePrice(Map<String, dynamic> product) {
  final sizePrices = _extractSizePrices(product);
  if (sizePrices.isEmpty) {
    return (product['price_syp'] as num?)?.toDouble() ?? 0;
  }
  return sizePrices.values.reduce((a, b) => a < b ? a : b);
}

String _productSizeSummary(Map<String, dynamic> product) {
  final volumeUnit = product['volume']?.toString().trim() ?? '';
  final sizeStocks = _extractSizeStocks(product);
  final sizes = _resolveSizeOptions(product, sizeStocks);

  if (sizes.isNotEmpty) {
    // Show admin-entered sizes as-is to support mixed units like g/kg/l/ml.
    return sizes.join(' / ');
  }

  if (volumeUnit.isNotEmpty) {
    return volumeUnit;
  }

  return '';
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onAdd,
  });

  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final price = _minimumSelectablePrice(product);
    final stock = _effectiveProductStock(product);
    final sizeSummary = _productSizeSummary(product);
    final formatter = NumberFormat('#,##0');
    final isOutOfStock = stock <= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: isOutOfStock ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Image Section
            Expanded(
              flex: 12,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: product['image_url'] != null
                          ? Image.network(product['image_url'], fit: BoxFit.contain)
                          : const Icon(Icons.image, size: 30, color: Colors.grey),
                    ),
                  ),
                  if (isOutOfStock)
                    Positioned(
                      top: 15,
                      right: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5)],
                        ),
                        child: Text(
                          'منتهي',
                          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    product['name']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15, height: 1.2),
                  ),
                  if (sizeSummary.isNotEmpty)
                    Text(
                      sizeSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: ui.TextDirection.ltr,
                      style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatter.format(price)} ل.س',
                    style: GoogleFonts.cairo(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ],
              ),
            ),
            // Add Button
            if (!isOutOfStock)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: InkWell(
                    onTap: onAdd,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary, size: 20),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class ProductDetailsView extends StatefulWidget {
  const ProductDetailsView({
    super.key,
    required this.controller,
    required this.product,
  });

  final StoreController controller;
  final Map<String, dynamic> product;

  @override
  State<ProductDetailsView> createState() => _ProductDetailsViewState();
}

class _ProductDetailsViewState extends State<ProductDetailsView> {
  int _quantity = 1;
  final Map<String, int> _sizeQuantities = {};

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final price = _minimumSelectablePrice(product);
    final stock = _effectiveProductStock(product);
    final formatter = NumberFormat('#,##0.00');
    final imageUrl = product['image_url']?.toString();
    final category = product['category']?.toString().trim();
    final description = product['description']?.toString().trim();
    final sizeStocks = _extractSizeStocks(product);
    final sizeOptions = _resolveSizeOptions(product, sizeStocks);
    final hasSizes = sizeOptions.isNotEmpty;
    final isOutOfStock = stock <= 0;
    final isLowStock = !isOutOfStock && stock < 10;
    final selectedSizeRows = hasSizes
        ? sizeOptions
            .map((size) => (
                  size: size,
                  qty: _sizeQuantities[size] ?? 0,
                  available: _effectiveStockForSelection(product, selectedSize: size),
                  unitPrice: _effectivePriceForSelection(product, selectedSize: size),
                ))
            .where((row) => row.qty > 0)
            .toList()
        : <({String size, int qty, int available, double unitPrice})>[];
    final selectedTotalQty = selectedSizeRows.fold<int>(0, (sum, row) => sum + row.qty);
    final selectedTotalPrice = selectedSizeRows.fold<double>(
      0,
      (sum, row) => sum + (row.unitPrice * row.qty),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل المنتج')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 260,
              child: imageUrl != null
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image,
                          size: 64, color: Colors.grey)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            product['name']?.toString() ?? '',
            style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            hasSizes
                ? 'يبدأ من ${formatter.format(price)} ل.س'
                : '${formatter.format(price)} ل.س',
            style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary),
          ),
          if (category != null && category.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('التصنيف: $category',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
          if (isOutOfStock || isLowStock) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isOutOfStock ? 'الكمية منتهية' : 'الكمية ستنتهي قريباً',
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w700),
              ),
            ),
          ],
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('تفاصيل المنتج',
                style: GoogleFonts.cairo(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(height: 1.5)),
          ],
          if (hasSizes) ...[
            const SizedBox(height: 16),
            Text('اختر المقاسات والكميات',
                style: GoogleFonts.cairo(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...sizeOptions.map((size) {
              final available = _effectiveStockForSelection(product, selectedSize: size);
              final unitPrice = _effectivePriceForSelection(product, selectedSize: size);
              final currentQty = _sizeQuantities[size] ?? 0;
              final isDisabled = available <= 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$size - ${formatter.format(unitPrice)} ل.س',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: isDisabled || currentQty <= 0
                          ? null
                          : () {
                              setState(() {
                                final next = currentQty - 1;
                                if (next <= 0) {
                                  _sizeQuantities.remove(size);
                                } else {
                                  _sizeQuantities[size] = next;
                                }
                              });
                            },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(currentQty.toString()),
                    IconButton(
                      onPressed: isDisabled
                          ? null
                          : () {
                              if (currentQty < available) {
                                setState(() {
                                  _sizeQuantities[size] = currentQty + 1;
                                });
                              } else {
                                Get.snackbar('المخزون', 'تخطيت الكمية المتاحة',
                                    backgroundColor: Colors.orange,
                                    colorText: Colors.white);
                              }
                            },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              );
            }),
            if (selectedTotalQty > 0) ...[
              const SizedBox(height: 8),
              Text(
                'المجموع المحدد: $selectedTotalQty قطعة - ${formatter.format(selectedTotalPrice)} ل.س',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('الكمية',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (_quantity > 1) {
                      setState(() {
                        _quantity -= 1;
                      });
                    }
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(_quantity.toString()),
                IconButton(
                  onPressed: () {
                    if (_quantity < stock) {
                      setState(() {
                        _quantity += 1;
                      });
                    } else {
                      Get.snackbar('المخزون', 'تخطيت الكمية المتاحة',
                          backgroundColor: Colors.orange,
                          colorText: Colors.white);
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: !isOutOfStock
                ? () {
                    if (hasSizes) {
                      if (selectedSizeRows.isEmpty) {
                        Get.snackbar('المقاس', 'اختر مقاسًا واحدًا على الأقل',
                            backgroundColor: Colors.orange,
                            colorText: Colors.white);
                        return;
                      }
                      for (final row in selectedSizeRows) {
                        if (row.qty > row.available) {
                          Get.snackbar('المخزون', 'الكمية المطلوبة غير متوفرة',
                              backgroundColor: Colors.red,
                              colorText: Colors.white);
                          return;
                        }
                      }
                      for (final row in selectedSizeRows) {
                        widget.controller.addToCart(product,
                            selectedSize: row.size, quantity: row.qty);
                      }
                    } else {
                      if (_quantity > stock) {
                        Get.snackbar('المخزون', 'الكمية المطلوبة غير متوفرة',
                            backgroundColor: Colors.red,
                            colorText: Colors.white);
                        return;
                      }
                      widget.controller.addToCart(product, quantity: _quantity);
                    }
                    Get.snackbar('السلة', 'تمت إضافة المنتج إلى السلة',
                        backgroundColor: AppColors.success,
                        colorText: Colors.white);
                  }
                : null,
            child: Text(hasSizes
                ? 'إضافة للسلة بالأحجام والكميات المحددة'
                : 'إضافة للسلة'),
          ),
        ],
      ),
    );
  }
}

class CartView extends StatelessWidget {
  const CartView({super.key, required this.controller});

  final StoreController controller;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00');
    return Scaffold(
      appBar: AppBar(title: const Text('السلة')),
      body: Obx(() {
        if (controller.cartItems.isEmpty) {
          return const Center(child: Text('السلة فارغة'));
        }
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (_, index) {
                  final item = controller.cartItems[index];
                  final quantity = item['quantity'] as int;
                  final price = (item['price_syp'] as num).toDouble();
                  final lineTotal = price * quantity;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: item['image_url'] != null
                                ? Image.network(item['image_url'],
                                    fit: BoxFit.cover)
                                : Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              if (item['selected_size'] != null)
                                Text('المقاس: ${item['selected_size']}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textLight)),
                              Text('${formatter.format(lineTotal)} ل.س',
                                  style: const TextStyle(
                                      color: AppColors.primary)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () =>
                                  controller.decreaseCartQuantity(index),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(quantity.toString()),
                            IconButton(
                              onPressed: () =>
                                  controller.increaseCartQuantity(index),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemCount: controller.cartItems.length,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الإجمالي',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${formatter.format(controller.cartTotal)} ل.س',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.to(() => CheckoutView(controller: controller));
                      },
                      child: const Text('إتمام عملية الشراء'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key, required this.controller});

  final StoreController controller;

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  final TextEditingController _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final String _savedPhone;
  late final String _savedAddress;
  late bool _isEditingPhone;
  late bool _isEditingAddress;

  @override
  void initState() {
    super.initState();
    _savedPhone = widget.controller.checkoutPhone.value.trim();
    _savedAddress = widget.controller.checkoutAddress.value.trim();
    _phoneController = TextEditingController(text: _savedPhone);
    _addressController = TextEditingController(text: _savedAddress);
    _isEditingPhone = _savedPhone.isEmpty;
    _isEditingAddress = _savedAddress.isEmpty;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بيانات التوصيل')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_savedPhone.isNotEmpty && !_isEditingPhone)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                          'تم تعبئة رقم التواصل السابق تلقائياً، هل تريد تعديل رقم التواصل؟'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditingPhone = true;
                        });
                      },
                      child: const Text('تعديل'),
                    ),
                  ],
                ),
              ),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              readOnly: !_isEditingPhone && _savedPhone.isNotEmpty,
              decoration: const InputDecoration(
                  labelText: 'رقم التواصل', border: OutlineInputBorder()),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'الرجاء إدخال رقم التواصل'
                  : null,
            ),
            if (_savedPhone.isNotEmpty && _isEditingPhone)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _phoneController.text = _savedPhone;
                      _isEditingPhone = false;
                    });
                  },
                  child: const Text('استخدام رقم التواصل المحفوظ'),
                ),
              ),
            const SizedBox(height: 12),
            if (_savedAddress.isNotEmpty && !_isEditingAddress)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                          'تم تعبئة عنوان التوصيل السابق تلقائياً، هل تريد تعديل عنوان التوصيل؟'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditingAddress = true;
                        });
                      },
                      child: const Text('تعديل'),
                    ),
                  ],
                ),
              ),
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              readOnly: !_isEditingAddress && _savedAddress.isNotEmpty,
              decoration: const InputDecoration(
                  labelText: 'العنوان', border: OutlineInputBorder()),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'الرجاء إدخال العنوان'
                  : null,
            ),
            if (_savedAddress.isNotEmpty && _isEditingAddress)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _addressController.text = _savedAddress;
                      _isEditingAddress = false;
                    });
                  },
                  child: const Text('استخدام عنوان التوصيل المحفوظ'),
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'ملاحظة إضافية (اختياري)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            Obx(() => ElevatedButton(
                  onPressed: widget.controller.isSubmittingOrder.value
                      ? null
                      : () async {
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          final success = await widget.controller.submitOrder(
                            contactPhone: _phoneController.text,
                            deliveryAddress: _addressController.text,
                            customerNote: _noteController.text,
                          );
                          if (success && mounted) {
                            Get.dialog(
                              const AlertDialog(
                                content: Text(
                                  'تم تاكيد طلبك سيتم التواصل معك من قبل مندوب التوصيل خلال ال 24 ساعة القادمة',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              barrierDismissible: false,
                            );
                            await Future.delayed(const Duration(seconds: 3));
                            if (Get.isDialogOpen ?? false) {
                              Get.back();
                            }
                            Get.until((route) => route.isFirst);
                          }
                        },
                  child: widget.controller.isSubmittingOrder.value
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('تأكيد الطلب'),
                )),
          ],
        ),
      ),
    );
  }
}

class InvoicesView extends StatefulWidget {
  const InvoicesView({super.key, required this.controller});

  final StoreController controller;

  @override
  State<InvoicesView> createState() => _InvoicesViewState();
}

class _InvoicesViewState extends State<InvoicesView> {
  @override
  void initState() {
    super.initState();
    widget.controller.fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd - HH:mm');
    final money = NumberFormat('#,##0.00');
    return Scaffold(
      appBar: AppBar(title: const Text('الفواتير')),
      body: Obx(() {
        if (widget.controller.isLoadingOrders.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (widget.controller.orders.isEmpty) {
          return const Center(child: Text('لا توجد فواتير سابقة'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, index) {
            final invoice = widget.controller.orders[index];
            final List<dynamic> items = invoice['items'] ?? [];
            final createdAtRaw = invoice['placed_at']?.toString();
            final dateText = createdAtRaw != null
                ? dateFormat.format(DateTime.parse(createdAtRaw).toLocal())
                : '-';
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(invoice['order_number'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${invoice['status_label'] ?? ''} - $dateText'),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('رقم التواصل'),
                      Text(invoice['contact_phone']?.toString() ?? '-'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('العنوان: '),
                      Expanded(
                          child: Text(
                              invoice['delivery_address']?.toString() ?? '-')),
                    ],
                  ),
                  const Divider(height: 20),
                  ...items.map((item) {
                    final selectedSize = item['selected_size'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item['product_name']}${selectedSize != null ? ' ($selectedSize)' : ''} × ${item['quantity']}',
                            ),
                          ),
                          Text(
                              '${money.format((item['line_total'] as num).toDouble())} ل.س'),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الإجمالي',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '${money.format((invoice['total'] as num).toDouble())} ل.س',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: widget.controller.orders.length,
        );
      }),
    );
  }
}
