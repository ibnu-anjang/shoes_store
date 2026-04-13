import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/provider/userProvider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _newPasswordController;
  String? _tempImagePath;
  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = UserProvider.of(context, listen: false);
    _nameController = TextEditingController(text: user.userName);
    _emailController = TextEditingController(text: user.email);
    _newPasswordController = TextEditingController();
    _tempImagePath = user.profileImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Fitur Crop hanya tersedia di Mobile (Android/iOS)
      if (Platform.isAndroid || Platform.isIOS) {
        _cropImage(pickedFile.path);
      } else {
        // Jika di Desktop (Linux/Windows), langsung gunakan fotonya
        setState(() {
          _tempImagePath = pickedFile.path;
        });
      }
    }
  }

  Future<void> _cropImage(String filePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: filePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Atur Posisi Foto',
          toolbarColor: kprimaryColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          activeControlsWidgetColor: kprimaryColor,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
          ],
        ),
        IOSUiSettings(
          title: 'Atur Posisi Foto',
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
          ],
        ),
      ],
    );

    if (croppedFile != null) {
      final file = File(croppedFile.path);
      final sizeInBytes = await file.length();
      final sizeInMb = sizeInBytes / (1024 * 1024);

      if (sizeInMb > 2) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hasil potongan masih terlalu besar! Maksimal 2 MB.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _tempImagePath = croppedFile.path;
      });
    }
  }

  ImageProvider? _getAvatarImage() {
    // Priority: 1) temp cropped image, 2) server profile image, 3) null (show icon)
    if (_tempImagePath != null) {
      if (_tempImagePath!.startsWith('http')) {
        return NetworkImage(_tempImagePath!);
      }
      return FileImage(File(_tempImagePath!));
    }
    final userProvider = UserProvider.of(context, listen: false);
    if (userProvider.profileImagePath != null && userProvider.profileImagePath!.isNotEmpty) {
      if (userProvider.profileImagePath!.startsWith('http')) {
        return NetworkImage(userProvider.profileImagePath!);
      }
      return FileImage(File(userProvider.profileImagePath!));
    }
    return null; // Will show person icon
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final userProvider = UserProvider.of(context, listen: false);
        
        String? newPW = _newPasswordController.text.isNotEmpty ? _newPasswordController.text : null;
        
        await userProvider.updateProfile(
          name: _nameController.text,
          email: _emailController.text,
          password: newPW,
          imagePath: _tempImagePath,
        );

        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui! 🎉'), backgroundColor: Colors.green),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui: $e'), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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
        title: const Text('Pengaturan Profil', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: _getAvatarImage(),
                        child: _getAvatarImage() == null
                            ? const Icon(Icons.person, size: 60, color: Colors.white)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: kprimaryColor, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              _buildSectionTitle("Informasi Dasar"),
              const SizedBox(height: 15),
              _buildTextField(_nameController, "Username", Icons.person_outline),
              const SizedBox(height: 15),
              _buildTextField(_emailController, "Gmail / Email", Icons.email_outlined),
              
              const SizedBox(height: 30),
              _buildSectionTitle("Keamanan (Ganti Password)"),
              const SizedBox(height: 15),
              _buildPasswordField(_newPasswordController, "Password Baru", "Biarkan kosong jika tidak ingin mengubah"),
              
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kprimaryColor,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Simpan Perubahan', 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)],
      ),
      child: TextFormField(
        controller: controller,
        validator: (value) => value == null || value.isEmpty ? 'Data tidak boleh kosong' : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: kprimaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !_showPassword,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          prefixIcon: const Icon(Icons.lock_outline, color: kprimaryColor),
          suffixIcon: IconButton(
            icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
