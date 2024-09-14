import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

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
          generalError.value = 'Ya existe una cuenta con este correo electrónico.';
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
          generalError.value = 'No se encontró ningún usuario con estas credenciales.';
          break;
        default:
          generalError.value = 'Ocurrió un error inesperado. Por favor, inténtelo de nuevo más tarde.';
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
/*
class LoginController_original extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final FirebaseAuth auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  var emailError = ''.obs;
  var passwordError = ''.obs;
  var generalError = ''.obs;
  var isLoading = false.obs;

  final storage = FlutterSecureStorage();

  Future<bool> signInOffline(String email, String password) async {
    List<String> users = await getLoggedInUsers();
    print('users $users');
    for (String uid in users) {
      Map<String, String> credentials = await getCredentials(uid);
      print('credentials $credentials');
      if (credentials['email'] == email &&
          credentials['password'] == password) {
        // Las credenciales coinciden, simular inicio de sesión
        print('true');
        return true;
      }
    }
    print('false');
    return false;
  }

  Future<void> saveCredentials(String email, String uid) async {
    await storage.write(key: 'email_$uid', value: email);
    await addLoggedInUser(uid);
  }

  Future<Map<String, String>> getCredentials(String uid) async {
    String? email = await storage.read(key: 'email_$uid');
    return {'email': email ?? ''};
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

  void signInWithEmailAndPassword(emailController, passwordController) async {
    if (!_validateEmail(emailController.text) ||
        !_validatePassword(passwordController.text)) {
      return;
    }
    isLoading.value = true;

    try {
      // Verificar la conectividad
      var connectivityResult = await (Connectivity().checkConnectivity());
      print('connectivityResult $connectivityResult');
      if (connectivityResult.contains(ConnectivityResult.none)) {
        print('no hay conexion');
        // No hay conexión a internet, intentar inicio de sesión offline
        bool offlineSignInSuccess =
            await signInOffline(emailController.text, passwordController.text);
        if (offlineSignInSuccess) {
          //_loadUserData();
          // Navegar a la pantalla principal de la aplicación
        } else {
          generalError.value = 'No se pudo iniciar sesión sin conexión.';
        }
      } else {
        print('si hay conexion');
        // Hay conexión a internet, proceder con el inicio de sesión normal
        await auth.signInWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
        // Guardar las credenciales para uso offline
        await saveCredentials(emailController.text, auth.currentUser!.uid);
        //_loadUserData();

        print('1111111111111111111111111 user $auth');
        // Navegar a la pantalla principal de la aplicación
      }
    } on FirebaseAuthException catch (e) {
      print('+++++++++++++++++++++ ${e.code}');
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
      //Desconectar para asegurarnos de que la sesión esté limpia
      await googleSignIn.signOut();
      // Iniciar el proceso de inicio de sesión con Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
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
      await auth.signInWithCredential(credential);

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
    /*isLoading.value = true;
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      print('22222222222222222222222222222 user $googleUser');
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;
      print('22222222222222222222222222222 auth $googleAuth');

      /*final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );*/

      await auth.signInWithCredential(credential);
      //_loadUserData();
      // Navegar a la pantalla principal de la aplicación
    } catch (e) {
      generalError.value =
          'Ocurrió un error inesperado. Por favor, inténtelo de nuevo más tarde.';
      print(e);
    } finally {
      isLoading.value = false;
    }*/
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

*/
class LoginPage extends StatelessWidget {
  final LoginController _controller = Get.find();
  
  LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return Scaffold(
      backgroundColor: customColors.texto1,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 50, left: 30, right: 30),
        child: Form(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Bienvenido de vuelta!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
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
                  padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
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
    );
  }
}

/*
class LoginPage_original extends StatelessWidget {
  final LoginController _controller = Get.find();
  //final LoginController _controller = Get.put(LoginController());
  //final AuthController authController = Get.find<AuthController>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return Scaffold(
      backgroundColor: customColors.texto1,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 50, left: 30, right: 30),
        child: Form(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Bienvenido de vuelta!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Glad to see you 🥰',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              /*TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email or username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      errorText: _controller.emailError.value.isNotEmpty
                                  ? _controller.emailError.value
                                  : null,
                    ),
                    onChanged: (value) =>
                                _controller.validateEmail(value),
                  ),*/
              Obx(() => TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email or username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      errorText: _controller.emailError.value.isNotEmpty
                          ? _controller.emailError.value
                          : null,
                    ),
                    onChanged: (value) => _controller.validateEmail(value),
                  )),
              const SizedBox(height: 16),
              /*TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      errorText:
                                  _controller.passwordError.value.isNotEmpty
                                      ? _controller.passwordError.value
                                      : null,
                    ),
                    obscureText: true,
                    onChanged: (value) =>
                                _controller.validatePassword(value),
                  ),*/
              Obx(() => TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      errorText: _controller.passwordError.value.isNotEmpty
                          ? _controller.passwordError.value
                          : null,
                    ),
                    obscureText: true,
                    onChanged: (value) => _controller.validatePassword(value),
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
              /*Obx(() => _controller.generalError.value.isNotEmpty
                          ? Text(
                              _controller.generalError.value,
                              style: const TextStyle(color: Colors.red),
                            )
                          : Container()),*/
              ElevatedButton(
                onPressed: () {
                  try {
                    _controller.signInWithEmailAndPassword(
                        /*emailController, passwordController*/);
                    // Si el inicio de sesión es exitoso, GetX navegará automáticamente a BottomNavBar
                  } catch (e) {
                    // Maneja el error (muestra un snackbar, etc.)
                    Get.snackbar('Error', e.toString());
                  }
                },
                child: const Text('Login'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
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
                      Get.to(SignupPage());
                    },
                    child: const Text('Signup'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Row(
                children: <Widget>[
                  Expanded(
                    child: Divider(thickness: 1),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('Ingresa con:'),
                  ),
                  Expanded(
                    child: Divider(thickness: 1),
                  ),
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
    );
  }
}

*/
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
