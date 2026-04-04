import 'package:flutter/material.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/models/addressModel.dart';
import 'package:shoes_store/provider/addressProvider.dart';

class AddAddressScreen extends StatefulWidget {
  final Address? address;
  const AddAddressScreen({super.key, this.address});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.address?.label ?? "");
    _nameController = TextEditingController(text: widget.address?.receiverName ?? "");
    _phoneController = TextEditingController(text: widget.address?.phoneNumber ?? "");
    _addressController = TextEditingController(text: widget.address?.fullAddress ?? "");
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      final provider = AddressProvider.of(context, listen: false);
      final newAddress = Address(
        id: widget.address?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        label: _labelController.text,
        receiverName: _nameController.text,
        phoneNumber: _phoneController.text,
        fullAddress: _addressController.text,
        isDefault: _isDefault,
      );

      if (widget.address == null) {
        provider.addAddress(newAddress);
      } else {
        provider.updateAddress(widget.address!.id, newAddress);
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat berhasil disimpan!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.address != null;

    return Scaffold(
      backgroundColor: kcontentColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? 'Edit Alamat' : 'Tambah Alamat Baru', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Detail Penerima"),
              const SizedBox(height: 15),
              _buildTextField(_nameController, "Nama Lengkap Penerima", Icons.person_outline),
              const SizedBox(height: 15),
              _buildTextField(_phoneController, "Nomor WhatsApp/HP", Icons.phone_android_outlined, isPhone: true),
              
              const SizedBox(height: 25),
              _buildSectionTitle("Informasi Alamat"),
              const SizedBox(height: 15),
              _buildTextField(_labelController, "Label Alamat (Rumah, Kantor, dll)", Icons.label_important_outline),
              const SizedBox(height: 15),
              _buildTextField(_addressController, "Alamat Lengkap", Icons.location_on_outlined, maxLines: 3),
              
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Jadikan Alamat Utama', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Gunakan sebagai alamat default saat checkout', style: TextStyle(fontSize: 12)),
                activeColor: kprimaryColor,
                value: _isDefault,
                onChanged: (val) => setState(() => _isDefault = val),
              ),

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kprimaryColor,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(isEditing ? 'Simpan Perubahan' : 'Simpan Alamat', 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPhone = false, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
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
}
