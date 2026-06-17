import 'package:flutter/material.dart';

class SnackbarUtils {
  static void showCustomSnackBar(
    BuildContext context, 
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    final theme = Theme.of(context);
    
    // Remove current snackbar if any
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    Color backgroundColor = theme.primaryColor;
    if (isError) {
      backgroundColor = Colors.red;
    } else if (isSuccess) {
      backgroundColor = Colors.green;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold, 
            fontSize: 14,
          ),
        ),
        width: 300,
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
        elevation: 10,
      ),
    );
  }
}
