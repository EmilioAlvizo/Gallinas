import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math';
import 'dart:collection';
import 'package:shared_preferences/shared_preferences.dart';

import 'comida.dart';
import 'fuente.dart';
import 'gallinas.dart';
import 'huevos.dart';
import 'opciones.dart';
import 'texto.dart';
import 'sqlite.dart';

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DateRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;

  @override
  String toString() => 'DateRange(start: $start, end: $end)';

  int get duracionTotal {
    return end.difference(start).inDays;
  }
}

class CalculoController extends GetxController {
  final CardControllerH huevosController = Get.find();
  final CardControllerC alimentosController = Get.find();
  final CardController gallinasController = Get.find();
  final NavegacionVar navegacionVar = Get.find();
  final AveControl aveControl = Get.find();

  var datosEconomicos = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Escuchar cambios en las listas de sumas de alimentos y gallinas
    ever(huevosController.sumas, (_) => actualizarDatosEconomicos());
    ever(alimentosController.sumas, (_) => actualizarDatosEconomicos());
    ever(gallinasController.sumas, (_) => actualizarDatosEconomicos());
    ever(gallinasController.restas, (_) => actualizarDatosEconomicos());
    ever(aveControl.selectedAveFilter, (_) => actualizarDatosEconomicos());
    // Inicializar cálculos
    actualizarDatosEconomicos();
  }

  double calcularPromedioPonderadoGallinas(
      DateTime fechaInicio, DateTime fechaFin) {
    int totalDias = 0;
    int totalGallinaDias = 0;
    //int gallinas2 = gallinasController.calcularTotal2()[0].toInt();

    List<DateTime> fechas = [
      ...gallinasController.filteredSumas.map((s) => s.fecha),
      ...gallinasController.filteredRestas.map((r) => r.fecha)
    ];

    int gallinas = gallinasController.filteredSumas
            .where((r) =>
                r.fecha.isBefore(fechaInicio) ||
                r.fecha.isAtSameMomentAs(fechaInicio))
            .fold(0, (sum, item) => sum + item.avesNuevas) -
        gallinasController.filteredRestas
            .where((r) =>
                r.fecha.isBefore(fechaInicio) ||
                r.fecha.isAtSameMomentAs(fechaInicio))
            .fold(0, (sum, item) => sum + item.avesMuertas);
    //print('gallinas2 $gallinas2');
    //print('fechaInicio $fechaInicio - fechaFin $fechaFin');
    //print('gallinas $gallinas');
    //print('fechas $fechas');
    fechas = fechas
        .where(
            (fecha) => fecha.isAfter(fechaInicio) && fecha.isBefore(fechaFin))
        .toList();
    fechas.sort((a, b) => a.compareTo(b));
    //print('fechas $fechas');
    DateTime? fechaActual = fechaInicio;
    //print('fechaActual $fechaActual');
    for (var fecha in fechas) {
      //print('fecha for $fecha');
      if (fechaActual != null) {
        int dias = fecha.difference(fechaActual).inDays;
        //print('dias $dias');
        totalDias += dias;
        totalGallinaDias += gallinas * dias;
        //print('totalDias $totalDias');
        //print('totalGallinaDias $totalGallinaDias');
      }
      gallinas += gallinasController.filteredSumas
          .where((s) => s.fecha == fecha)
          .fold(0, (sum, item) => sum + item.avesNuevas);
      //print('gallinas for $gallinas');
      gallinas -= gallinasController.filteredRestas
          .where((r) => r.fecha == fecha)
          .fold(0, (sum, item) => sum + item.avesMuertas);
      //print('gallinas for $gallinas');
      fechaActual = fecha;
    }

    if (fechaActual != null && fechaActual.isBefore(fechaFin)) {
      int dias = fechaFin.difference(fechaActual).inDays;
      //print('dias $dias');
      totalDias += dias;
      totalGallinaDias += gallinas * dias;
      //print('totalDias $totalDias');
      //print('totalGallinaDias $totalGallinaDias');
    }
    //print('return ${totalGallinaDias / totalDias}');
    return totalDias > 0 ? totalGallinaDias / totalDias : gallinas.toDouble();
  }

  void actualizarDatosEconomicos() {
    print('actualizarDatosEconomicos');
    List<Map<String, dynamic>> resultados = [];
    if (alimentosController.filteredSumas.isEmpty) return;

    double costoTotal = 0;
    double consumoTotal = 0;

    // Agrupar las compras de alimentos por periodos
    var comprasAgrupadas = SplayTreeMap<DateRange, List<SumaC>>(
      (a, b) {
        int cmp = a.start.compareTo(b.start);
        if (cmp == 0) {
          cmp = a.end.compareTo(b.end);
        }
        return cmp;
      },
    );

    for (var compra in alimentosController.filteredSumas) {
      DateRange key =
          DateRange(compra.fecha.add(Duration(days: 1)), compra.fechafinal);
      if (!comprasAgrupadas.containsKey(key)) {
        comprasAgrupadas[key] = [];
      }
      comprasAgrupadas[key]!.add(compra);
    }

    comprasAgrupadas.forEach((rango, compras) {
      print('$rango \t $compras');
      // Calcular costo y consumo total para este periodo
      double costoPeriodo = 0;
      double consumoPeriodo = 0;
      for (var compra in compras) {
        costoPeriodo += compra.precio!;
        consumoPeriodo += compra.cantidad;
      }
      costoTotal += costoPeriodo;
      consumoTotal += consumoPeriodo;

      double promedioGallinas =
          calcularPromedioPonderadoGallinas(rango.start, rango.end);

      int huevos = huevosController.filteredSumas
          .where((r) =>
              (r.fecha.isBefore(rango.end) ||
                  r.fecha.isAtSameMomentAs(rango.end)) &&
              (r.fecha.isAfter(rango.start) ||
                  r.fecha.isAtSameMomentAs(rango.start)))
          .fold(0, (sum, item) => sum + item.buenos + item.rotos);

      resultados.add({
        'fechaInicio': rango.start,
        'fechaFin': rango.end,
        'costoTotal': costoPeriodo,
        'consumoTotal': consumoPeriodo,
        'costoPromedioPorKg':
            costoTotal / (consumoTotal == 0 ? 1 : consumoTotal),
        'promedioPonderadoGallinas': promedioGallinas,
        'consumodiario': consumoPeriodo / rango.duracionTotal,
        'consumodiarioporgallina':
            (consumoPeriodo / rango.duracionTotal) / promedioGallinas,
        'huevos': huevos,
        'puntoequilibrio': costoPeriodo / huevos,
      });
    });
    resultados.sort((a, b) => b['fechaInicio'].compareTo(a['fechaInicio']));
    datosEconomicos.value = resultados;
  }
}

final FirebaseAuth _auth = FirebaseAuth.instance;

void addObjeto(resta, String nombre) async {
  final UserSession userSession = Get.find();
  String user = userSession.usuarioSeleccionado.value!;
  if (user != null) {
    //print();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user)
        .collection(nombre)
        .doc(resta.id)
        .set(resta.toJson()); //.add(resta.toJson());
  }
}

void removeObjeto(resta, String nombre) {
  final UserSession userSession = Get.find();
  String user = userSession.usuarioSeleccionado.value!;
  if (user != null) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(user)
        .collection(nombre)
        .doc(resta.id)
        .delete();
  }
}

void updateObjeto(oldResta, newResta, String nombre) async {
  final UserSession userSession = Get.find();
  String user = userSession.usuarioSeleccionado.value!;
  if (user != null) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user)
        .collection(nombre)
        .doc(oldResta.id)
        .update(newResta.toJson());
  }
}

Future<void> actualizarSumas(List<dynamic> sumas, String texto) async {
  final NavegacionVar navegacionVar = Get.find<NavegacionVar>();

  try {
    String? uid;
    uid ??= await navegacionVar.getSavedUserUID();

    final directorio = await getApplicationDocumentsDirectory();
    //print('*********************** $directorio');
    final file = File('${directorio.path}/$uid.json');
    //print('*********************** $file');
    final data = await file.readAsString();
    //print('*********************** $data');
    final jsonData = jsonDecode(data);
    //print('*********************** $jsonData');
    jsonData[texto] = sumas.map((p) => p.toJson()).toList();
    print('actualizar $texto');
    //print(jsonData);
    await file.writeAsString(jsonEncode(jsonData));
  } catch (e) {
    print('Error al actualizar las $texto: $e');
  }
}

Future<void> actualizarRestas(List<dynamic> restas, String texto) async {
  final NavegacionVar navegacionVar = Get.find<NavegacionVar>();
  try {
    String? uid;
    uid ??= await navegacionVar.getSavedUserUID();
    final directorio = await getApplicationDocumentsDirectory();
    final file = File('${directorio.path}/$uid.json');
    final data = await file.readAsString();
    final jsonData = jsonDecode(data);
    jsonData[texto] = restas.map((a) => a.toJson()).toList();
    print('actualizar $texto');
    print(jsonData);
    print(file);
    await file.writeAsString(jsonEncode(jsonData));
  } catch (e) {
    print('Error al actualizar las $texto: $e');
  }
}

class NavegacionVar extends GetxController with WidgetsBindingObserver {
  Rx<int> tabIndex = 0.obs;
  Rx<int> botonIndex = 0.obs;
  RxBool bool1 = false.obs;
  final bool4 = TextEditingController().obs;

  PageController pageController = PageController(keepPage: false);
  PageController pageController2 = PageController(keepPage: false);
  PageController pageController3 = PageController(keepPage: false);
  PageController pageController4 = PageController(keepPage: false);
  void onPageChanged(int index) {
    print('df $index');
    botonIndex.value = index;
  }

  RxBool showNombre = true.obs;
  final showConsumo = true.obs;
  final showVentas = true.obs;
  final showRotos = true.obs;
  RxBool showOtros = true.obs;
  final showIngreso = true.obs;
  final showTotales = true.obs;

  final CardController cardController = Get.find();
  final CardControllerH cardControllerH = Get.find();
  final CardControllerC cardControllerC = Get.find();
  //final FarmSelectionController farmSelectionController = Get.find();

  Map<String, RxList<dynamic>> getDataMap() {
    return {
      'sumas': cardController.sumas,
      'restas': cardController.restas,
      'sumasH': cardControllerH.sumas,
      'restasH': cardControllerH.restas,
      'sumasC': cardControllerC.sumas,
    };
  }

  limpiarVar() {
    print('limpiando variables');
    cardController.sumas.clear();
    cardController.restas.clear();
    cardController.totales.clear();
    cardControllerH.sumas.clear();
    cardControllerH.restas.clear();
    cardControllerH.totales.clear();
    cardControllerC.sumas.clear();
    cardControllerC.totales.clear();
    print('variables limpias');
  }

  Future<void> inicio(User? user) async {
    Map<String, RxList<dynamic>> dataMap = getDataMap();
    print('ssssssssssssssssssssssssssssssssssssssssssssssssss');
    print('sssssssssssssfffffffffffffffffffffssssssssssssssssssssss');
    print('sssssssssssssssssssssssssssssssssssssssssssssssss');
    WidgetsBinding.instance.addObserver(this);
    await limpiarVar();
    await cardController.loadAllData(user!.uid);
    await cardControllerH.loadAllData(user.uid);
    await cardControllerC.loadAllData(user.uid);
    //await cargarDatos(user);
    //await loadFromFirebase2(dataMap);
    //await guardarDatos();
    //farmSelectionController.loadFarms();
  }

  @override
  void onClose() async {
    Map<String, RxList<dynamic>> dataMap = getDataMap();
    print('zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz');
    print('zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz');
    print('zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz');
    WidgetsBinding.instance.removeObserver(this);
    //await guardarDatos();
    //await syncWithFirebase(dataMap);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    Map<String, RxList<dynamic>> dataMap = getDataMap();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      print('cacacacacacacacacacacacacaccacaacacac');
      print('cacacacacacacacacacacacacaccaacacacacacacac');
      print('zzzzzzzzcacacacacacacacacacacacacaccacacacacaczzzzzzzzz');
      //await guardarDatos();
      //await syncWithFirebase(dataMap);
    }
  }

  syncWithFirebase(Map<String, List<dynamic>> dataMap) async {
    print('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    print('                           syncWithFirebase                   ');
    print('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    try {
      User? user = _auth.currentUser;
      print('                user: $user           ');
      if (user != null) {
        WriteBatch batch = FirebaseFirestore.instance.batch();
        dataMap.forEach((collectionName, objects) {
          for (var objeto in objects) {
            DocumentReference docRef = FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection(collectionName)
                .doc(objeto.id);
            batch.set(docRef, objeto.toJson());
          }
        });
        await batch.commit();
      }
      print('==========================================================');
      print(
          '               datos sincronizados (syncWithFirebase)                  ');
      print('==========================================================');
    } catch (e, stackTrace) {
      print('==========================================================');
      print('                   error syncWithFirebase $e                  ');
      print('                Stack trace: $stackTrace           ');
      print('==========================================================');
    }
  }

  loadFromFirebase(objeto, String nombre) async {
    try {
      print('INICIA     ++++++++    loadFromFirebase');
      User? user = _auth.currentUser;
      if (user != null) {
        var querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection(nombre)
            .get();
        if (nombre == 'sumas') {
          print('----- es una suma');
          var loadedAnimales = querySnapshot.docs
              .map((doc) => Suma.fromJson(doc.data()))
              .toList();
          print('loadedAnimales $loadedAnimales');
          print('objeto.value ${objeto.value}');
          objeto.value = loadedAnimales;
          print('objeto.value ${objeto.value}');
          objeto.forEach((suma) => cardController.calcularTotalSuma(suma));
          cardController.ordenarCronologicamente(objeto);
        } else if (nombre == 'restas') {
          print('----- es una restas');
          var loadedAnimales = querySnapshot.docs
              .map((doc) => Resta.fromJson(doc.data()))
              .toList();
          objeto.value = loadedAnimales;
          objeto.forEach((resta) => cardController.calcularTotalResta(resta));
          cardController.ordenarCronologicamente(objeto);
        } else if (nombre == 'sumasH') {
          print('----- es una sumasH');
          var loadedAnimales = querySnapshot.docs
              .map((doc) => SumaH.fromJson(doc.data()))
              .toList();
          objeto.value = loadedAnimales;
          objeto.forEach((suma) => cardControllerH.calcularTotalSuma(suma));
          cardControllerH.ordenarCronologicamente(objeto);
        } else if (nombre == 'restasH') {
          print('----- es una restasH');
          var loadedAnimales = querySnapshot.docs
              .map((doc) => RestaH.fromJson(doc.data()))
              .toList();
          objeto.value = loadedAnimales;
          objeto.forEach((resta) => cardControllerH.calcularTotalResta(resta));
          cardControllerH.ordenarCronologicamente(objeto);
        } else if (nombre == 'sumasC') {
          print('----- es una sumasC');
          var loadedAnimales = querySnapshot.docs
              .map((doc) => SumaC.fromJson(doc.data()))
              .toList();
          print('loadedAnimales $loadedAnimales');
          print('objeto.value ${objeto.value}');
          objeto.value = loadedAnimales;
          print('objeto.value ${objeto.value}');
          objeto.forEach((suma) => cardControllerC.calcularTotalC(suma));
          cardControllerC.ordenarCronologicamente(objeto);
        }
        print('fin loadfromfirebase');
        guardarDatos();
      }
    } catch (e) {
      return print('error al loadFromFirebase');
    }
  }

  // Función genérica para crear un objeto a partir de su JSON
  dynamic _getObjectFromJson(Map<String, dynamic> jsonData, String nombre) {
    switch (nombre) {
      case 'sumas':
        return Suma.fromJson(jsonData);
      case 'restas':
        return Resta.fromJson(jsonData);
      case 'sumasH':
        return SumaH.fromJson(jsonData);
      case 'restasH':
        return RestaH.fromJson(jsonData);
      case 'sumasC':
        return SumaC.fromJson(jsonData);
      default:
        throw ArgumentError('Nombre de colección no válido: $nombre');
    }
  }

  loadFromFirebase2(Map<String, RxList<dynamic>> dataMap) async {
    print('**************************************************************');
    print('                       INICIA loadFromFirebase2                   ');
    print('**************************************************************');
    try {
      User? user = FirebaseAuth.instance.currentUser;
      print('855555555555555555555555555 user $user');
      if (user != null) {
        List<Future<QuerySnapshot>> futures = [];
        dataMap.keys.forEach((String nombre) {
          var reference = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection(nombre);

          futures.add(reference
              .get()); // Agregar la operación de lectura a la lista de futuros
        });

        List<QuerySnapshot> snapshots = await Future.wait(
            futures); // Esperar a que se completen todas las operaciones de lectura

        for (int i = 0; i < snapshots.length; i++) {
          var querySnapshot = snapshots[i];
          var nombre = dataMap.keys.elementAt(i);
          var objeto = dataMap[nombre]!;

          List<dynamic> loadedObjects = querySnapshot.docs.map((doc) {
            final data = doc.data();
            if (data is Map<String, dynamic>) {
              return _getObjectFromJson(data, nombre);
            } else {
              throw Exception('El documento no tiene el formato esperado.');
            }
          }).toList();

          switch (nombre) {
            case 'sumas':
              objeto.assignAll(loadedObjects.cast<Suma>());
              cardController.ordenarCronologicamente(objeto);
              break;
            case 'restas':
              objeto.assignAll(loadedObjects.cast<Resta>());
              cardController.ordenarCronologicamente(objeto);
              break;
            case 'sumasH':
              objeto.assignAll(loadedObjects.cast<SumaH>());
              cardController.ordenarCronologicamente(objeto);
              break;
            case 'restasH':
              objeto.assignAll(loadedObjects.cast<RestaH>());
              cardController.ordenarCronologicamente(objeto);
              break;
            case 'sumasC':
              objeto.assignAll(loadedObjects.cast<SumaC>());
              cardController.ordenarCronologicamente(objeto);
              break;
            default:
              throw ArgumentError('Nombre de colección no válido: $nombre');
          }
        }
      }
      print('==========================================================');
      print('      Todas las operaciones han sido completadas!            ');
      print('==========================================================');
    } catch (e, stackTrace) {
      print('==========================================================');
      print('             Error en loadFromFirebase2: $e           ');
      print('                Stack trace: $stackTrace           ');
      print('==========================================================');
    }
  }

  Future<void> loadFromFirebase3(Map<String, RxList<dynamic>> dataMap) async {
    print('**************************************************************');
    print('                       INICIA loadFromFirebase3                   ');
    print('**************************************************************');
    try {
      User? user = FirebaseAuth.instance.currentUser;
      print('999999999999999999999999999999999 user $user');
      if (user != null) {
        List<Future<QuerySnapshot>> futures = [];

        // Cargar datos propios del usuario
        dataMap.keys.forEach((String nombre) {
          var reference = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection(nombre);
          futures.add(reference.get());
        });

        // Cargar datos compartidos
        var sharedReference = FirebaseFirestore.instance
            .collection('compartidos')
            .where('sharedWith', arrayContains: user.uid);
        futures.add(sharedReference.get());

        List<QuerySnapshot> snapshots = await Future.wait(futures);

        // Procesar datos propios del usuario
        for (int i = 0; i < dataMap.length; i++) {
          var querySnapshot = snapshots[i];
          var nombre = dataMap.keys.elementAt(i);
          var objeto = dataMap[nombre]!;

          List<dynamic> loadedObjects = querySnapshot.docs.map((doc) {
            final data = doc.data();
            if (data is Map<String, dynamic>) {
              return _getObjectFromJson(data, nombre);
            } else {
              throw Exception('El documento no tiene el formato esperado.');
            }
          }).toList();

          _assignObjectsToList(nombre, objeto, loadedObjects);
        }

        // Procesar datos compartidos
        var sharedSnapshot = snapshots.last;
        for (var doc in sharedSnapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          var ownerUid = data['owner'];
          var collections = data['collections'] as List<dynamic>;

          for (var collectionName in collections) {
            var sharedDataReference = FirebaseFirestore.instance
                .collection('users')
                .doc(ownerUid)
                .collection(collectionName);

            var sharedDataSnapshot = await sharedDataReference.get();
            var sharedObjects = sharedDataSnapshot.docs.map((doc) {
              final data = doc.data();
              if (data is Map<String, dynamic>) {
                return _getObjectFromJson(data, collectionName);
              } else {
                throw Exception(
                    'El documento compartido no tiene el formato esperado.');
              }
            }).toList();

            _assignObjectsToList(
                collectionName, dataMap[collectionName]!, sharedObjects);
          }
        }

        print('==========================================================');
        print(
            '      Todas las operaciones han sido completadas! (loadFromFirebase3)            ');
        print('==========================================================');
      }
    } catch (e, stackTrace) {
      print('==========================================================');
      print('             Error en loadFromFirebase3: $e           ');
      print('                Stack trace: $stackTrace           ');
      print('==========================================================');
    }
  }

  void _assignObjectsToList(
      String nombre, RxList<dynamic> objeto, List<dynamic> loadedObjects) {
    switch (nombre) {
      case 'sumas':
        objeto.assignAll(loadedObjects.cast<Suma>());
        break;
      case 'restas':
        objeto.assignAll(loadedObjects.cast<Resta>());
        break;
      case 'sumasH':
        objeto.assignAll(loadedObjects.cast<SumaH>());
        break;
      case 'restasH':
        objeto.assignAll(loadedObjects.cast<RestaH>());
        break;
      case 'sumasC':
        objeto.assignAll(loadedObjects.cast<SumaC>());
        break;
      default:
        throw ArgumentError('Nombre de colección no válido: $nombre');
    }
    cardController.ordenarCronologicamente(objeto);
  }

  Future<void> removeSharedAccess(
      String sharedUserId, String collectionName) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('No user logged in');

    var sharedDocsQuery = await FirebaseFirestore.instance
        .collection('compartidos')
        .where('owner', isEqualTo: currentUser.uid)
        .where('sharedWith', arrayContains: sharedUserId)
        .get();

    for (var doc in sharedDocsQuery.docs) {
      var data = doc.data();
      var collections = List<String>.from(data['collections']);
      collections.remove(collectionName);

      if (collections.isEmpty) {
        await doc.reference.delete();
      } else {
        await doc.reference.update({'collections': collections});
      }
    }
  }

  // Método para guardar las listas en un archivo
  Future<void> guardarDatos() async {
    print('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    print('                           GUARDANDO datos                   ');
    print('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    try {
      final data = {
        'sumas': cardController.sumas.map((p) => p.toJson()).toList(),
        'restas': cardController.restas.map((a) => a.toJson()).toList(),
        'sumasH': cardControllerH.sumas.map((p) => p.toJson()).toList(),
        'restasH': cardControllerH.restas.map((a) => a.toJson()).toList(),
        'sumasC': cardControllerC.sumas.map((p) => p.toJson()).toList(),
      };

      String? uid;

      // Intentar obtener el usuario actual de Firebase
      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          uid = currentUser.uid;
          // Guardar el UID para uso futuro offline
          await saveUserUID(uid);
        }
      } catch (e) {
        print('No se pudo acceder a Firebase. Intentando usar UID guardado.');
      }

      // Si no se pudo obtener el UID de Firebase, intentar obtenerlo del almacenamiento local
      if (uid == null) {
        uid = await getSavedUserUID();
      }

      // Si aún no tenemos un UID, usar un valor por defecto
      if (uid == null) {
        uid = 'default_user';
        print('No se pudo obtener un UID. Usando usuario por defecto.');
      }
      print('uid $uid');
      final directorio = await getApplicationDocumentsDirectory();
      final file = File('${directorio.path}/$uid.json');

      await file.writeAsString(jsonEncode(data));
      print('==========================================================');
      print('              datos guardados      (guardarDatos)             ');
      print('==========================================================');
    } catch (e) {
      print('==========================================================');
      print('                   error guardando datos                   ');
      print('==========================================================');
    }
  }

// Método para recuperar las listas desde un archivo
  Future<void> saveUserUID(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_uid', uid);
  }

  Future<String?> getSavedUserUID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_uid');
  }

  cargarDatos3() async {
    try {
      print('------------------------------------------------------------');
      print('                           cargando datos                   ');
      print('------------------------------------------------------------');

      String? uid;

      // Intentar obtener el usuario actual de Firebase
      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          uid = currentUser.uid;
          // Guardar el UID para uso futuro offline
          await saveUserUID(uid);
        }
      } catch (e) {
        print('No se pudo acceder a Firebase. Intentando usar UID guardado.');
      }

      // Si no se pudo obtener el UID de Firebase, intentar obtenerlo del almacenamiento local
      if (uid == null) {
        uid = await getSavedUserUID();
      }

      // Si aún no tenemos un UID, usar un valor por defecto
      if (uid == null) {
        uid = 'default_user';
        print('No se pudo obtener un UID. Usando usuario por defecto.');
      }
      print('uid $uid');
      final directorio = await getApplicationDocumentsDirectory();
      final file = File('${directorio.path}/$uid.json');

      if (!await file.exists()) {
        Map<String, dynamic> initialData = {
          "sumas": [],
          "restas": [],
          "sumasH": [],
          "restasH": [],
          "sumasC": []
        };
        await file.create(recursive: true);
        await file.writeAsString(jsonEncode(initialData));
        print('archivo creado para el usuario: $uid');
      }
      final data = await file.readAsString();
      final jsonData = jsonDecode(data);
      final sumas = (jsonData['sumas'] as List<dynamic>)
          .map((p) => Suma.fromJson(p))
          .toList();
      final restas = (jsonData['restas'] as List<dynamic>)
          .map((a) => Resta.fromJson(a))
          .toList();
      final sumasH = (jsonData['sumasH'] as List<dynamic>)
          .map((p) => SumaH.fromJson(p))
          .toList();
      final restasH = (jsonData['restasH'] as List<dynamic>)
          .map((a) => RestaH.fromJson(a))
          .toList();
      final sumasC = (jsonData['sumasC'] as List<dynamic>)
          .map((p) => SumaC.fromJson(p))
          .toList();
      cardController.sumas.value = sumas;
      cardController.restas.value = restas;
      cardControllerH.sumas.value = sumasH;
      cardControllerH.restas.value = restasH;
      cardControllerC.sumas.value = sumasC;
      for (var suma in sumas) {
        cardController.calcularTotalSuma(suma);
      }
      for (var resta in restas) {
        cardController.calcularTotalResta(resta);
      }
      for (var suma in sumasH) {
        cardControllerH.calcularTotalSuma(suma);
      }
      for (var resta in restasH) {
        cardControllerH.calcularTotalResta(resta);
      }
      for (var suma in sumasC) {
        cardControllerC.calcularTotalC(suma);
      }
      print('==========================================================');
      print(
          '                      Si hay datos guardados (cargarDatos)              ');
      print('==========================================================');
    } catch (e) {
      print('==========================================================');
      print('                      error al cargarDatos               ');
      print('==========================================================');
    }
  }

  Future<void> cargarDatos(User? user) async {
    try {
      print('------------------------------------------------------------');
      print('                           cargando datos                   ');
      print('------------------------------------------------------------');


      final directorio = await getApplicationDocumentsDirectory();
      final file = File('${directorio.path}/${user!.uid}.json');

      if (!await file.exists()) {
        Map<String, dynamic> initialData = {
          "sumas": [],
          "restas": [],
          "sumasH": [],
          "restasH": [],
          "sumasC": []
        };
        await file.create(recursive: true);
        await file.writeAsString(jsonEncode(initialData));
        print('Archivo creado para el usuario: ${user!.uid}');
      }

      final data = await file.readAsString();
      final jsonData = jsonDecode(data);

      cardController.sumas.value = (jsonData['sumas'] as List<dynamic>)
          .map((p) => Suma.fromJson(p))
          .toList();
      cardController.restas.value = (jsonData['restas'] as List<dynamic>)
          .map((a) => Resta.fromJson(a))
          .toList();
      cardControllerH.sumas.value = (jsonData['sumasH'] as List<dynamic>)
          .map((p) => SumaH.fromJson(p))
          .toList();
      cardControllerH.restas.value = (jsonData['restasH'] as List<dynamic>)
          .map((a) => RestaH.fromJson(a))
          .toList();
      cardControllerC.sumas.value = (jsonData['sumasC'] as List<dynamic>)
          .map((p) => SumaC.fromJson(p))
          .toList();

      for (var suma in cardController.sumas) {
        cardController.calcularTotalSuma(suma);
      }
      for (var resta in cardController.restas) {
        cardController.calcularTotalResta(resta);
      }
      for (var suma in cardControllerH.sumas) {
        cardControllerH.calcularTotalSuma(suma);
      }
      for (var resta in cardControllerH.restas) {
        cardControllerH.calcularTotalResta(resta);
      }
      for (var suma in cardControllerC.sumas) {
        cardControllerC.calcularTotalC(suma);
      }

      print('==========================================================');
      print('                      Datos cargados exitosamente          ');
      print('==========================================================');
    } catch (e) {
      print('==========================================================');
      print('                      Error al cargarDatos: $e             ');
      print('==========================================================');
    }
  }

  cargarDatos_original() async {
    try {
      print('------------------------------------------------------------');
      print('                           cargando datos                   ');
      print('------------------------------------------------------------');

      String? uid;

      // Intentar obtener el usuario actual de Firebase
      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          uid = currentUser.uid;
          // Guardar el UID para uso futuro offline
          await saveUserUID(uid);
          print('se ubtubo de firebase ${uid}');
        }
      } catch (e) {
        print('No se pudo acceder a Firebase. Intentando usar UID guardado.');
      }

      // Si no se pudo obtener el UID de Firebase, intentar obtenerlo del almacenamiento local
      if (uid == null) {
        uid = await getSavedUserUID();
        print('se ubtubo de local ${uid}');
      }

      // Si aún no tenemos un UID, usar un valor por defecto
      if (uid == null) {
        uid = 'default_user';
        print('No se pudo obtener un UID. Usando usuario por defecto.');
      }
      print('uid $uid');
      final directorio = await getApplicationDocumentsDirectory();
      final file = File('${directorio.path}/$uid.json');

      if (!await file.exists()) {
        Map<String, dynamic> initialData = {
          "sumas": [],
          "restas": [],
          "sumasH": [],
          "restasH": [],
          "sumasC": []
        };
        await file.create(recursive: true);
        await file.writeAsString(jsonEncode(initialData));
        print('archivo creado para el usuario: $uid');
      }
      final data = await file.readAsString();
      final jsonData = jsonDecode(data);
      final sumas = (jsonData['sumas'] as List<dynamic>)
          .map((p) => Suma.fromJson(p))
          .toList();
      final restas = (jsonData['restas'] as List<dynamic>)
          .map((a) => Resta.fromJson(a))
          .toList();
      final sumasH = (jsonData['sumasH'] as List<dynamic>)
          .map((p) => SumaH.fromJson(p))
          .toList();
      final restasH = (jsonData['restasH'] as List<dynamic>)
          .map((a) => RestaH.fromJson(a))
          .toList();
      final sumasC = (jsonData['sumasC'] as List<dynamic>)
          .map((p) => SumaC.fromJson(p))
          .toList();
      cardController.sumas.value = sumas;
      cardController.restas.value = restas;
      cardControllerH.sumas.value = sumasH;
      cardControllerH.restas.value = restasH;
      cardControllerC.sumas.value = sumasC;
      for (var suma in sumas) {
        cardController.calcularTotalSuma(suma);
      }
      for (var resta in restas) {
        cardController.calcularTotalResta(resta);
      }
      for (var suma in sumasH) {
        cardControllerH.calcularTotalSuma(suma);
      }
      for (var resta in restasH) {
        cardControllerH.calcularTotalResta(resta);
      }
      for (var suma in sumasC) {
        cardControllerC.calcularTotalC(suma);
      }
      print('==========================================================');
      print(
          '                      Si hay datos guardados (cargarDatos)              ');
      print('==========================================================');
    } catch (e) {
      print('==========================================================');
      print('                      error al cargarDatos               ');
      print('==========================================================');
    }
  }

  cargarDatos2(String id) async {
    try {
      print('------------------------------------------------------------');
      print(
          '                 cargando datos de $id   (cargarDatos2)               ');
      print('------------------------------------------------------------');

      final directorio = await getApplicationDocumentsDirectory();
      final file = File('${directorio.path}/$id.json');

      if (!await file.exists()) {
        Map<String, dynamic> initialData = {
          "sumas": [],
          "restas": [],
          "sumasH": [],
          "restasH": [],
          "sumasC": []
        };
        await file.create(recursive: true);
        await file.writeAsString(jsonEncode(initialData));
        print('archivo creado para el usuario: $id');
      }
      final data = await file.readAsString();
      final jsonData = jsonDecode(data);
      final sumas = (jsonData['sumas'] as List<dynamic>)
          .map((p) => Suma.fromJson(p))
          .toList();
      final restas = (jsonData['restas'] as List<dynamic>)
          .map((a) => Resta.fromJson(a))
          .toList();
      final sumasH = (jsonData['sumasH'] as List<dynamic>)
          .map((p) => SumaH.fromJson(p))
          .toList();
      final restasH = (jsonData['restasH'] as List<dynamic>)
          .map((a) => RestaH.fromJson(a))
          .toList();
      final sumasC = (jsonData['sumasC'] as List<dynamic>)
          .map((p) => SumaC.fromJson(p))
          .toList();
      cardController.sumas.value = sumas;
      cardController.restas.value = restas;
      cardControllerH.sumas.value = sumasH;
      cardControllerH.restas.value = restasH;
      cardControllerC.sumas.value = sumasC;
      for (var suma in sumas) {
        cardController.calcularTotalSuma(suma);
      }
      for (var resta in restas) {
        cardController.calcularTotalResta(resta);
      }
      for (var suma in sumasH) {
        cardControllerH.calcularTotalSuma(suma);
      }
      for (var resta in restasH) {
        cardControllerH.calcularTotalResta(resta);
      }
      for (var suma in sumasC) {
        cardControllerC.calcularTotalC(suma);
      }
      print('==========================================================');
      print('     Si hay datos guardados para $id   (cargarDatos2)  ');
      print('==========================================================');
    } catch (e) {
      print('==========================================================');
      print('                      error al cargarDatos               ');
      print('==========================================================');
    }
  }
}

class Caja extends StatelessWidget {
  final Color color1;
  final Color color2;
  final String txt1;
  final String txt2;
  final bool oscuro;

  const Caja(
      {super.key,
      required this.color1,
      required this.color2,
      required this.txt1,
      required this.txt2,
      this.oscuro = false});

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return Expanded(
      child: Container(
        //width: 120,
        height: 120,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: color1,
            image: DecorationImage(
                image: const AssetImage('assets/topographi.png'),
                colorFilter: ColorFilter.mode(color2, BlendMode.srcIn),
                fit: BoxFit.none,
                alignment: Alignment.center)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(txt1,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: oscuro ? customColors.texto2 : Colors.white)),
            const Padding(padding: EdgeInsets.only(top: 5)),
            Text(txt2,
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: oscuro ? customColors.texto2 : Colors.white))
          ],
        ),
      ),
    );
  }
}

class CircleColor extends StatelessWidget {
  final Color color;
  final Widget texto;

  CircleColor({required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 10),
        texto
      ],
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<Color> colors;
  final List<Color> colorsA;
  final List<double> data;
  final List<String> labels;
  final double percentageSeparation;
  final BuildContext context;

  PieChartPainter(this.context,
      {required this.colors,
      required this.colorsA,
      required this.data,
      required this.labels,
      this.percentageSeparation = 30.0});

  @override
  void paint(Canvas canvas, Size size) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    double total = data.reduce((value, element) => value + element);
    double startAngle = -3 * pi / 2;
    double radius = size.width / 2;
    double centerX = size.width / 2;
    double centerY = size.height / 2;
    double legendX = size.width / 2 - 50;
    double legendY = size.height + 20;

    for (int i = 0; i < data.length; i++) {
      double sweepAngle = (data[i] / total) * 2 * pi;

      // Dibujar sector del pastel
      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        startAngle,
        sweepAngle,
        true,
        Paint()..color = colors[i],
      );

      // Dibujar línea exterior del sector del pastel
      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = colorsA[i] // Color de la línea exterior
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );

      // Calcular posición del porcentaje y dibujarlo
      if (data[i] != 0) {
        double percentageX = centerX +
            (radius + percentageSeparation) * cos(startAngle + sweepAngle / 2);
        double percentageY = centerY +
            (radius + percentageSeparation) * sin(startAngle + sweepAngle / 2);
        String percentage = ((data[i] / total) * 100).toStringAsFixed(1) + '%';
        TextSpan percentageSpan = TextSpan(
          text: percentage,
          style: TextStyle(
              color: customColors.texto4,
              fontFamily: 'Pangram',
              fontWeight: FontWeight.w700),
        );
        TextPainter percentagePainter = TextPainter(
          text: percentageSpan,
          textDirection: TextDirection.ltr,
        );
        percentagePainter.layout();
        percentagePainter.paint(
            canvas,
            Offset(percentageX - percentagePainter.width / 2,
                percentageY - percentagePainter.height / 2));

        // Calcular posición del centro del sector y dibujar etiqueta

        double labelX =
            centerX + (radius / 2) * cos(startAngle + sweepAngle / 2);
        double labelY =
            centerY + (radius / 2) * sin(startAngle + sweepAngle / 2);
        TextSpan labelSpan = TextSpan(
          text: '${data[i].toInt()}',
          style: TextStyle(
              color: colorsA[i],
              fontFamily: 'Pangram',
              fontWeight: FontWeight.w700),
        );
        TextPainter labelPainter = TextPainter(
          text: labelSpan,
          textDirection: TextDirection.ltr,
        );
        labelPainter.layout();
        labelPainter.paint(
            canvas,
            Offset(labelX - labelPainter.width / 2,
                labelY - labelPainter.height / 2));
      }

      startAngle += sweepAngle;
      if (i == 1) {
        legendX = size.width / 2 + 50;
        legendY = size.height + 20;
      } else if (i == 3) {
        legendY += 30;
      } else {
        legendY += 30;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class CustomPieChart extends StatelessWidget {
  final List<double> data;

  const CustomPieChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      height: 210,
      child: CustomPaint(
        painter: PieChartPainter(
          context,
          colors: [
            const Color(0xffBAE0E5),
            const Color(0xffF0D2CA),
            const Color(0xffF0CB94),
            const Color(0xff72C0A5)
          ],
          colorsA: [
            const Color(0xff4595AC),
            const Color(0xffCA7C74),
            const Color(0xffE59A54),
            const Color(0xff1B9C73)
          ],
          data: data, // Datos para los sectores
          labels: ['A', 'B', 'C', 'D'], // Etiquetas de leyenda
          percentageSeparation: 30,
        ),
      ),
    );
  }
}

class CustomTable extends StatelessWidget {
  final CardControllerH cardControllerH = Get.find();
  final NavegacionVar navegacionVar = Get.find();

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return Obx(() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              color: customColors.card,
            ),
            child: Row(
              children: [
                if (navegacionVar.showNombre.value)
                  CustomHeaderCell(label: 'Nombre'),
                if (navegacionVar.showConsumo.value)
                  CustomHeaderCell(label: 'Consumo'),
                if (navegacionVar.showVentas.value)
                  CustomHeaderCell(label: 'Ventas'),
                if (navegacionVar.showRotos.value)
                  CustomHeaderCell(label: 'Rotos'),
                if (navegacionVar.showOtros.value)
                  CustomHeaderCell(label: 'Otros'),
                if (navegacionVar.showIngreso.value)
                  CustomHeaderCell(label: 'Ingreso'),
                if (navegacionVar.showTotales.value)
                  CustomHeaderCellFinal(label: 'Totales'),
              ],
            ),
          ),
          ListView.builder(
            //physics: NeverScrollableScrollPhysics(),
            //physics: ScrollPhysics(),
            shrinkWrap: true,
            itemCount: cardControllerH.totales.length,
            itemBuilder: (context, index) {
              final total = cardControllerH.totales[index];
              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4.0),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10)),
                      color: customColors.card,
                    ),
                    child: Row(
                      children: [
                        if (navegacionVar.showNombre.value)
                          CustomDataCell(label: total.nombre),
                        if (navegacionVar.showConsumo.value)
                          CustomDataCell(label: total.huevosConsumo.toString()),
                        if (navegacionVar.showVentas.value)
                          CustomDataCell(
                              label: total.huevosVendidos.toString()),
                        if (navegacionVar.showRotos.value)
                          CustomDataCell(label: total.huevosRoto.toString()),
                        if (navegacionVar.showOtros.value)
                          CustomDataCell(label: total.huevosOtros.toString()),
                        if (navegacionVar.showIngreso.value)
                          CustomDataCell(label: '\$ ${total.balance}'),
                        if (navegacionVar.showTotales.value)
                          CustomDataCellFinal(
                              label: total.huevosTotales.toString()),
                        //CustomDataCell(label: total.fecha.toString()),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    //height: 25,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25)),
                      color: customColors.cardbottom,
                    ),
                    child: Text(formatearFecha(total.fecha),
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14)),
                  )
                ],
              );
            },
          ),
        ],
      );
    });
  }
}

class CustomHeaderCell extends StatelessWidget {
  final String label;
  final CardControllerH cardControllerH = Get.find();

  CustomHeaderCell({required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          cardControllerH.sortBy(label.toLowerCase());
        },
        child: Container(
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RotatedBox(
                quarterTurns: 3,
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Obx(() {
                final isSortingByThisColumn =
                    cardControllerH.sortedColumn.value == label.toLowerCase();
                if (isSortingByThisColumn) {
                  final isAscending = cardControllerH.ascendingOrder.value;
                  return Icon(
                    isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  );
                } else {
                  return const SizedBox(); // No muestra el icono si no se ha hecho clic en esta columna
                }
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomHeaderCellFinal extends StatelessWidget {
  final String label;
  final CardControllerH cardControllerH = Get.find();

  CustomHeaderCellFinal({required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          cardControllerH.sortBy(label.toLowerCase());
        },
        child: Container(
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RotatedBox(
                quarterTurns: 3,
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Obx(() {
                final isSortingByThisColumn =
                    cardControllerH.sortedColumn.value == label.toLowerCase();
                if (isSortingByThisColumn) {
                  final isAscending = cardControllerH.ascendingOrder.value;
                  return Icon(
                    isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  );
                } else {
                  return const SizedBox(); // No muestra el icono si no se ha hecho clic en esta columna
                }
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomDataCell extends StatelessWidget {
  final String label;

  const CustomDataCell({required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class CustomDataCellFinal extends StatelessWidget {
  final String label;

  const CustomDataCellFinal({required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        alignment: Alignment.center,
        child: Text(label),
      ),
    );
  }
}

class CustomTable2 extends StatelessWidget {
  var contol;
  var navegacionVar;

  CustomTable2({required this.contol, required this.navegacionVar});

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return Obx(() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              color: customColors.card,
            ),
            child: Row(
              children: [
                if (navegacionVar.showNombre.value)
                  CustomHeaderCell2(label: 'Nombre', contol: contol),
                if (navegacionVar.showConsumo.value)
                  CustomHeaderCell2(label: 'Consumo', contol: contol),
                if (navegacionVar.showVentas.value)
                  CustomHeaderCell2(label: 'Ventas', contol: contol),
                if (navegacionVar.showRotos.value)
                  CustomHeaderCell2(label: 'Rotos', contol: contol),
                if (navegacionVar.showOtros.value)
                  CustomHeaderCell2(label: 'Otros', contol: contol),
                if (navegacionVar.showIngreso.value)
                  CustomHeaderCell2(label: 'Ingreso', contol: contol),
                if (navegacionVar.showTotales.value)
                  CustomHeaderCellFinal2(label: 'Totales', contol: contol),
              ],
            ),
          ),
          ListView.builder(
            //physics: NeverScrollableScrollPhysics(),
            //physics: ScrollPhysics(),
            shrinkWrap: true,
            itemCount: contol.totales.length,
            itemBuilder: (context, index) {
              final total = contol.totales[index];
              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4.0),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10)),
                      color: customColors.card,
                    ),
                    child: Row(
                      children: [
                        if (navegacionVar.showNombre.value)
                          CustomDataCell(label: total.nombre),
                        if (navegacionVar.showConsumo.value)
                          CustomDataCell(label: total.huevosConsumo.toString()),
                        if (navegacionVar.showVentas.value)
                          CustomDataCell(
                              label: total.huevosVendidos.toString()),
                        if (navegacionVar.showRotos.value)
                          CustomDataCell(label: total.huevosRoto.toString()),
                        if (navegacionVar.showOtros.value)
                          CustomDataCell(label: total.huevosOtros.toString()),
                        if (navegacionVar.showIngreso.value)
                          CustomDataCell(label: '\$ ${total.balance}'),
                        if (navegacionVar.showTotales.value)
                          CustomDataCellFinal(
                              label: total.huevosTotales.toString()),
                        //CustomDataCell(label: total.fecha.toString()),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    //height: 25,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25)),
                      color: customColors.cardbottom,
                    ),
                    child: Text(formatearFecha(total.fecha),
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14)),
                  )
                ],
              );
            },
          ),
        ],
      );
    });
  }
}

class CustomHeaderCell2 extends StatelessWidget {
  final String label;
  var contol;

  CustomHeaderCell2({required this.label, required this.contol});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          contol.sortBy(label.toLowerCase());
        },
        child: Container(
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RotatedBox(
                quarterTurns: 3,
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Obx(() {
                final isSortingByThisColumn =
                    contol.sortedColumn.value == label.toLowerCase();
                if (isSortingByThisColumn) {
                  final isAscending = contol.ascendingOrder.value;
                  return Icon(
                    isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  );
                } else {
                  return const SizedBox(); // No muestra el icono si no se ha hecho clic en esta columna
                }
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomHeaderCellFinal2 extends StatelessWidget {
  final String label;
  var contol;

  CustomHeaderCellFinal2({required this.label, required this.contol});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          contol.sortBy(label.toLowerCase());
        },
        child: Container(
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RotatedBox(
                quarterTurns: 3,
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Obx(() {
                final isSortingByThisColumn =
                    contol.sortedColumn.value == label.toLowerCase();
                if (isSortingByThisColumn) {
                  final isAscending = contol.ascendingOrder.value;
                  return Icon(
                    isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  );
                } else {
                  return const SizedBox(); // No muestra el icono si no se ha hecho clic en esta columna
                }
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomTable3 extends StatelessWidget {
  var contol;
  var navegacionVar;

  CustomTable3({required this.contol, required this.navegacionVar});

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return Obx(() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              color: customColors.card,
            ),
            child: Row(
              children: [
                CustomHeaderCell2(label: 'Nombre', contol: contol),
                CustomHeaderCell2(label: 'Buenos', contol: contol),
                CustomHeaderCellFinal2(label: 'Rotos', contol: contol),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              //physics: NeverScrollableScrollPhysics(),
              //physics: ScrollPhysics(),
              shrinkWrap: true,
              itemCount: contol.filteredTotales.length,
              itemBuilder: (context, index) {
                final total = contol.filteredTotales[index];
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4.0),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10)),
                        color: customColors.card,
                      ),
                      child: Row(
                        children: [
                          CustomDataCell(label: total.nombre),
                          CustomDataCell(label: total.buenos.toString()),
                          CustomDataCellFinal(label: total.rotos.toString()),
                          //CustomDataCell(label: total.fecha.toString()),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      //height: 25,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(25),
                            bottomRight: Radius.circular(25)),
                        color: customColors.cardbottom,
                      ),
                      child: Text(formatearFecha(total.fecha),
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 14)),
                    )
                  ],
                );
              },
            ),
          ),
        ],
      );
    });
  }
}
