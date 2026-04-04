import 'package:flutter/material.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/models/addressModel.dart';
import 'package:shoes_store/provider/addressProvider.dart';
import 'package:shoes_store/screens/profile/address/addAddressScreen.dart';

class AddressListScreen extends StatelessWidget {
  final bool isSelectionMode;
  const AddressListScreen({super.key, this.isSelectionMode = false});

  @override
  Widget build(BuildContext context) {
    final addressProvider = AddressProvider.of(context);
    final addresses = addressProvider.addresses;

    return Scaffold(
      backgroundColor: kcontentColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isSelectionMode ? 'Pilih Alamat' : 'Alamat Saya', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: addresses.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                return _buildAddressCard(context, address, addressProvider);
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AddAddressScreen())),
          style: ElevatedButton.styleFrom(
            backgroundColor: kprimaryColor,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text('Tambah Alamat Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text('Belum ada alamat tersimpan', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, Address address, AddressProvider provider) {
    return GestureDetector(
      onTap: () {
        if (isSelectionMode) {
          provider.setSelectedAddress(address.id);
          Navigator.pop(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: address.isDefault ? Border.all(color: kprimaryColor, width: 2) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(address.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (address.isDefault) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: kprimaryColor, borderRadius: BorderRadius.circular(5)),
                        child: const Text('Utama', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  itemBuilder: (ctx) => [
                    if (!address.isDefault) const PopupMenuItem(value: 'default', child: Text('Jadikan Utama')),
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: Colors.red))),
                  ],
                  onSelected: (value) {
                    if (value == 'default') provider.setDefault(address.id);
                    if (value == 'delete') provider.deleteAddress(address.id);
                    if (value == 'edit') {
                      Navigator.push(context, MaterialPageRoute(builder: (ctx) => AddAddressScreen(address: address)));
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(address.receiverName, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(address.phoneNumber, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 10),
            Text(address.fullAddress, style: const TextStyle(color: Colors.black87, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
