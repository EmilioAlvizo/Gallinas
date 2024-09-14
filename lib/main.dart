import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';

import 'src/autenticacion.dart';
import 'src/comida.dart';
import 'src/control.dart';
import 'src/fuente.dart';
import 'src/gallinas.dart';
import 'src/huevos.dart';
import 'src/invitacion.dart';
import 'src/login.dart';
import 'src/navegacion.dart';
import 'src/opciones.dart';
import 'src/sqlite.dart';

//import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Get.lazyPut(() => ThemeController());
  Get.lazyPut(() => CardControllerH());
  Get.lazyPut(() => CardControllerC());
  Get.lazyPut(() => CardController());
  Get.lazyPut(() => AuthController());
  Get.lazyPut(() => InvitationSystem());
  Get.lazyPut(() => AveControl());
  Get.lazyPut(() => NavegacionVar());
  Get.lazyPut(() => FarmSelectionController());
  //Get.lazyPut(() => LoginController());
  Get.put(LoginController());
  Get.lazyPut(() => FilterController());
  Get.lazyPut(() => UserSession());

// Habilitar la persistencia sin conexión
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);

  //SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  /*final AveControl aveControl = Get.put(AveControl());
  final CardControllerH cardControllerH = Get.put(CardControllerH());
  final CardControllerC cardControllerC = Get.put(CardControllerC());
  final CardController cardController = Get.put(CardController());
  final AuthController authController = Get.put(AuthController());
  final InvitationSystem invitationSystem = Get.put(InvitationSystem());*/

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gallinero',
      home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              print('snapshot ${snapshot.connectionState} +++++++++++++++++++----------------------------           en myapp');
              if (snapshot.connectionState == ConnectionState.active) {
                User? user = snapshot.data;
                print('user ${user} +++++++++++++++++++----------------------------           en myapp');
                if (user == null) {
                  return LoginPage();
                } else {
                  return BottomNavBar();
                }
              } else {
                return const CircularProgressIndicator();
              }
            }, 
          ),
      /*SafeArea(
        top: false,
        child: Obx(() {
          if (authController.authState.value.isAuthenticated) {
            print('authController.authState.value.isAuthenticated ${authController.authState.value.isAuthenticated}');
            return BottomNavBar();
          } else {
            print('authController.authState.value.isAuthenticated ${authController.authState.value.isAuthenticated}');
            return LoginPage();
          }
        }),*/
        /**/
      navigatorObservers: [GetObserver()],
      initialBinding: BindingsBuilder.put(() => NavegacionVar()),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
    );
  }
}

