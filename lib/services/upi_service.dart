import 'package:url_launcher/url_launcher.dart';

class UpiService {
  // Replace with actual business UPI ID in production
  static const String gymUpiId = "ultimatefitness@okaxis";
  static const String gymName = "Ultimate Fitness Point";

  /// Launches the default UPI app (GPay/PhonePe/etc.) with pre-filled details.
  static Future<void> initiateUPIPayment({
    required double amount,
    required String transactionNote,
  }) async {
    final String url = 
      "upi://pay?pa=$gymUpiId&pn=${Uri.encodeComponent(gymName)}&am=$amount&tn=${Uri.encodeComponent(transactionNote)}&cu=INR";

    final Uri uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch UPI app. Please ensure GPay or PhonePe is installed.';
    }
  }

  /// Opens WhatsApp to notify the owner.
  static Future<void> notifyOwnerViaWhatsApp({
    required String ownerMobile,
    required String message,
  }) async {
    // Standard WhatsApp deep link
    final String url = "https://wa.me/$ownerMobile?text=${Uri.encodeComponent(message)}";
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not open WhatsApp.';
    }
  }
}
