import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/models/cartItem.dart';
import 'package:shoes_store/provider/orderProvider.dart';
import 'package:shoes_store/provider/reviewProvider.dart';
import 'package:shoes_store/provider/userProvider.dart';
import 'package:shoes_store/services/apiService.dart';
import '../../widgets/smartImage.dart';

class ReviewScreen extends StatefulWidget {
  /// Item spesifik yang akan direview.
  final CartItem item;

  /// ID order tempat item ini berasal (untuk ditampilkan di UI).
  final String orderId;

  final ReviewItem? existingReview;

  const ReviewScreen({
    super.key,
    required this.item,
    required this.orderId,
    this.existingReview,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitted = false;
  bool _isSubmitting = false;
  String? _tempImagePath;
  String? _profileImagePath;
  bool _isUploadingProfile = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingReview != null) {
      _selectedRating = widget.existingReview!.rating.toInt();
      _reviewController.text = widget.existingReview!.comment;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = UserProvider.of(context, listen: false);
      setState(() => _profileImagePath = userProvider.profileImagePath);
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _showProfileImagePicker() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Ubah Foto Profil',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _pickerOption(
                    ctx,
                    icon: Icons.camera_alt_outlined,
                    label: 'Kamera',
                    source: ImageSource.camera,
                  ),
                  _pickerOption(
                    ctx,
                    icon: Icons.photo_library_outlined,
                    label: 'Galeri',
                    source: ImageSource.gallery,
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickerOption(BuildContext ctx, {required IconData icon, required String label, required ImageSource source}) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(ctx);
        await _pickProfileImage(source);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kcontentColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: kprimaryColor),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile == null) return;
    setState(() {
      _profileImagePath = pickedFile.path;
      _isUploadingProfile = true;
    });
    try {
      final result = await ApiService.uploadProfilePicture(pickedFile.path);
      final user = result['user'];
      if (user != null && mounted) {
        final userProvider = UserProvider.of(context, listen: false);
        final normalizedUrl = ApiService.normalizeImage(user['profile_image']?.toString() ?? '');
        await userProvider.updateProfile(imagePath: pickedFile.path);
        setState(() => _profileImagePath = normalizedUrl.isNotEmpty ? normalizedUrl : pickedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload foto: $e'), backgroundColor: Colors.red),
        );
        setState(() => _profileImagePath = null);
      }
    } finally {
      if (mounted) setState(() => _isUploadingProfile = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (Platform.isAndroid || Platform.isIOS) {
        _cropImage(pickedFile.path);
      } else {
        setState(() => _tempImagePath = pickedFile.path);
      }
    }
  }

  Future<void> _cropImage(String filePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: filePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Atur Foto Ulasan',
          toolbarColor: kprimaryColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          activeControlsWidgetColor: kprimaryColor,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
          ],
        ),
        IOSUiSettings(
          title: 'Atur Foto Ulasan',
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.original,
          ],
        ),
      ],
    );
    if (croppedFile != null) {
      setState(() => _tempImagePath = croppedFile.path);
    }
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0 || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    final reviewProvider = ReviewProvider.of(context, listen: false);
    final orderProvider = OrderProvider.of(context, listen: false);
    final userProvider = UserProvider.of(context, listen: false);

    final review = ReviewItem(
      id: widget.existingReview?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      productId: widget.item.product.id.toString(),
      orderItemId: widget.item.id ?? 0,
      userId: userProvider.userId,
      userName: userProvider.userName,
      rating: _selectedRating.toDouble(),
      comment: _reviewController.text,
      date: DateTime.now(),
      imagePath: _tempImagePath,
      profilePicture: _profileImagePath,
    );

    try {
      if (widget.existingReview != null) {
        await reviewProvider.updateReview(review);
      } else {
        await reviewProvider.addReview(review);
        await orderProvider.loadOrders();
      }
      if (mounted) setState(() => _isSubmitted = true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          'Beri Review',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isSubmitted ? _buildSuccessView() : _buildReviewForm(),
    );
  }

  Widget _buildProfileAvatar() {
    ImageProvider? imageProvider;
    if (_profileImagePath != null && _profileImagePath!.isNotEmpty) {
      if (_profileImagePath!.startsWith('http')) {
        imageProvider = NetworkImage(_profileImagePath!);
      } else {
        imageProvider = FileImage(File(_profileImagePath!));
      }
    }

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: imageProvider,
            child: _isUploadingProfile
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : imageProvider == null
                    ? const Icon(Icons.person, size: 45, color: Colors.white)
                    : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isUploadingProfile ? null : _showProfileImagePicker,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kprimaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          // User profile avatar with camera button
          _buildProfileAvatar(),
          const SizedBox(height: 20),

          // Product preview — hanya 1 item
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                Text(
                  'Pesanan ${widget.orderId}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SmartImage(
                        url: widget.item.product.image,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.product.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Size ${widget.item.selectedSize} • x${widget.item.quantity}',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Rating Stars
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Bagaimana produk ini?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 5),
                Text(
                  _getRatingText(),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRating = index + 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          index < _selectedRating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: index < _selectedRating ? 48 : 40,
                          color: index < _selectedRating
                              ? Colors.amber
                              : Colors.grey.shade300,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Review Text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                const Text(
                  'Tulis Review',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reviewController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Ceritakan pengalamanmu dengan produk ini...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: kcontentColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Upload Photo (Optional)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                const Row(
                  children: [
                    Text(
                      'Tambahkan Foto',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(width: 5),
                    Text(
                      '(Opsional)',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                if (_tempImagePath == null)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: kcontentColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                          SizedBox(height: 5),
                          Text(
                            'Pilih Foto',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog.fullscreen(
                              backgroundColor: Colors.black,
                              child: Stack(
                                children: [
                                  Center(
                                    child: InteractiveViewer(
                                      child: Image.file(
                                        File(_tempImagePath!),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 40,
                                    right: 20,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            image: DecorationImage(
                              image: FileImage(File(_tempImagePath!)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -5,
                        right: -5,
                        child: GestureDetector(
                          onTap: () => setState(() => _tempImagePath = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: (_selectedRating == 0 || _isSubmitting) ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: kprimaryColor,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Kirim Review',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: Colors.green.shade400, size: 60),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Terima Kasih!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const SizedBox(height: 10),
            Text(
              'Review untuk ${widget.item.product.title} telah terkirim.\nRating: ${'⭐' * _selectedRating}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kprimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Selesai',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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

  String _getRatingText() {
    switch (_selectedRating) {
      case 1: return 'Sangat Buruk 😞';
      case 2: return 'Buruk 😕';
      case 3: return 'Cukup 😐';
      case 4: return 'Bagus 😊';
      case 5: return 'Sangat Bagus! 🤩';
      default: return 'Tap bintang untuk memberi rating';
    }
  }
}
