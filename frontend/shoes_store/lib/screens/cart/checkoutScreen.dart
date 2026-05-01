import 'package:flutter/material.dart';
import 'package:shoes_store/models/cartItem.dart';
import 'package:shoes_store/provider/addressProvider.dart';
import 'package:shoes_store/provider/cartProvider.dart';
import '../../widgets/smartImage.dart';
import 'package:shoes_store/provider/orderProvider.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/screens/navBar.dart';
import 'package:shoes_store/screens/order/orderDetailScreen.dart';
import 'package:shoes_store/models/orderModel.dart';
import 'package:shoes_store/services/authService.dart';
import 'package:shoes_store/screens/auth/loginScreen.dart';
import 'package:shoes_store/screens/profile/address/addressListScreen.dart';
import 'package:shoes_store/screens/profile/address/addAddressScreen.dart';
import 'package:shoes_store/provider/userProvider.dart';
import 'package:shoes_store/services/apiService.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> items;
  final bool isBuyNow;

  const CheckoutScreen({super.key, required this.items, this.isBuyNow = false});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _waController = TextEditingController();
  String _selectedMethod = 'Bank Transfer';
  bool _isCheckingOut = false;
  Map<String, String> _paymentConfig = {};

  @override
  void initState() {
    super.initState();
    ApiService.getPaymentConfig().then((cfg) {
      if (mounted) setState(() => _paymentConfig = cfg);
    });
  }

  final List<Map<String, dynamic>> _methods = [
    {
      'id': 'Bank Transfer',
      'title': 'Transfer Bank (Manual)',
      'icon': Icons.account_balance_outlined,
      'description': 'Transfer ke Rekening Resmi PT Shoes Store',
    },
    {
      'id': 'QRIS',
      'title': 'QRIS / E-Wallet',
      'icon': Icons.qr_code_scanner_outlined,
      'description': 'Bayar instan pakai Gopay, OVO, Dana',
    },
    {
      'id': 'COD',
      'title': 'COD (Bayar di Tempat)',
      'icon': Icons.handshake_outlined,
      'description': 'Bayar saat kurir mengantar barang',
    },
  ];

  // Replikasi rumus backend: sum(ord(c) for c in username) % 100 + 1
  int _calcUniqueCode(String username) =>
      username.codeUnits.fold(0, (s, c) => s + c) % 100 + 1;

  Widget _buildQrisWidget(double size) {
    final qrisUrl = _paymentConfig['qris_image'] ?? '';
    if (qrisUrl.isNotEmpty) {
      return Image.network(
        ApiService.normalizeImage(qrisUrl),
        width: size, height: size, fit: BoxFit.contain,
        errorBuilder: (ctx, e, s) => Icon(Icons.qr_code_2, size: size * 0.4, color: Colors.grey),
      );
    }
    return Image.asset(
      'assets/images/qris_payment.png',
      fit: BoxFit.contain,
      errorBuilder: (ctx, e, s) => Icon(Icons.qr_code_2, size: size * 0.4, color: Colors.grey),
    );
  }

  double get _subtotal {
    double total = 0;
    for (var item in widget.items) {
      total += item.totalPrice;
    }
    return total;
  }

  double get _total => _subtotal + CartProvider.flatOngkir;

  String? _validateWa(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Nomor WhatsApp wajib diisi';
    if (!digits.startsWith('08') && !digits.startsWith('628')) {
      return 'Nomor WA harus diawali 08 atau 628';
    }
    if (digits.length < 10 || digits.length > 13) {
      return 'Nomor WA tidak valid (10–13 digit)';
    }
    return null;
  }

  Future<void> _handleCheckout() async {
    if (_alamatController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon isi alamat pengiriman!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final waError = _validateWa(_waController.text);
    if (waError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(waError), backgroundColor: Colors.red),
      );
      return;
    }

    if (_isCheckingOut) return; // Guard double-tap

    // Capture providers before async gap
    final orderProvider = OrderProvider.of(context, listen: false);
    final addressProvider = AddressProvider.of(context, listen: false);

    // Confirmation Dialog before placing order
    final bool isCod = _selectedMethod == 'COD';
    final username = UserProvider.of(context).userName;
    final uniqueCode = isCod ? 0 : _calcUniqueCode(username);
    final grandTotal = _total + uniqueCode;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Konfirmasi Pesanan", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Apakah Anda yakin ingin membuat pesanan ini?"),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Tagihan:", style: TextStyle(color: Colors.grey)),
                Text(
                  formatRupiah(isCod ? _total : grandTotal),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: kprimaryColor),
                ),
              ],
            ),
            if (!isCod) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("  (sudah termasuk kode unik)", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  Text(formatRupiah(uniqueCode.toDouble()),
                      style: TextStyle(fontSize: 11, color: Colors.orange.shade600, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kprimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Ya, Pesan Sekarang",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Check Auth
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Silakan login terlebih dahulu!"),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isCheckingOut = true);
    // Map UI label ke kode backend
    final pmMap = {'Bank Transfer': 'TF', 'QRIS': 'QRIS', 'COD': 'COD'};
    final paymentMethodCode = pmMap[_selectedMethod] ?? 'TF';
    try {
      final order = await orderProvider.checkout(
        items: widget.items,
        address: _alamatController.text,
        phone: _waController.text,
        paymentMethod: paymentMethodCode,
      );

      addressProvider.clearSelectedAddress();

      if (!mounted) return;
      _showSuccessDialog(_selectedMethod == 'COD', order);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal checkout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  void _showSuccessDialog(bool isCOD, Order order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            Text(
              isCOD
                  ? 'Pesanan Berhasil Dibuat! 📦'
                  : 'Pesanan Berhasil Dibuat! 🚀',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isCOD
                  ? 'Terima kasih! Pesanan Anda akan segera kami proses dan dikirim.'
                  : 'Mohon selesaikan pembayaran agar pesanan segera diproses.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BottomNavBar(),
                    ),
                    (route) => false,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailScreen(order: order),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kprimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Lihat Detail Pesanan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kcontentColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STEP 1: ALAMAT
            _buildSectionTitle("Informasi Pengiriman"),
            const SizedBox(height: 15),
            _buildAddressInputs(),

            const SizedBox(height: 25),

            // STEP 2: PESANAN
            _buildSectionTitle("Ringkasan Pesanan"),
            const SizedBox(height: 15),
            _buildOrderItems(),

            const SizedBox(height: 25),

            // STEP 3: METODE PEMBAYARAN
            _buildSectionTitle("Metode Pembayaran"),
            const SizedBox(height: 15),
            ..._methods.map((m) => _buildPaymentMethod(m)),

            // DETAIL PEMBAYARAN (Baru ditambahkan)
            if (_selectedMethod != 'COD') ...[
              const SizedBox(height: 15),
              _buildMethodDetails(),
            ],

            const SizedBox(height: 25),

            // STEP 4: RINGKASAN HARGA
            _buildSectionTitle("Ringkasan Pembayaran"),
            const SizedBox(height: 15),
            _buildPriceSummary(),

            const SizedBox(height: 40),

            // TOMBOL BUAT PESANAN
            ElevatedButton(
              onPressed: _isCheckingOut ? null : _handleCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: kprimaryColor,
                disabledBackgroundColor: kprimaryColor.withAlpha(150),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: _isCheckingOut
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Buat Pesanan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
    );
  }

  Widget _buildAddressInputs() {
    final addressProvider = AddressProvider.of(context);
    final selectedAddress = addressProvider.selectedAddress;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Alamat Pengiriman",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => selectedAddress != null
                          ? const AddressListScreen(isSelectionMode: true)
                          : const AddAddressScreen(),
                    ),
                  );
                },
                child: Text(
                  selectedAddress != null ? "Ubah" : "Tambah",
                  style: const TextStyle(
                    color: kprimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          if (selectedAddress != null) ...[
            Row(
              children: [
                const Icon(Icons.location_on, color: kprimaryColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${selectedAddress.receiverName} | ${selectedAddress.phoneNumber}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedAddress.fullAddress,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Update controllers silently for order creation logic
            () {
              _alamatController.text = selectedAddress.fullAddress;
              _waController.text = selectedAddress.phoneNumber;
              return const SizedBox.shrink();
            }(),
          ] else
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    color: Colors.grey.shade300,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Belum ada alamat pengiriman",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.items.length,
        separatorBuilder: (ctx, idx) => const Divider(height: 1),
        itemBuilder: (ctx, idx) {
          final item = widget.items[idx];
          return ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SmartImage(
                url: item.displayImage,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              item.product.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Row(
              children: [
                Text(
                  "${item.sku.variantName} | x${item.quantity}",
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: item.selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 0.5),
                  ),
                ),
              ],
            ),
            trailing: Text(
              formatRupiah(item.totalPrice),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: kprimaryColor,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethod(Map<String, dynamic> method) {
    bool isSelected = _selectedMethod == method['id'];
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? kprimaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              method['icon'],
              color: isSelected ? kprimaryColor : Colors.grey,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    method['description'],
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: kprimaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: _selectedMethod == 'Bank Transfer'
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detail Rekening PT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 15),
                _detailRow('Bank', _paymentConfig['tf_bank_name'] ?? 'BCA (Modern Shoes Store)'),
                _detailRow('No. Rekening', _paymentConfig['tf_account_number'] ?? '7712 8890 1234'),
                _detailRow('Nama Penerima', _paymentConfig['tf_account_holder'] ?? 'PT Shoes Store Modern'),
                const SizedBox(height: 10),
                const Text(
                  '*Mohon simpan bukti transfer Anda',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            )
          : Column(
              children: [
                const Text(
                  'Scan QRIS Disini',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: _buildQrisWidget(200),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sistem akan memverifikasi otomatis setelah Anda klik "Buat Pesanan".',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary() {
    final bool needsUniqueCode = _selectedMethod != 'COD';
    final username = UserProvider.of(context).userName;
    final uniqueCode = needsUniqueCode ? _calcUniqueCode(username) : 0;
    final grandTotal = _total + uniqueCode;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryRow("Subtotal", formatRupiah(_subtotal)),
          const SizedBox(height: 10),
          _summaryRow(
            "Biaya Pengiriman",
            CartProvider.flatOngkir == 0 ? "Gratis" : formatRupiah(CartProvider.flatOngkir),
          ),
          if (needsUniqueCode) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text("Kode Unik", style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(width: 5),
                    Tooltip(
                      message: 'Ditambahkan agar pembayaranmu mudah diidentifikasi sistem',
                      child: Icon(Icons.info_outline, size: 14, color: Colors.grey.shade400),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    "+ ${formatRupiah(uniqueCode.toDouble())}",
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Tagihan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text(
                formatRupiah(needsUniqueCode ? grandTotal : _total),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: kprimaryColor),
              ),
            ],
          ),
          if (needsUniqueCode)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '* Sudah termasuk kode unik ${formatRupiah(uniqueCode.toDouble())} untuk identifikasi transfer.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
