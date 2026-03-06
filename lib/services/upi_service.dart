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
    // UPI apps expect upi://pay (with the //)
    final Uri uri = Uri.parse(
      'upi://pay?pa=$gymUpiId'
      '&pn=${Uri.encodeComponent(gymName)}'
      '&am=${amount.toStringAsFixed(2)}'
      '&tn=${Uri.encodeComponent(transactionNote)}'
      '&cu=INR'
    );

    try {
      // On Android, externalNonBrowserApplication is the most reliable for deep links
      final bool launched = await launchUrl(
        uri, 
        mode: LaunchMode.externalNonBrowserApplication
      );
      
      if (!launched) {
        throw 'No UPI apps found that can handle this payment.';
      }
    } catch (e) {
      // If the above fails, try one last fallback with externalApplication
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (innerError) {
        throw 'Could not launch UPI app. Please ensure GPay or PhonePe is installed and has UPI set up.';
      }
    }
  }

  /// Opens WhatsApp to notify the owner.
  static Future<void> notifyOwnerViaWhatsApp({
    required String ownerMobile,
    required String message,
  }) async {
    // Try https first, then whatsapp:// if that fails
    final Uri httpsUri = Uri.parse("https://wa.me/$ownerMobile?text=${Uri.encodeComponent(message)}");
    final Uri waUri = Uri.parse("whatsapp://send?phone=$ownerMobile&text=${Uri.encodeComponent(message)}");

    try {
      await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      try {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
      } catch (innerError) {
        throw 'Could not open WhatsApp. Please ensure it is installed.';
      }
    }
  }
}
