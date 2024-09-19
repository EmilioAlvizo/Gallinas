import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:ui';

import 'fuente.dart';
//import 'package:connectivity_plus/connectivity_plus.dart';
//import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//import 'package:shared_preferences/shared_preferences.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final FirebaseAuth auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  var emailError = ''.obs;
  var passwordError = ''.obs;
  var generalError = ''.obs;
  var isLoading = false.obs;

  Future<void> signInWithEmailAndPassword() async {
    if (!_validateEmail(emailController.text) ||
        !_validatePassword(passwordController.text)) {
      return;
    }
    isLoading.value = true;

    try {
      await auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      print('Usuario autenticado: ${auth.currentUser?.uid}');
      // Navegar a la pantalla principal de la aplicación
    } on FirebaseAuthException catch (e) {
      print('Error de autenticación: ${e.code}');
      if (e.code == 'user-not-found') {
        emailError.value = 'Usuario no registrado.';
      } else if (e.code == 'wrong-password') {
        passwordError.value = 'Contraseña incorrecta.';
      } else {
        generalError.value =
            'Ocurrió un error inesperado. Por favor, inténtelo de nuevo más tarde.';
      }
    } catch (e) {
      generalError.value = 'Ocurrió un error inesperado. $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      // Desconectar para asegurarnos de que la sesión esté limpia
      await googleSignIn.signOut();

      // Iniciar el proceso de inicio de sesión con Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // El usuario canceló el inicio de sesión
        return;
      }

      // Obtener los detalles de autenticación de la solicitud
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Crear una nueva credencial
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Iniciar sesión en Firebase con la credencial de Google
      await auth.signInWithCredential(credential);

      print('Usuario autenticado con Google: ${auth.currentUser?.uid}');
      // Navegar a la pantalla principal de la aplicación
      // Get.offAllNamed('/home'); // Asegúrate de tener esta ruta definida
    } on FirebaseAuthException catch (e) {
      print('Error de autenticación con Google: ${e.code}');
      switch (e.code) {
        case 'account-exists-with-different-credential':
          generalError.value =
              'Ya existe una cuenta con este correo electrónico.';
          break;
        case 'invalid-credential':
          generalError.value = 'Las credenciales son inválidas.';
          break;
        case 'operation-not-allowed':
          generalError.value = 'Operación no permitida. Contacte al soporte.';
          break;
        case 'user-disabled':
          generalError.value = 'Esta cuenta de usuario ha sido deshabilitada.';
          break;
        case 'user-not-found':
          generalError.value =
              'No se encontró ningún usuario con estas credenciales.';
          break;
        default:
          generalError.value =
              'Ocurrió un error inesperado. Por favor, inténtelo de nuevo más tarde.';
      }
    } catch (e) {
      print('Error detallado: $e');
      generalError.value = 'Error inesperado: $e';
    }
  }

  bool _validateEmail(String email) {
    final emailRegex =
        RegExp(r"^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}$");
    if (!emailRegex.hasMatch(email)) {
      emailError.value = 'Ingrese un correo electrónico válido';
      return false;
    }
    emailError.value = '';
    return true;
  }

  bool _validatePassword(String password) {
    if (password.length < 8) {
      passwordError.value = 'Debe tener al menos 8 caracteres';
      return false;
    }
    passwordError.value = '';
    return true;
  }

  void validateEmail(String value) {
    _validateEmail(value);
  }

  void validatePassword(String value) {
    _validatePassword(value);
  }
}

class LoginPage extends StatelessWidget {
  final LoginController _controller = Get.find();
  var _obscureText = true.obs;

  final List<String> imagePaths = [
    'assets/icon/inicio.jpg',
    'assets/icon/inicio2.jpg',
    'assets/icon/inicio3.jpg',
  ];

  final List<bool> isImageDark = [
    false, // Asumimos que inicio.jpg es una imagen oscura
    true, // Asumimos que inicio2.jpg es una imagen clara
    false, // Asumimos que inicio3.jpg es una imagen oscura
  ];

  LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final int randomIndex = random.nextInt(imagePaths.length);
    final String randomImagePath = imagePaths[randomIndex];
    final bool isDarkImage = isImageDark[randomIndex];

    final customColors = Theme.of(context).extension<CustomColors>()!;
    final textColor = isDarkImage ? Colors.white : Colors.black;
    final buttonColor = isDarkImage ? Color(0xFFECEEE6) : Color(0xFF353730);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(randomImagePath),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _buildGlassContainer(
                      child: Column(
                        children: [
                          Text(
                            'Bienvenido de vuelta!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          /*Text(
                            'Glad to see you 🥰',
                            style: TextStyle(
                                fontSize: 16,
                                color: textColor.withOpacity(0.7)),
                          ),*/
                          const SizedBox(height: 32),
                          _buildGlassTextField(
                            controller: _controller.emailController,
                            labelText: 'Email or username',
                            errorText: _controller.emailError,
                            textColor: textColor,
                          ),
                          const SizedBox(height: 16),
                          _buildGlassTextField(
                            controller: _controller.passwordController,
                            labelText: 'Password',
                            errorText: _controller.passwordError,
                            obscureText: _obscureText.value,
                            textColor: textColor,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // Implementar funcionalidad de "Forgot password?"
                              },
                              child: Text('Olvidaste el password?',
                                  style: TextStyle(
                                      color: textColor.withOpacity(0.7))),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Obx(() => _controller.generalError.value.isNotEmpty
                              ? Text(
                                  _controller.generalError.value,
                                  style: TextStyle(color: customColors.rojo),
                                )
                              : Container()),
                          ElevatedButton(
                            onPressed: _controller.signInWithEmailAndPassword,
                            child: Text('Login',
                                style: TextStyle(
                                    color: isDarkImage
                                        ? Colors.black
                                        : Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 80, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text("No te has registrado?",
                                  style: TextStyle(color: textColor)),
                              TextButton(
                                onPressed: () {
                                  Get.to(() => SignupPage());
                                },
                                child: Text('Signup',
                                    style: TextStyle(color: textColor)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: <Widget>[
                              Expanded(
                                  child: Divider(
                                      thickness: 1,
                                      color: textColor.withOpacity(0.5))),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text('Ingresa con:',
                                    style: TextStyle(color: textColor)),
                              ),
                              Expanded(
                                  child: Divider(
                                      thickness: 1,
                                      color: textColor.withOpacity(0.5))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SignInButton(
                            Buttons.Google,
                            onPressed: _controller.signInWithGoogle,
                          ),
                          SignInButton(
                            Buttons.AppleDark,
                            onPressed: () {
                              // Implementar funcionalidad de inicio de sesión con Apple
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String labelText,
    required RxString errorText,
    bool obscureText = false,
    required Color textColor,
  }) {
    return Obx(() => TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: TextStyle(color: textColor.withOpacity(1.0)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: textColor.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: textColor),
            ),
            errorText: errorText.value.isNotEmpty ? errorText.value : null,
            errorStyle: TextStyle(color: Colors.red[300]),
            filled: true,
            fillColor: textColor.withOpacity(0.1),
          ),
          style: TextStyle(color: textColor),
          obscureText: obscureText && _obscureText.value,
        ));
  }
}

class LoginPage_original extends StatelessWidget {
  final LoginController _controller = Get.find();
  var _obscureText = true.obs; // Para manejar la visibilidad de la contraseña

  final List<String> imagePaths = [
    'assets/icon/inicio.jpg',
    'assets/icon/inicio2.jpg',
    'assets/icon/inicio3.jpg',
    // Agrega más rutas de imágenes según sea necesario
  ];

  LoginPage_original({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    final Random random = Random();
    final int randomIndex = random.nextInt(imagePaths.length);
    final String randomImagePath = imagePaths[randomIndex];

    return Scaffold(
      backgroundColor: customColors.texto1,
      body: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(randomImagePath),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                //AssetImage('assets/icon/ic_launcher.png'),
                //Image.asset(
                //  'assets/icon/ic_launcher.png', // Reemplaza con la ruta correcta de tu imagen
                //  height: 100, // Ajusta la altura según tus necesidades
                //),
                //const SizedBox(height: 32),
                const Text(
                  'Bienvenido de vuelta!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Glad to see you 🥰',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                Obx(() => TextFormField(
                      controller: _controller.emailController,
                      decoration: InputDecoration(
                        labelText: 'Email or username',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        errorText: _controller.emailError.value.isNotEmpty
                            ? _controller.emailError.value
                            : null,
                      ),
                    )),
                const SizedBox(height: 16),
                Obx(() => TextFormField(
                      controller: _controller.passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        errorText: _controller.passwordError.value.isNotEmpty
                            ? _controller.passwordError.value
                            : null,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            _obscureText.value = !_obscureText.value;
                          },
                        ),
                      ),
                      obscureText: true,
                    )),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Implementar funcionalidad de "Forgot password?"
                    },
                    child: const Text('Olvidaste el password?'),
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() => _controller.generalError.value.isNotEmpty
                    ? Text(
                        _controller.generalError.value,
                        style: const TextStyle(color: Colors.red),
                      )
                    : Container()),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await _controller.signInWithEmailAndPassword();
                      // Si el inicio de sesión es exitoso, GetX navegará automáticamente a BottomNavBar
                    } catch (e) {
                      // Maneja el error (muestra un snackbar, etc.)
                      Get.snackbar('Error', e.toString());
                    }
                  },
                  child: const Text('Login'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 80, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text("No te has registrado?"),
                    TextButton(
                      onPressed: () {
                        // Navegar a la página de registro
                        Get.to(() => SignupPage());
                      },
                      child: const Text('Signup'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Row(
                  children: <Widget>[
                    Expanded(child: Divider(thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Ingresa con:'),
                    ),
                    Expanded(child: Divider(thickness: 1)),
                  ],
                ),
                const SizedBox(height: 16),
                SignInButton(
                  Buttons.Google,
                  onPressed: _controller.signInWithGoogle,
                ),
                SignInButton(
                  Buttons.Apple,
                  onPressed: () {
                    // Implementar funcionalidad de inicio de sesión con Apple
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SignupController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  var emailError = ''.obs;
  var passwordError = ''.obs;
  var termsAccepted = false.obs;
  var generalError = ''.obs;

  void registerWithEmailAndPassword() async {
    if (!_validateEmail(emailController.text) ||
        !_validatePassword(passwordController.text) ||
        !termsAccepted.value) {
      return;
    }

    try {
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      // Navegar a la pantalla principal de la aplicación
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          emailError.value = 'El correo electrónico ya está en uso';
          break;
        case 'invalid-email':
          emailError.value = 'Ingrese un correo electrónico válido';
          break;
        case 'weak-password':
          passwordError.value = 'La contraseña es demasiado débil';
          break;
        case 'operation-not-allowed':
          generalError.value = 'Operación no permitida. Contacte al soporte.';
          break;
        default:
          generalError.value =
              'Ocurrió un error inesperado. Por favor, inténtelo de nuevo más tarde.';
      }
    } catch (e) {
      generalError.value =
          'Ocurrió un error inesperado. Por favor, inténtelo de nuevo más tarde.';
    }
  }

  bool _validateEmail(String email) {
    final emailRegex =
        RegExp(r"^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}$");
    if (!emailRegex.hasMatch(email)) {
      emailError.value = 'Ingrese un correo electrónico válido';
      return false;
    }
    emailError.value = '';
    return true;
  }

  bool _validatePassword(String password) {
    if (password.length < 8) {
      passwordError.value = 'Debe tener al menos 8 caracteres';
      return false;
    }
    passwordError.value = '';
    return true;
  }

  void setTermsAccepted(bool value) {
    termsAccepted.value = value;
  }

  Future<void> signInWithGoogle() async {
    try {
      // Iniciar el proceso de inicio de sesión con Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('googleUser $googleUser');
      if (googleUser == null) {
        // El usuario canceló el inicio de sesión
        return;
      }

      // Obtener los detalles de autenticación de la solicitud
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      print('googleAuth $googleAuth');

      // Crear una nueva credencial
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Iniciar sesión en Firebase con la credencial de Google
      await _auth.signInWithCredential(credential);

      // Si llegamos aquí, el inicio de sesión fue exitoso
      // Navegar a la pantalla principal de la aplicación
      //Get.offAllNamed('/home'); // Asegúrate de tener esta ruta definida
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          generalError.value =
              'Ya existe una cuenta con este correo electrónico.';
          break;
        case 'invalid-credential':
          generalError.value = 'Las credenciales son inválidas.';
          break;
        case 'operation-not-allowed':
          generalError.value = 'Operación no permitida. Contacte al soporte.';
          break;
        case 'user-disabled':
          generalError.value = 'Esta cuenta de usuario ha sido deshabilitada.';
          break;
        case 'user-not-found':
          generalError.value =
              'No se encontró ningún usuario con estas credenciales.';
          break;
        default:
          generalError.value =
              'Ocurrió un error inesperado. Por favor, inténtelo de nuevo más tarde.';
      }
    } catch (e) {
      print('Error detallado: $e');
      generalError.value = 'Error inesperado: $e';
    }
  }
}

class SignupPage extends StatelessWidget {
  final SignupController controller = Get.put(SignupController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            const Text(
              'Crear una cuenta',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'We are glad to have you on board 😊',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Obx(() => TextField(
                  controller: controller.emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    errorText: controller.emailError.value.isNotEmpty
                        ? controller.emailError.value
                        : null,
                  ),
                  keyboardType: TextInputType.emailAddress,
                )),
            const SizedBox(height: 10),
            Obx(() => TextField(
                  controller: controller.passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    errorText: controller.passwordError.value.isNotEmpty
                        ? controller.passwordError.value
                        : null,
                  ),
                  obscureText: true,
                )),
            const SizedBox(height: 10),
            Row(
              children: [
                Obx(() => Checkbox(
                      value: controller.termsAccepted.value,
                      onChanged: (value) {
                        controller.setTermsAccepted(value!);
                      },
                    )),
                const Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'I have read, understood and agree to the ',
                      children: [
                        TextSpan(
                          text: 'Privacy Policy',
                          style:
                              TextStyle(decoration: TextDecoration.underline),
                        ),
                        TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Terms & Conditions',
                          style:
                              TextStyle(decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Obx(() => Text(
                  controller.generalError.value,
                  style: const TextStyle(color: Colors.red),
                )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  controller.registerWithEmailAndPassword();
                  Get.back();
                },
                child: const Text('Sign up'),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () {
                  // Navegar a la página de inicio de sesión
                  Get.back();
                },
                child: const Text('Have an account? Login'),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(
                  child: Divider(),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('or'),
                ),
                Expanded(
                  child: Divider(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.g_mobiledata),
                  onPressed: () {
                    controller.signInWithGoogle();
                    Get.back();
                    // Manejar inicio de sesión con Google
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.apple),
                  onPressed: () {
                    // Manejar inicio de sesión con Apple
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
