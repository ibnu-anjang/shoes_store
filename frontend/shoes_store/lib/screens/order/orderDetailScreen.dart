import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/models/orderModel.dart';
import 'package:shoes_store/provider/orderProvider.dart';
import 'package:shoes_store/screens/detail/detailScreen.dart';
import '../../widgets/smartImage.dart';
import 'package:shoes_store/screens/review/reviewHelper.dart';
import 'package:shoes_store/services/apiService.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  File? _proofImage;
  bool _isUploading = false;
  bool _isCancelling = false;
  bool _isEditMode = false;
  Map<String, String> _paymentConfig = {};

  @override
  void initState() {
    super.initState();
    _loadPaymentConfig();
  }

  Future<void> _loadPaymentConfig() async {
    final cfg = await ApiService.getPaymentConfig();
    if (mounted) setState(() => _paymentConfig = cfg);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => _proofImage = File(picked.path));
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih Sumber Foto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _sourceButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Galeri',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _sourceButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'Kamera',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: kcontentColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: kprimaryColor),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadProof(String orderId) async {
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih foto bukti pembayaran terlebih dahulu!'), backgroundColor: Colors.red),
      );
      return;
    }
    final provider = OrderProvider.of(context, listen: false);
    setState(() => _isUploading = true);
    try {
      await ApiService.uploadPayment(orderId, _proofImage!);
      await provider.loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bukti pembayaran berhasil dikirim! Menunggu verifikasi admin.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _proofImage = null;
          _isEditMode = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = OrderProvider.of(context);
    final currentOrder = provider.orders.firstWhere(
      (o) => o.id == widget.order.id,
      orElse: () => widget.order,
    );

    final bool isCod = currentOrder.paymentMethod == 'COD';
    final bool isUnpaid = currentOrder.status == OrderStatus.unpaid;
    final bool isVerifying = currentOrder.status == OrderStatus.menungguVerifikasi;
    final bool isProcessing = currentOrder.status == OrderStatus.diproses;
    final bool canCancel = isUnpaid || isVerifying || isProcessing;
    final bool showPaymentSection = (isUnpaid || isVerifying) && !isCod;
    final bool showUpload = isUnpaid || (isVerifying && _isEditMode);

    return Scaffold(
      backgroundColor: kcontentColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            _buildStatusTimeline(currentOrder),
            const SizedBox(height: 15),

            // COD info card
            if (isCod && isProcessing) ...[
              _buildCodProcessingCard(),
              const SizedBox(height: 15),
            ],

            // Payment instructions + upload section (TF/QRIS only)
            if (showPaymentSection) ...[
              _buildPaymentInstructions(currentOrder),
              const SizedBox(height: 15),
              if (showUpload) ...[
                _buildProofUploadSection(currentOrder.id),
                const SizedBox(height: 15),
              ],
              // For VERIFYING: show "sent" card + edit toggle
              if (isVerifying && !_isEditMode) ...[
                _buildProofSentCard(),
                const SizedBox(height: 15),
              ],
            ],

            // Resi
            if (currentOrder.resi != null) _buildResiCard(currentOrder),

            _buildItemsCard(context, currentOrder),
            const SizedBox(height: 15),

            _buildAlamatCard(currentOrder),
            const SizedBox(height: 15),

            _buildPriceCard(currentOrder),
            const SizedBox(height: 15),

            if (isUnpaid)
              _buildWaitingInfoCard(
                icon: Icons.payment,
                color: Colors.amber,
                message: 'Menunggu Pembayaran',
                sub: 'Selesaikan pembayaran dan upload bukti transfer.',
              ),

            if (isVerifying)
              _buildWaitingInfoCard(
                icon: Icons.hourglass_top,
                color: Colors.orange,
                message: 'Menunggu Validasi Pembayaran',
                sub: 'Admin sedang memverifikasi bukti transfer Anda.',
              ),

            if (isProcessing && !isCod)
              _buildWaitingInfoCard(
                icon: Icons.inventory_2_outlined,
                color: Colors.blue,
                message: 'Menunggu Toko Mengirim Barang',
                sub: 'Pesanan Anda sedang diproses dan segera dikirim.',
              ),

            if (canCancel) ...[
              _buildCancelButton(context, currentOrder, provider),
              const SizedBox(height: 8),
            ],

            if (currentOrder.status == OrderStatus.dalamPengiriman)
              _buildConfirmButton(context, currentOrder, provider),

            if (currentOrder.status == OrderStatus.diterima)
              currentOrder.isReviewed
                  ? _buildReviewedLabel()
                  : _buildReviewButton(context, currentOrder),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCodProcessingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
            child: Icon(Icons.local_atm_outlined, color: Colors.green.shade700, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pesanan COD Sedang Diproses',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green.shade800)),
                const SizedBox(height: 3),
                Text('Pembayaran dilakukan saat paket tiba di tangan Anda.',
                    style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofSentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.teal.shade100, shape: BoxShape.circle),
                child: Icon(Icons.check_circle_outline, color: Colors.teal.shade700, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bukti Pembayaran Terkirim',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal.shade800)),
                    Text('Menunggu konfirmasi admin.',
                        style: TextStyle(fontSize: 12, color: Colors.teal.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() {
                _isEditMode = true;
                _proofImage = null;
              }),
              icon: Icon(Icons.edit_outlined, size: 16, color: Colors.teal.shade700),
              label: Text('Edit Bukti Pembayaran',
                  style: TextStyle(fontSize: 13, color: Colors.teal.shade700, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.teal.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewedLabel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          SizedBox(width: 10),
          Text('Pesanan Telah Diulas ✅',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(Order order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: order.status == OrderStatus.menungguVerifikasi
            ? Border.all(color: Colors.orange.shade300, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Status Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (order.status == OrderStatus.unpaid || order.status == OrderStatus.menungguVerifikasi)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.status == OrderStatus.unpaid
                        ? Colors.amber.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    order.statusText,
                    style: TextStyle(
                      color: order.status == OrderStatus.unpaid
                          ? Colors.amber.shade900
                          : Colors.orange.shade800,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTimelineStep(
            icon: Icons.payment,
            title: 'Pesanan Dibuat',
            subtitle: (order.status == OrderStatus.unpaid || order.status == OrderStatus.menungguVerifikasi)
                ? 'Silakan selesaikan pembayaranmu'
                : 'Pembayaran telah dikonfirmasi',
            isActive: true,
            isCompleted: order.status != OrderStatus.unpaid && order.status != OrderStatus.menungguVerifikasi,
          ),
          _buildTimelineConnector(
              order.status != OrderStatus.unpaid && order.status != OrderStatus.menungguVerifikasi),
          _buildTimelineStep(
            icon: Icons.receipt_long,
            title: 'Pesanan Diproses',
            subtitle: 'Penjual sedang memproses pesananmu',
            isActive: order.status != OrderStatus.unpaid && order.status != OrderStatus.menungguVerifikasi,
            isCompleted: order.status == OrderStatus.dalamPengiriman || order.status == OrderStatus.diterima,
          ),
          _buildTimelineConnector(
              order.status == OrderStatus.dalamPengiriman || order.status == OrderStatus.diterima),
          _buildTimelineStep(
            icon: Icons.local_shipping,
            title: 'Dalam Pengiriman',
            subtitle: order.resi != null ? 'No. Resi: ${order.resi}' : 'Menunggu pengiriman',
            isActive: order.status == OrderStatus.dalamPengiriman || order.status == OrderStatus.diterima,
            isCompleted: order.status == OrderStatus.diterima,
          ),
          _buildTimelineConnector(order.status == OrderStatus.diterima),
          _buildTimelineStep(
            icon: Icons.check_circle,
            title: 'Paket Diterima',
            subtitle: 'Pesanan telah diterima',
            isActive: order.status == OrderStatus.diterima,
            isCompleted: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInstructions(Order order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 10),
              Text(
                order.paymentMethod == 'QRIS' ? 'Scan QRIS Pembayaran' : 'Detail Rekening Transfer',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (order.paymentMethod == 'QRIS')
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: _buildQrisImage(200),
            )
          else ...[
            _instructionRow('Bank', _paymentConfig['tf_bank_name'] ?? 'BCA (Modern Shoes Store)'),
            _instructionRow('No. Rekening', _paymentConfig['tf_account_number'] ?? '7712 8890 1234'),
            _instructionRow('Atas Nama', _paymentConfig['tf_account_holder'] ?? 'PT Shoes Store Modern'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: Colors.blue),
            ),
            _instructionRow('Harga Produk', formatRupiah(order.subtotal)),
            _instructionRow('Kode Unik', '+ ${order.uniqueCode}'),
            const SizedBox(height: 4),
            _instructionRowBold('Total Transfer', formatRupiah(order.total)),
          ],
          const SizedBox(height: 15),
          const Text(
            '*Pesanan akan diproses otomatis setelah Anda melakukan pembayaran dan dikonfirmasi oleh sistem.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.blue, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildQrisImage(double size) {
    final qrisUrl = _paymentConfig['qris_image'] ?? '';
    if (qrisUrl.isNotEmpty) {
      final fullUrl = ApiService.normalizeImage(qrisUrl);
      return Image.network(
        fullUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (ctx, err, st) =>
            Icon(Icons.qr_code_2, size: size * 0.5, color: Colors.grey),
      );
    }
    return Image.asset(
      'assets/images/qris_payment.png',
      width: size,
      height: size,
      errorBuilder: (ctx, err, st) =>
          Icon(Icons.qr_code_2, size: size * 0.5, color: Colors.grey),
    );
  }

  Widget _instructionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.blue.shade700, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue.shade900)),
        ],
      ),
    );
  }

  Widget _instructionRowBold(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.blue.shade800, fontSize: 14, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.blue.shade900)),
        ],
      ),
    );
  }

  Widget _buildProofUploadSection(String orderId) {
    final bool isEdit = _isEditMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isEdit ? Icons.edit : Icons.upload_file, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                isEdit ? 'Edit Bukti Pembayaran' : 'Upload Bukti Pembayaran',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange.shade800),
              ),
              const SizedBox(width: 4),
              Text('*wajib',
                  style: TextStyle(fontSize: 11, color: Colors.red.shade600, fontStyle: FontStyle.italic)),
            ],
          ),
          if (isEdit)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Pilih foto baru untuk menggantikan bukti sebelumnya.',
                style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
              ),
            ),
          const SizedBox(height: 12),

          // Image preview area
          GestureDetector(
            onTap: _showImageSourceSheet,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 120),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _proofImage != null ? Colors.orange.shade400 : Colors.orange.shade200,
                  width: 2,
                ),
              ),
              child: _proofImage != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _proofImage!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _showImageSourceSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.swap_horiz, size: 14, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text('Ganti Foto', style: TextStyle(color: Colors.white, fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.orange.shade300),
                          const SizedBox(height: 8),
                          Text('Tap untuk pilih foto',
                              style: TextStyle(color: Colors.orange.shade400, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Dari galeri atau kamera',
                              style: TextStyle(color: Colors.orange.shade300, fontSize: 11)),
                        ],
                      ),
                    ),
            ),
          ),

          if (_proofImage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                  const SizedBox(width: 6),
                  Text('Foto siap dikirim. Pastikan gambar sudah benar!',
                      style: TextStyle(fontSize: 11, color: Colors.green.shade700)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Cancel edit (only in edit mode)
          if (isEdit)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => setState(() {
                    _isEditMode = false;
                    _proofImage = null;
                  }),
                  child: const Text('Batal Edit', style: TextStyle(color: Colors.grey)),
                ),
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: (_isUploading || _proofImage == null) ? null : () => _uploadProof(orderId),
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.verified_outlined, color: Colors.white),
              label: Text(
                _isUploading
                    ? 'Mengirim...'
                    : isEdit
                        ? 'Perbarui Bukti Pembayaran'
                        : 'Konfirmasi Pembayaran',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _proofImage != null ? Colors.orange.shade700 : Colors.grey.shade400,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: _proofImage != null ? 2 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isCompleted,
    bool isLast = false,
  }) {
    final color = isActive ? kprimaryColor : Colors.grey.shade300;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? kprimaryColor.withValues(alpha: 0.1) : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isActive ? Colors.black : Colors.grey.shade400)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12,
                      color: isActive ? Colors.grey.shade600 : Colors.grey.shade400)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineConnector(bool isActive) {
    return Container(
      margin: const EdgeInsets.only(left: 19),
      width: 2,
      height: 30,
      color: isActive ? kprimaryColor : Colors.grey.shade300,
    );
  }

  Widget _buildResiCard(Order order) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.local_shipping, color: Colors.blue.shade700, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nomor Resi', style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
              Text(order.resi!,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(BuildContext context, Order order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Produk Dipesan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DetailScreen(product: item.product)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SmartImage(url: item.product.image, width: 60, height: 60, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.product.title,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const SizedBox(width: 6),
                              Text(item.sku.variantName,
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
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
                              const SizedBox(width: 8),
                              Text('x${item.quantity}',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(formatRupiah(item.totalPrice),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingInfoCard({
    required IconData icon,
    required MaterialColor color,
    required String message,
    required String sub,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.shade700, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color.shade800)),
                const SizedBox(height: 3),
                Text(sub, style: TextStyle(fontSize: 12, color: color.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlamatCard(Order order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Alamat Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, color: kprimaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(order.alamat,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone_outlined, color: kprimaryColor, size: 20),
              const SizedBox(width: 8),
              Text(order.nomorWA, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(Order order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          _priceRow('Subtotal', formatRupiah(order.subtotal)),
          const SizedBox(height: 8),
          _priceRow('Ongkos Kirim', order.ongkir == 0 ? 'Gratis' : formatRupiah(order.ongkir)),
          if (order.uniqueCode > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('Kode Unik', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Ditambahkan untuk identifikasi transfer',
                      child: Icon(Icons.info_outline, size: 13, color: Colors.grey.shade400),
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
                    '+ ${formatRupiah(order.uniqueCode.toDouble())}',
                    style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Bayar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(formatRupiah(order.total),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kprimaryColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        Text(value, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildConfirmButton(BuildContext context, Order order, OrderProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Konfirmasi Penerimaan'),
              content: const Text('Apakah kamu sudah menerima paket ini?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Belum')),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                              SizedBox(width: 12),
                              Text('Memproses konfirmasi...'),
                            ],
                          ),
                          duration: Duration(seconds: 10),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                    try {
                      await provider.confirmReceived(order.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Paket dikonfirmasi diterima!'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal konfirmasi: ${e.toString().replaceAll('Exception: ', '')}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kprimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Ya, Sudah Terima', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        label: const Text('Konfirmasi Paket Diterima',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context, Order order, OrderProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: _isCancelling
              ? null
              : () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Batalkan Pesanan?'),
                      content: const Text('Pesanan yang sudah dibatalkan tidak dapat dikembalikan.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tidak')),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            setState(() => _isCancelling = true);
                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(context);
                            try {
                              await provider.cancelOrder(order.id);
                              if (mounted) {
                                messenger.showSnackBar(const SnackBar(
                                    content: Text('Pesanan berhasil dibatalkan.'),
                                    backgroundColor: Colors.green));
                                nav.pop();
                              }
                            } catch (e) {
                              if (mounted) {
                                messenger.showSnackBar(SnackBar(
                                    content: Text(
                                        'Gagal: ${e.toString().replaceAll('Exception: ', '')}'),
                                    backgroundColor: Colors.red));
                              }
                            } finally {
                              if (mounted) setState(() => _isCancelling = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
          icon: _isCancelling
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.cancel_outlined, color: Colors.red),
          label: Text(
            _isCancelling ? 'Membatalkan...' : 'Batalkan Pesanan',
            style: const TextStyle(color: Colors.red),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewButton(BuildContext context, Order order) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: () => openReviewPicker(context, order),
        icon: const Icon(Icons.star_outline, color: Colors.white),
        label: const Text('Beri Rating & Review',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: kprimaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}
