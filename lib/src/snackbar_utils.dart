import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SnackbarUtils {
  static void showSuccess(String message) {
    Get.snackbar(
      'Éxito',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: Icon(Icons.check_circle_rounded, color: Colors.white),
      duration: Duration(seconds: 3),
    );
  }

  static void showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: Icon(Icons.nearby_error_rounded, color: Colors.white),
      duration: Duration(seconds: 3),
    );
  }

  static void showInfo(String message) {
    Get.snackbar(
      'Información',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      icon: Icon(Icons.info_rounded, color: Colors.white),
      duration: Duration(seconds: 3),
    );
  }

  static void showWarning(String message) {
    Get.snackbar(
      'Advertencia',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      icon: Icon(Icons.warning_rounded, color: Colors.white),
      duration: Duration(seconds: 5),
    );
  }
}
