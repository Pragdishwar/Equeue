import 'dart:convert';

class QRService {
  /// Generate QR data string for a token.
  static String generateTokenQRData({
    required String tokenId,
    required String tokenNumber,
    required String serviceId,
    required String branchId,
  }) {
    final data = {
      'token_id': tokenId,
      'token_number': tokenNumber,
      'service_id': serviceId,
      'branch_id': branchId,
      'timestamp': DateTime.now().toIso8601String(),
    };
    return jsonEncode(data);
  }

  /// Parse QR data string back to a map.
  static Map<String, dynamic>? parseQRData(String qrData) {
    try {
      return jsonDecode(qrData) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Validate QR data has required fields.
  static bool isValidTokenQR(Map<String, dynamic> data) {
    return data.containsKey('token_id') &&
        data.containsKey('token_number') &&
        data.containsKey('service_id') &&
        data.containsKey('branch_id');
  }
}
