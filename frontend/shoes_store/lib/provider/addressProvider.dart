import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoes_store/models/addressModel.dart';

class AddressProvider extends ChangeNotifier {
  final List<Address> _addresses = [];
  Address? _selectedAddress;

  List<Address> get addresses => _addresses;

  Address? get selectedAddress => _selectedAddress ?? defaultAddress;

  Address? get defaultAddress {
    try {
      return _addresses.firstWhere((a) => a.isDefault);
    } catch (e) {
      // Jika tidak ada default, ambil yang pertama jika tersedia
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  static AddressProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<AddressProvider>(context, listen: listen);
  }

  void addAddress(Address address) {
    // Jika ini alamat pertama, jadikan default otomatis
    if (_addresses.isEmpty) {
      address.isDefault = true;
    } else if (address.isDefault) {
      // Jika ada alamat baru diset default, reset yang lain
      _resetDefaults();
    }
    _addresses.add(address);
    notifyListeners();
  }

  void setSelectedAddress(String id) {
    _selectedAddress = _addresses.firstWhere((a) => a.id == id);
    notifyListeners();
  }

  void clearSelectedAddress() {
    _selectedAddress = null;
    notifyListeners();
  }

  void updateAddress(String id, Address newAddress) {
    final index = _addresses.indexWhere((a) => a.id == id);
    if (index != -1) {
      if (newAddress.isDefault) {
        _resetDefaults();
      }
      _addresses[index] = newAddress;
      notifyListeners();
    }
  }

  void deleteAddress(String id) {
    bool wasDefault = false;
    final index = _addresses.indexWhere((a) => a.id == id);
    if (index != -1) {
      wasDefault = _addresses[index].isDefault;
      _addresses.removeAt(index);
      
      // Jika yang dihapus adalah default dan masih ada alamat lain, set yang pertama jadi default
      if (wasDefault && _addresses.isNotEmpty) {
        _addresses.first.isDefault = true;
      }
      notifyListeners();
    }
  }

  void setDefault(String id) {
    _resetDefaults();
    final index = _addresses.indexWhere((a) => a.id == id);
    if (index != -1) {
      _addresses[index].isDefault = true;
      notifyListeners();
    }
  }

  void _resetDefaults() {
    for (var a in _addresses) {
      a.isDefault = false;
    }
  }
}
