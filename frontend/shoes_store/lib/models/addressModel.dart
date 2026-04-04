class Address {
  final String id;
  final String label; // Rumah, Kantor, dll
  final String receiverName;
  final String phoneNumber;
  final String fullAddress;
  bool isDefault;

  Address({
    required this.id,
    required this.label,
    required this.receiverName,
    required this.phoneNumber,
    required this.fullAddress,
    this.isDefault = false,
  });

  // Untuk keperluan editing (copy with)
  Address copyWith({
    String? id,
    String? label,
    String? receiverName,
    String? phoneNumber,
    String? fullAddress,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      label: label ?? this.label,
      receiverName: receiverName ?? this.receiverName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullAddress: fullAddress ?? this.fullAddress,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
