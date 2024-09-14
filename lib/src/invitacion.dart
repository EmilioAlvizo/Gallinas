import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'comida.dart';
import 'control.dart';
import 'fuente.dart';
import 'gallinas.dart';
import 'huevos.dart';
import 'sqlite.dart';
import 'snackbar_utils.dart';

class InvitationSystem extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> inviteUser(String invitedUserEmail,
      {List<String>? collectionsToShare}) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('No user logged in');

      print('Current user: ${currentUser.email}');
      print('Inviting user: $invitedUserEmail');

      // Verificar si ya existe una invitación pendiente
      QuerySnapshot existingInvitations = await FirebaseFirestore.instance
          .collection('invitaciones')
          .where('ownerUid', isEqualTo: currentUser.uid)
          .where('invitedEmail', isEqualTo: invitedUserEmail)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingInvitations.docs.isNotEmpty) {
        print('Ya existe una invitación pendiente para $invitedUserEmail');
        SnackbarUtils.showWarning(
            'Ya existe una invitación pendiente para $invitedUserEmail');
        // Aquí puedes lanzar una excepción o manejar el caso como prefieras
        return;
        //throw Exception('Ya existe una invitación pendiente para este usuario');
      }

      // Si no se especifican colecciones, compartir todas
      List<String> allCollections = [
        'sumas',
        'restas',
        'sumasH',
        'restasH',
        'sumasC'
      ];
      List<String> collectionsToShareFinal =
          collectionsToShare ?? allCollections;

      print('Collections to share: ${collectionsToShareFinal.join(", ")}');

      // Crear una invitación en la colección 'invitaciones'
      DocumentReference docRef =
          await FirebaseFirestore.instance.collection('invitaciones').add({
        'ownerUid': currentUser.uid,
        'ownerEmail': currentUser.email,
        'invitedEmail': invitedUserEmail,
        'collections': collectionsToShareFinal,
        'permissions': [
          'view',
          'edit'
        ], // Puedes ajustar esto según tus necesidades
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Invitación creada con ID: ${docRef.id}');

      print(
          'Invitación enviada a $invitedUserEmail para compartir ${collectionsToShareFinal.join(", ")}');
      // crear el documento en 'compartidos'
      // Referencia a la colección 'compartidos'
      CollectionReference compartidos =
          FirebaseFirestore.instance.collection('compartidos');

      try {
        // Intentar obtener el documento existente
        DocumentSnapshot docSnapshot =
            await compartidos.doc(currentUser.uid).get();
        print('docSnapshot: ${docSnapshot}');

        if (docSnapshot.exists) {
          // El documento existe, actualizar el campo 'invitedEmail'
          print('si existe');

          await compartidos.doc(currentUser.uid).update({
            'invitedEmail': FieldValue.arrayUnion([invitedUserEmail])
          });
          print('Documento actualizado con éxito');
        } else {
          print('no existe');

          // El documento no existe, crearlo
          await compartidos.doc(currentUser.uid).set({
            'owner': currentUser.uid,
            'ownerEmail': currentUser.email,
            'sharedWith': [],
            'invitedEmail': [invitedUserEmail],
            'permissions': ['view', 'edit'],
          });
          print('Documento creado con éxito');
        }
      } catch (e) {
        print('Error al crear/actualizar el documento: $e');
      }
    } catch (e) {
      print('Error en inviteUser: $e');
      rethrow;
    }
  }

  Future<void> checkAndProcessInvitations() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return print('No user logged in');
    } else {
      try {
        print('Checking invitations for user: ${currentUser.email}');

        // Buscar invitaciones pendientes para el email del usuario actual
        var invitationsQuery = await FirebaseFirestore.instance
            .collection('invitaciones')
            .where('invitedEmail', isEqualTo: currentUser.email)
            .where('status', isEqualTo: 'pending')
            .get();

        print('Found ${invitationsQuery.docs.length} pending invitations');

        for (var doc in invitationsQuery.docs) {
          var invitationData = doc.data();
          print('Processing invitation: ${doc.id}');

          // usando firebase Crear un nuevo documento en 'compartidos' cuyo nombre sea el propietario original del recurso
          // y que tenga los datos del invitado y las colecciones compartidas
          await FirebaseFirestore.instance
              .collection('compartidos')
              .doc(invitationData['ownerUid'])
              .update({
            'sharedWith': FieldValue.arrayUnion([currentUser.uid])
          });
          // Actualizar el estado de la invitación a 'accepted'
          await doc.reference.update({'status': 'accepted'});
          print('Invitation ${doc.id} processed successfully');
        }
      } catch (e) {
        print('Error in checkAndProcessInvitations: $e');
        rethrow;
      }
    }
  }

  Future<void> checkAndUpdateInvitation() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    // Buscar invitaciones pendientes para el email del usuario actual
    var invitationsQuery = await FirebaseFirestore.instance
        .collection('invitaciones')
        .where('invitedEmail', isEqualTo: currentUser?.email)
        .where('status', isEqualTo: 'pending')
        .get();
    print('Found ${invitationsQuery.docs.length} pending invitations');

    // If a document is found
    if (invitationsQuery.docs.isNotEmpty) {
      // Reference to the compartidos collection
      CollectionReference compartidos =
          FirebaseFirestore.instance.collection('compartidos');
      for (var doc in invitationsQuery.docs) {
        var invitationData = doc.data();
        // ver si existe un documento en compartidos con el mismo nombre que el propietario original del recurso
        print('ouner ${invitationData['ownerUid']} id');
        DocumentSnapshot existe_compartidos =
            await compartidos.doc(invitationData['ownerUid']).get();
        if (existe_compartidos.exists) {
          print('Documento encontrado');

          // Actualizar el documento
          await FirebaseFirestore.instance
              .collection('compartidos')
              .doc(invitationData['ownerUid'])
              .update({
            'sharedWith': FieldValue.arrayUnion([currentUser?.uid]),
            'invitedEmail': FieldValue.arrayUnion([currentUser?.email])
          });

          print('Documento actualizado con éxito');
        } else {
          await FirebaseFirestore.instance
              .collection('compartidos')
              .doc(invitationData['ownerUid'])
              .set({
            'owner': invitationData['ownerUid'],
            'ownerEmail': invitationData['ownerEmail'],
            'sharedWith': [currentUser?.uid],
            'invitedEmail': [currentUser?.email],
            'collections': invitationData['collections'],
            'permissions': invitationData['permissions'],
          });
          print('compartidos creado');
        }
        // Actualizar el estado de la invitación a 'accepted'
        await doc.reference.update({'status': 'accepted'});
        print('Invitation ${doc.id} processed successfully');
      }
    }
  }

  Future<void> acceptInvitation(
      String invitationId, String compartidosId) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    print('currentUser ${currentUser?.uid}');
    print('invitationId ${invitationId}');
    print('compartidosId ${compartidosId}');
    try {
      // Obtener la invitación
      DocumentSnapshot invitation =
          await _firestore.collection('invitaciones').doc(invitationId).get();

      if (!invitation.exists) {
        throw Exception('Invitation not found');
      }

      // Actualizar los permisos en el documento de datos
      await _firestore.collection('compartidos').doc(compartidosId).update({
        'sharedWith': FieldValue.arrayUnion([currentUser?.uid]),
      });

      // Actualizar el estado de la invitación
      await _firestore
          .collection('invitaciones')
          .doc(invitationId)
          .update({'status': 'accepted'});

      Get.snackbar('Éxito', 'Invitación aceptada');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo aceptar la invitación: $e');
    }
  }

  Future<void> deleteInvitation(
      String invitationId, String compartidosId, String? usuario) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    try {
      print('invitationId $invitationId');
      print('compartidosId $compartidosId');
      print('usuario $usuario');
      // Obtener la referencia a la invitación
      DocumentReference invitationRef =
          _firestore.collection('invitaciones').doc(invitationId);

      // Eliminar la invitación
      await invitationRef.delete();

      // Actualizar el documento en la colección 'compartidos'
      await _firestore.collection('compartidos').doc(compartidosId).update({
        'sharedWith': FieldValue.arrayRemove([currentUser?.uid]),
        'invitedEmail': FieldValue.arrayRemove([currentUser?.email])
      });

      print(
          'Invitación eliminada y documento compartido actualizado con éxito');
    } catch (e) {
      print('Error al eliminar la invitación: $e');
      throw e;
    }
  }

  Future<void> deleteInvitation2(
      String invitationId, String invitedEmail) async {
    try {
      // Eliminar la invitación
      await _firestore.collection('invitaciones').doc(invitationId).delete();

      // Actualizar el documento en la colección 'compartidos'
      DocumentReference compartidosRef =
          _firestore.collection('compartidos').doc(_auth.currentUser?.uid);
      DocumentSnapshot compartidosDoc = await compartidosRef.get();

      if (compartidosDoc.exists) {
        Map<String, dynamic> data =
            compartidosDoc.data() as Map<String, dynamic>;
        List<String> invitedEmails =
            List<String>.from(data['invitedEmail'] ?? []);

        invitedEmails.remove(invitedEmail);

        if (invitedEmails.isEmpty) {
          // Si no quedan emails invitados, eliminar el documento
          await compartidosRef.delete();
        } else {
          // Actualizar el documento con la lista actualizada
          await compartidosRef.update({'invitedEmail': invitedEmails});
        }
      }

      //Get.snackbar('Éxito', 'Invitación eliminada con éxito');
      SnackbarUtils.showSuccess('Invitación eliminada con éxito');
    } catch (e) {
      print('Error al eliminar la invitación: $e');
      SnackbarUtils.showError('No se pudo eliminar la invitación');
      //Get.snackbar('Error', 'No se pudo eliminar la invitación');
    }
  }

  Stream<QuerySnapshot> getInvitations() {
    return _firestore
        .collection('invitaciones')
        .where('invitedEmail', isEqualTo: _auth.currentUser?.email)
        .snapshots();
    //.where('status', isEqualTo: 'pending')
    //.snapshots();
  }

  Future<bool> checkPermission(String dataId) async {
    try {
      DocumentSnapshot dataDoc =
          await _firestore.collection('data').doc(dataId).get();

      if (!dataDoc.exists) {
        return false;
      }

      Map<String, dynamic> data = dataDoc.data() as Map<String, dynamic>;
      List<String> sharedWith = List<String>.from(data['sharedWith'] ?? []);

      return sharedWith.contains(_auth.currentUser?.uid);
    } catch (e) {
      print('Error checking permission: $e');
      return false;
    }
  }
}

class FarmSelectionController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserSession userSession = Get.find();
  final CardController gallinas = Get.find();
  final CardControllerH huevos = Get.find();
  final CardControllerC comida = Get.find();
  final RxList<Map<String, dynamic>> farms = <Map<String, dynamic>>[].obs;
  final RxString selectedDataType =
      'sumas'.obs; // Por defecto, seleccionamos 'sumas'
  final NavegacionVar navegacionVar = Get.find();

  loadFarms(User? user) async {
    print('loadFarms');

    // Cargar la granja personal del usuario
    print('userId $user');
    print('userId ${user?.uid}');
    print('userId ${user?.email}');
    farms.clear();
    farms.add({
      'id': user?.uid,
      'name': 'Mi Granja',
      'location': user?.email,
      'icon': Icons.home,
    });
    print('paso 2');
    // Cargar las invitaciones a otras granjas (esto requiere una implementación adicional en tu sistema)
    // Por ahora, asumiremos que las invitaciones se almacenan en una colección separada
    QuerySnapshot invitations = await _firestore
        .collection('compartidos')
        .where('sharedWith', arrayContains: user?.uid)
        .get();
    print('paso 3 ${invitations}');

    if (invitations.docs.isNotEmpty) {
      print('paso 4');
      for (var doc in invitations.docs) {
        farms.add({
          'id': doc['owner'],
          'name': 'Otro',
          'location': doc['ownerEmail'],
          'icon': Icons.share,
        });
      }
    }
    print(
        ' este es farms: ${farms}                                    +++++++++++++++');
  }

  void selectFarm(String farmId) {
    try {
      userSession.usuarioSeleccionado.value = farmId;
      navegacionVar.limpiarVar();
      gallinas.loadAllData(farmId);
      huevos.loadAllData(farmId);
      comida.loadAllData(farmId);
      //navegacionVar.cargarDatos2(farmId);
      Get.snackbar('Éxito', 'Granja seleccionada');
    } catch (e, stackTrace) {
      print('error en $e');
      print('Stack trace: $stackTrace');
    }
    // Aquí puedes agregar lógica adicional, como cambiar la vista o cargar datos específicos
  }

  void selectDataType(String dataType) {
    selectedDataType.value = dataType;
    // Aquí puedes agregar lógica para cargar los datos específicos del tipo seleccionado
  }
}

class FarmSelectionScreen extends StatelessWidget {
  final FarmSelectionController controller = Get.find();
  final UserSession userSession = Get.find();

  final controlador;
  FarmSelectionScreen({super.key, required this.controlador});

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25),
      child: Column(
        children: [
          Obx(
            () => Row(
              children: [
                ChoiceChip(
                  label: Text('Granjas',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: controlador.botonIndex.value == 0
                              ? customColors.texto1
                              : const Color(0xff828282))),
                  backgroundColor: customColors.boton,
                  selectedColor: const Color(0xffE59A54),
                  checkmarkColor: controlador.botonIndex.value == 0
                      ? customColors.texto1
                      : const Color(0xff828282),
                  padding: const EdgeInsets.only(
                      top: 10, bottom: 10, right: 10, left: 10),
                  side: const BorderSide(style: BorderStyle.none),
                  selected: controlador.botonIndex.value == 0,
                  onSelected: (selected) {
                    controlador.botonIndex.value = 0;
                    controlador.pageController4.jumpToPage(0);
                  },
                ),
                const Padding(padding: EdgeInsets.only(right: 10.0)),
                ChoiceChip(
                  label: Text('Recibidas',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: controlador.botonIndex.value == 1
                              ? customColors.texto1
                              : const Color(0xff828282))),
                  backgroundColor: customColors.boton,
                  side: const BorderSide(style: BorderStyle.none),
                  selectedColor: const Color(0xffE59A54),
                  checkmarkColor: controlador.botonIndex.value == 1
                      ? customColors.texto1
                      : const Color(0xff828282),
                  padding: const EdgeInsets.only(
                      top: 10, bottom: 10, right: 10, left: 10),
                  selected: controlador.botonIndex.value == 1,
                  onSelected: (selected) {
                    controlador.botonIndex.value = 1;
                    controlador.pageController4.jumpToPage(1);
                  },
                ),
                const Padding(padding: EdgeInsets.only(right: 10.0)),
                ChoiceChip(
                  label: Text('Enviadas',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: controlador.botonIndex.value == 2
                              ? customColors.texto1
                              : const Color(0xff828282))),
                  backgroundColor: customColors.boton,
                  side: const BorderSide(style: BorderStyle.none),
                  selectedColor: const Color(0xffE59A54),
                  checkmarkColor: controlador.botonIndex.value == 2
                      ? customColors.texto1
                      : const Color(0xff828282),
                  padding: const EdgeInsets.only(
                      top: 10, bottom: 10, right: 10, left: 10),
                  selected: controlador.botonIndex.value == 2,
                  onSelected: (selected) {
                    controlador.botonIndex.value = 2;
                    controlador.pageController4.jumpToPage(2);
                  },
                ),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.only(top: 25.0)),
          // aqui pon un boton para selecionar el tipo de ave o para ver todas
          Obx(() => _getBody(controlador.botonIndex.value, context)),
        ],
      ),
    );
  }

  Widget _getBody(int index, BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    final CardController cardController = Get.find();
    return Expanded(
      child: PageView(
        controller: controlador.pageController4,
        onPageChanged: controlador.onPageChanged,
        children: [
          Stack(alignment: Alignment.center, children: [
            Column(
              children: [
                //poner un boton que ejecute la funcion getDatabaseUsers y muestre el resultado en un texto
                /*ElevatedButton(
                  onPressed: () async {
                    var datos = await cardController.sumas;
                    //await DatabaseHelper.instance.getSumas(userSession.usuarioSeleccionado.value!);

                    List<String> userEmails =
                        await DatabaseHelper.instance.getDatabaseUsers();
                    print('principal: ${UserSession.currentUserId}');
                    print('datos: $datos');
                    // Aquí puedes mostrar los correos electrónicos en un Text widget o realizar otras acciones necesarias
                    Get.snackbar('Correos electrónicos', userEmails.join(', '));
                    duration:
                    Duration(seconds: 5); // Duración del Snackbar en segundos
                  },
                  child: const Icon(Icons.send_rounded),
                ),*/
                /*
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DatabaseViewer(
                            userId: userSession.usuarioSeleccionado.value!),
                      ),
                    );
                  },
                  child: Text('Ver base de datos'),
                ),*/
                Expanded(
                  child: Obx(() {
                    if (controller.farms.isEmpty) {
                      return const Center(
                          child: Text('No hay granjas disponibles'));
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.all(0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        childAspectRatio: 3,
                        crossAxisSpacing: 1,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: controller.farms.length,
                      itemBuilder: (context, index) {
                        final farm = controller.farms[index];
                        return Obx(
                          () => Card(
                            color: userSession.usuarioSeleccionado.value ==
                                    farm['id']
                                ? const Color(0xffE59A54)
                                : customColors.card,
                            child: InkWell(
                              highlightColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              onTap: () => controller.selectFarm(farm['id']),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Stack(
                                  children: [
                                    // Nombre en la parte superior izquierda
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        farm['name'],
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: userSession.usuarioSeleccionado
                                                      .value ==
                                                  farm['id']
                                              ? customColors.texto1
                                              : customColors.texto4,
                                        ),
                                      ),
                                    ),
                                    // Icono en la parte derecha
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Icon(
                                        farm['icon'],
                                        size: 30,
                                        color: userSession.usuarioSeleccionado
                                                    .value ==
                                                farm['id']
                                            ? customColors.texto1
                                            : customColors.iconos,
                                      ),
                                    ),
                                    // Ubicación e ID en la parte inferior izquierda
                                    Align(
                                      alignment: Alignment.bottomLeft,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            farm['location'],
                                            style: TextStyle(
                                              color: userSession
                                                          .usuarioSeleccionado
                                                          .value ==
                                                      farm['id']
                                                  ? customColors.texto1
                                                  : customColors.texto3,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            farm['id'],
                                            style: TextStyle(
                                              color: userSession
                                                          .usuarioSeleccionado
                                                          .value ==
                                                      farm['id']
                                                  ? customColors.texto1
                                                  : customColors.texto3,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ]),
          Stack(alignment: Alignment.center, children: [
            InvitationsScreen(),
            Positioned(
              bottom: 10,
              right: 0,
              child: FloatingActionButton(
                backgroundColor: const Color(0xff03dac6),
                foregroundColor: Colors.black,
                mini: true,
                onPressed: () {
                  mostrarDialogo(context);
                },
                child: const Icon(Icons.send_rounded),
              ),
            )
            /*Container(child: Column(children: [_MostrarSumas()])),
            
            )*/
          ]),
          Stack(alignment: Alignment.center, children: [
            SentInvitationsScreen(),
          ])
        ],
      ),
    );
  }
}

void mostrarDialogo(BuildContext context) {
  final _formKey = GlobalKey<FormState>();
  final InvitationSystem invitationSystem = Get.find();
  TextEditingController emailC = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Invitar usuario'),
        content: SingleChildScrollView(
          child: Container(
            width: double.maxFinite,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: emailC,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    autofillHints: [AutofillHints.email],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Email',
                      helperText: '* requerido',
                      hintText: 'Ingresa tu dirección de email',
                      prefixIcon: Icon(Icons.email),
                      filled: false,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa un email';
                      }
                      // Expresión regular para validar el formato del email
                      final emailRegex =
                          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Ingresa un email válido';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
          Builder(builder: (BuildContext context) {
            return ElevatedButton(
              child: const Text('Agregar'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  invitationSystem.inviteUser(emailC.text);
                  Navigator.of(context).pop();
                } else {
                  print('Hay campos sin completar');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: const Text('Hay campos sin completar'),
                      action: SnackBarAction(
                        label: 'Cerrar',
                        onPressed: () {},
                      ),
                    ),
                  );
                }
              },
            );
          }),
        ],
      );
    },
  );
}

class InvitationsScreen extends StatelessWidget {
  final UserSession userSession = Get.find();

  @override
  Widget build(BuildContext context) {
    final InvitationSystem invitationSystem = Get.find<InvitationSystem>();

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: invitationSystem.getInvitations(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              return GestureDetector(
                onTap: () {
                  if (data['status'] == 'pending') {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Aceptar invitación'),
                          content: Text(
                              '¿Deseas aceptar la invitación de ${data['ownerEmail']}?'),
                          actions: <Widget>[
                            TextButton(
                              child: Text('Cancelar'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: Text('Aceptar'),
                              onPressed: () {
                                invitationSystem.acceptInvitation(
                                    document.id, data['ownerUid']);
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Eliminar invitación'),
                        content: Text(
                            '¿Estás seguro de que deseas eliminar esta invitación?'),
                        actions: <Widget>[
                          TextButton(
                            child: Text('Cancelar'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: Text('Eliminar'),
                            onPressed: () {
                              // Aquí debes implementar la lógica para eliminar la invitación
                              invitationSystem.deleteInvitation(
                                  document.id,
                                  data['ownerUid'],
                                  userSession.usuarioSeleccionado.value);
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Card(
                  margin: EdgeInsets.all(8.0),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invitación de:\n${data['ownerEmail']}',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            //SizedBox(height: 8),
                            //Text('Para acceder a ${data['ownerUid']}'), el simbolo paara saltar de linea es: \n
                          ],
                        ),
                        Icon(
                          data['status'] == 'pending'
                              ? Icons.hourglass_empty_rounded
                              : Icons.check_rounded,
                          color: data['status'] == 'pending'
                              ? Colors.orange
                              : Colors.green,
                          size: 30,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class SentInvitationsScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final InvitationSystem invitationSystem = Get.find<InvitationSystem>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invitaciones Enviadas'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('invitaciones')
            .where('ownerUid', isEqualTo: _auth.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              return GestureDetector(
                onTap: () {
                  _showDeleteDialog(context, document.id, data['invitedEmail']);
                },
                child: Card(
                  margin: EdgeInsets.all(8.0),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invitación para:\n${data['invitedEmail']}',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Icon(
                          data['status'] == 'pending'
                              ? Icons.hourglass_empty_rounded
                              : Icons.check_rounded,
                          color: data['status'] == 'pending'
                              ? Colors.orange
                              : Colors.green,
                          size: 30,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, String invitationId, String invitedEmail) {
        
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Eliminar invitación'),
          content:
              Text('¿Estás seguro de que deseas eliminar esta invitación?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Eliminar'),
              onPressed: () {
                invitationSystem.deleteInvitation2(invitationId, invitedEmail);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
