import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'control.dart';

class CerrarSesionBoton extends StatelessWidget {
  final NavegacionVar navegacionVar = Get.find<NavegacionVar>();
  

  CerrarSesionBoton({super.key});

  Future<void> _cerrarSesion() async {
    try {
      // Mostrar un diálogo de confirmación
      bool confirmar = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Get.back(result: false),
            ),
            TextButton(
              child: const Text('Sí, cerrar sesión'),
              onPressed: () => Get.back(result: true),
            ),
          ],
        ),
      ) ?? false;

      if (confirmar) {
        // Mostrar un indicador de carga mientras se procesa el cierre de sesión
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );

        print('Cerrando sesion');
        //await navegacionVar.guardarDatos();
        //Map<String, RxList<dynamic>> dataMap = navegacionVar.getDataMap();
        //await navegacionVar.syncWithFirebase(dataMap);
        await navegacionVar.limpiarVar();

        // Cerrar sesión en Firebase
        await FirebaseAuth.instance.signOut();

        // Intentar desconectar Google Sign-In
        try {
          final GoogleSignIn googleSignIn = GoogleSignIn();
          if (await googleSignIn.isSignedIn()) {
            await googleSignIn.disconnect();
            await googleSignIn.signOut();
          }
        } catch (e) {
          print('Error al desconectar Google Sign-In: $e');
          // Continuar con el cierre de sesión incluso si falla la desconexión de Google
        }

        // Cerrar todas las pantallas hasta la raíz
        Get.until((route) => route.isFirst);

        print('Sesión cerrada exitosamente');

        // Cerrar el indicador de carga
        Get.back();

        // Mostrar un mensaje de éxito
        Get.snackbar(
          'Éxito',
          'Has cerrado sesión correctamente',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('Error al cerrar sesión: $e');
      // Cerrar el indicador de carga si está abierto
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Get.snackbar(
        'Error',
        'No se pudo cerrar la sesión completamente. Por favor, inténtalo de nuevo.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _cerrarSesion,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
      child: const Text(
        'Cerrar Sesión',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}


