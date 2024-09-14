import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'control.dart';

class AuthState {
  final User? user;
  final bool isOfflineAuthenticated;

  AuthState({this.user, this.isOfflineAuthenticated = false});

  bool get isAuthenticated => user != null || isOfflineAuthenticated;
}

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Rx<AuthState> authState = Rx<AuthState>(AuthState());
  final RxBool isOffline = false.obs;
  final storage = FlutterSecureStorage();

  @override
  void onInit() {
    super.onInit();
    _checkConnectivity();
    ever(isOffline, (_) => _checkAuthState());
    _auth.authStateChanges().listen((User? firebaseUser) {
      if (!isOffline.value) {
        authState.value = AuthState(user: firebaseUser);
      }
    });
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    isOffline.value = connectivityResult.contains(ConnectivityResult.none);
  }

  Future<void> _checkAuthState() async {
    if (isOffline.value) {
      final prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      authState.value = AuthState(isOfflineAuthenticated: isLoggedIn);
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      print('connectivityResult $connectivityResult');
      if (connectivityResult.contains(ConnectivityResult.none)) {
        print('no hay conexion');

        // Intento de inicio de sesión offline
        bool offlineSignInSuccess = await signInOffline(email, password);
        if (offlineSignInSuccess) {
          final prefs = await SharedPreferences.getInstance();
          print('prefs $prefs');
          await prefs.setBool('is_logged_in', true);
          print('prefs $prefs');
          authState.value = AuthState(isOfflineAuthenticated: true);
          print('user.value ${authState.value}');
        } else {
          throw Exception('No se pudo iniciar sesión sin conexión.');
        }
      } else {
        print('si hay conexion');
        // Inicio de sesión online
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await saveCredentials(email, password, userCredential.user!.uid);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        authState.value = AuthState(user: userCredential.user);
      }
    } catch (e) {
      print('Error en signInWithEmailAndPassword: $e');
      rethrow;
    }
  }

  Future<bool> signInOffline(String email, String password) async {
    List<String> users = await getLoggedInUsers();
    print('users $users');
    for (String uid in users) {
      Map<String, String> credentials = await getCredentials(uid);
      print('credentials $credentials');
      if (credentials['email'] == email &&
          credentials['password'] == password) {
        print('true');
        return true;
      }
    }
    print('false');
    return false;
  }

  Future<void> saveCredentials(
      String email, String password, String uid) async {
    await storage.write(key: 'email_$uid', value: email);
    await storage.write(key: 'password_$uid', value: password);
    await addLoggedInUser(uid);
  }

  Future<Map<String, String>> getCredentials(String uid) async {
    String? email = await storage.read(key: 'email_$uid');
    String? password = await storage.read(key: 'password_$uid');
    return {'email': email ?? '', 'password': password ?? ''};
  }

  Future<void> addLoggedInUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> users = prefs.getStringList('logged_in_users') ?? [];
    if (!users.contains(uid)) {
      users.add(uid);
      await prefs.setStringList('logged_in_users', users);
    }
  }

  Future<List<String>> getLoggedInUsers() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('logged_in_users') ?? [];
  }

  Future<void> signOut() async {
    if (!isOffline.value) {
      await _auth.signOut();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    authState.value = AuthState();
  }
}

class CerrarSesionBoton extends StatelessWidget {
  final NavegacionVar navegacionVar = Get.find<NavegacionVar>();
  

  CerrarSesionBoton({Key? key}) : super(key: key);

  Future<void> _cerrarSesion() async {
    try {
      // Mostrar un diálogo de confirmación
      bool confirmar = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Cerrar Sesión'),
          content: Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Get.back(result: false),
            ),
            TextButton(
              child: Text('Sí, cerrar sesión'),
              onPressed: () => Get.back(result: true),
            ),
          ],
        ),
      ) ?? false;

      if (confirmar) {
        // Mostrar un indicador de carga mientras se procesa el cierre de sesión
        Get.dialog(
          Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );

        print('Cerrando sesion');
        await navegacionVar.guardarDatos();
        Map<String, RxList<dynamic>> dataMap = navegacionVar.getDataMap();
        await navegacionVar.syncWithFirebase(dataMap);
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
        minimumSize: Size(double.infinity, 50),
      ),
      child: const Text(
        'Cerrar Sesión',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}

/*class CerrarSesionBoton_original extends StatelessWidget {
  final NavegacionVar navegacionVar = Get.find<NavegacionVar>();
  final AuthController authController = Get.find<AuthController>();

  Future<void> _cerrarSesion() async {
    try {
      // Mostrar un diálogo de confirmación
      bool confirmar = await Get.dialog(
        AlertDialog(
          title: Text('Cerrar Sesión'),
          content: Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Get.back(result: false),
            ),
            TextButton(
              child: Text('Sí, cerrar sesión'),
              onPressed: () => Get.back(result: true),
            ),
          ],
        ),
      );

      if (confirmar) {
        print('Cerrando sesion');
        await navegacionVar.guardarDatos();
        Map<String, RxList<dynamic>> dataMap = navegacionVar.getDataMap();
        await navegacionVar.syncWithFirebase(dataMap);
        await navegacionVar.limpiarVar();

        await FirebaseAuth.instance.signOut(); // Cierra sesión en Firebase
        await GoogleSignIn().disconnect(); // Desconecta la cuenta de Google
        await GoogleSignIn().signOut(); // Cierra sesión en Google

        // ... dentro de tu función _cerrarSesion()
        /*final GoogleSignIn googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          print('entro el if en cerrar cecion google');
          await googleSignIn.disconnect();
          await GoogleSignIn().signOut();
        }

        // Cerrar sesión
        if (!authController.isOffline.value) {
          print('entro el if en cerrar cecion');
          await FirebaseAuth.instance.signOut();
          await authController._auth.signOut();
        }*/
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', false);
        authController.authState.value = AuthState();

        // Cerrar todas las pantallas hasta la raíz
        Get.until((route) => route.isFirst);

        // Mostrar un indicador de carga mientras se procesa el cierre de sesión
        Get.dialog(
          Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );

        print('si se cerro exxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxito');
        // Esperar un poco para dar tiempo a que el StreamBuilder reaccione
        await Future.delayed(Duration(seconds: 1));

        // Cerrar el indicador de carga
        Get.back();
      }
    } catch (e) {
      print('Error al cerrar sesión: $e');
      Get.snackbar(
        'Error',
        'No se pudo cerrar la sesión. Por favor, inténtalo de nuevo.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _cerrarSesion,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
      ),
      child: const Text(
        'Cerrar Sesión',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}*/
