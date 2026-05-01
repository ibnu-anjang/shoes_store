import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoes_store/models/addressModel.dart';
import 'package:shoes_store/services/apiService.dart';
import 'package:uuid/uuid.dart';

class AddressProvider extends ChangeNotifier {
  List<Address> _addresses = [];
  Address? _selectedAddress;
  String? _error;

  List<Address> get addresses => _addresses;
  String? get error => _error;

  Address? get selectedAddress => _selectedAddress ?? defaultAddress;

  Address? get defaultAddress {
    try {
      return _addresses.firstWhere((a) => a.isDefault);
    } catch (e) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  static AddressProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<AddressProvider>(context, listen: listen);
  }

  AddressProvider() {
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    _error = null;
    try {
      final data = await ApiService.getAddresses();
      _addresses = data.map((item) => Address(
        id: item['id'],
        label: item['label'],
        receiverName: item['receiver_name'],
        phoneNumber: item['phone_number'],
        fullAddress: item['full_address'],
        isDefault: item['is_default'],
      )).toList();
      notifyListeners();
    } catch (e) {
      _error = "Gagal memuat alamat";
      debugPrint("Gagal fetch addresses: $e");
      notifyListeners();
    }
  }

  Future<void> addAddress(Address address) async {
    if (_addresses.isEmpty) address.isDefault = true;
    else if (address.isDefault) _resetDefaults();
    
    // Create new id if not given
    Address targetAddress = address;
    if (address.id.isEmpty) {
       targetAddress = address.copyWith(id: const Uuid().v4());
    }

    _addresses.add(targetAddress);
    notifyListeners();

    try {
      await ApiService.addAddress({
        "id": targetAddress.id,
        "label": targetAddress.label,
        "receiver_name": targetAddress.receiverName,
        "phone_number": targetAddress.phoneNumber,
        "full_address": targetAddress.fullAddress,
        "is_default": targetAddress.isDefault,
      });
      fetchAddresses(); // Re-sync
    } catch (e) {
      debugPrint("Gagal tambah alamat ke server: $e");
    }
  }

  Future<void> updateAddress(String id, Address newAddress) async {
    final index = _addresses.indexWhere((a) => a.id == id);
    if (index == -1) return;
    if (newAddress.isDefault) _resetDefaults();
    _addresses[index] = newAddress;
    notifyListeners();
    try {
      await ApiService.updateAddress(id, {
        "label": newAddress.label,
        "receiver_name": newAddress.receiverName,
        "phone_number": newAddress.phoneNumber,
        "full_address": newAddress.fullAddress,
        "is_default": newAddress.isDefault,
      });
      await fetchAddresses(); // sync dari server
    } catch (e) {
      debugPrint("Gagal update alamat ke server: $e");
    }
  }

  Future<void> setDefault(String id) async {
    _resetDefaults();
    final index = _addresses.indexWhere((a) => a.id == id);
    if (index == -1) return;
    _addresses[index].isDefault = true;
    notifyListeners();
    try {
      final addr = _addresses[index];
      await ApiService.updateAddress(id, {
        "label": addr.label,
        "receiver_name": addr.receiverName,
        "phone_number": addr.phoneNumber,
        "full_address": addr.fullAddress,
        "is_default": true,
      });
      await fetchAddresses();
    } catch (e) {
      debugPrint("Gagal set default alamat: $e");
    }
  }

  void setSelectedAddress(String id) {
    _selectedAddress = _addresses.firstWhere((a) => a.id == id);
    notifyListeners();
  }

  void clearSelectedAddress() {
    _selectedAddress = null;
    notifyListeners();
  }

  Future<void> deleteAddress(String id) async {
    final index = _addresses.indexWhere((a) => a.id == id);
    if (index != -1) {
      _addresses.removeAt(index);
      notifyListeners();
      try {
        await ApiService.deleteAddress(id);
        fetchAddresses();
      } catch(e) {
        debugPrint(e.toString());
      }
    }
  }

  void _resetDefaults() {
    for (var a in _addresses) {
      a.isDefault = false;
    }
  }

  /// Wipe semua data saat logout agar tidak bocor ke akun berikutnya
  void clearAddresses() {
    _addresses.clear();
    _selectedAddress = null;
    _error = null;
    notifyListeners();
  }
}
