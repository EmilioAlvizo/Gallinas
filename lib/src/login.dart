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

class CustomGoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String theme; // 'dark', 'light', or 'neutral'

  const CustomGoogleSignInButton({
    Key? key,
    required this.onPressed,
    this.theme = 'light',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String assetPath = 'assets/';
    String buttonType = 'android_${theme}_rd_na';

    return InkWell(
      onTap: onPressed,
      child: Image.asset(
        '$assetPath$buttonType.png',
      ),
    );
  }
}

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
    final buttonColor =
        isDarkImage ? const Color(0xFFECEEE6) : const Color(0xFF353730);

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
                    buildGlassContainer(
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
                          const SizedBox(height: 40),
                          buildGlassTextField(
                            controller: _controller.emailController,
                            labelText: 'Email or username',
                            errorText: _controller.emailError,
                            textColor: textColor,
                          ),
                          const SizedBox(height: 16),
                          buildGlassTextField(
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
                                  Get.to(() => SignupPage(
                                      randomImagePath: randomImagePath,
                                      textColor: textColor,
                                      isDarkImage: isDarkImage));
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
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
                          CustomGoogleSignInButton(
                            onPressed: _controller.signInWithGoogle,
                            theme: 'dark', // o 'dark' o 'neutral'
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
    bool isEmailValid = _validateEmail(emailController.text);
    bool isPasswordValid = _validatePassword(passwordController.text);

    if (!isEmailValid || !isPasswordValid) {
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
  final String randomImagePath;
  final Color textColor;
  final bool isDarkImage;
  final SignupController controller = Get.put(SignupController());

  SignupPage(
      {Key? key,
      required this.randomImagePath,
      required this.textColor,
      required this.isDarkImage})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    final buttonColor =
        isDarkImage ? const Color(0xFFECEEE6) : const Color(0xFF353730);

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
                  children: [
                    buildGlassContainer(
                      child: Column(
                        children: [
                          //const SizedBox(height: 60),
                          Text(
                            'Crear una cuenta',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor),
                          ),
                          const SizedBox(height: 40),
                          buildGlassTextField(
                            controller: controller.emailController,
                            labelText: 'Email',
                            errorText: controller.emailError,
                            textColor: textColor,
                          ),
                          /*Obx(() => TextField(
                                controller: controller.emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  errorText: controller.emailError.value.isNotEmpty
                                      ? controller.emailError.value
                                      : null,
                                ),
                                keyboardType: TextInputType.emailAddress,
                              )),*/
                          const SizedBox(height: 16),
                          buildGlassTextField(
                            controller: controller.passwordController,
                            labelText: 'Password',
                            errorText: controller.passwordError,
                            textColor: textColor,
                          ),
                          /*Obx(() => TextField(
                                controller: controller.passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  errorText: controller.passwordError.value.isNotEmpty
                                      ? controller.passwordError.value
                                      : null,
                                ),
                                obscureText: true,
                              )),*/
                          const SizedBox(height: 10),
                          /*Row(
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
                                        style: TextStyle(
                                            decoration: TextDecoration.underline),
                                      ),
                                      TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Terms & Conditions',
                                        style: TextStyle(
                                            decoration: TextDecoration.underline),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),*/
                          const SizedBox(height: 10),
                          Obx(() => Text(
                                controller.generalError.value,
                                style: const TextStyle(color: Colors.red),
                              )),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              controller.registerWithEmailAndPassword();
                              Get.back();
                            },
                            child: Text('Sign up',
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
                          const SizedBox(height: 10),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                // Navegar a la página de inicio de sesión
                                Get.back();
                              },
                              child: Text('Have an account?  Login',
                                  style: TextStyle(color: textColor)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(
                                child: const Divider(),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text('or',
                                    style: TextStyle(color: textColor)),
                              ),
                              const Expanded(
                                child: Divider(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              /*IconButton(
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
                              ),*/
                              CustomGoogleSignInButton(
                                onPressed: controller.signInWithGoogle,
                                theme: 'dark', // o 'dark' o 'neutral'
                              ),
                            ],
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
}

Widget buildGlassContainer({required Widget child}) {
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

Widget buildGlassTextField({
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
        obscureText: obscureText,
      ));
}
