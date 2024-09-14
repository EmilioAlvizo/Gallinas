import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:uuid/uuid.dart';

import 'control.dart';
import 'fuente.dart';
import 'gallinas.dart';
import 'opciones.dart';
import 'texto.dart';
import 'sqlite.dart';

enum Razon_reduccionH { Consumo, Roto, Venta, Otro }

class SumaH {
  final String id;
  String nombre;
  Ave ave;
  int buenos;
  int rotos;
  DateTime fecha;

  SumaH({
    String? id,
    required this.nombre,
    required this.ave,
    required this.buenos,
    required this.rotos,
    required this.fecha,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'ave': ave.displayName,
      'buenos': buenos,
      'rotos': rotos,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory SumaH.fromJson(Map<String, dynamic> json) {
    return SumaH(
      id: json['id'],
      nombre: json['nombre'],
      ave: parseEnum(json['ave'], Ave.values),
      buenos: json['buenos'],
      rotos: json['rotos'],
      fecha: DateTime.parse(json['fecha']),
    );
  }
}

class RestaH {
  final String id;
  String nombre;
  Ave ave;
  int huevosMenos;
  Razon_reduccionH razon;
  double ingreso;
  DateTime fecha;

  RestaH(
      {String? id,
      required this.nombre,
      required this.ave,
      required this.huevosMenos,
      required this.razon,
      this.ingreso = 0,
      required this.fecha})
      : id = id ?? const Uuid().v4(); // Genera un ID único si no se proporciona

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'ave': ave.displayName,
      'huevosMenos': huevosMenos,
      'razon': razon.toString().split('.').last,
      'ingreso': ingreso,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory RestaH.fromJson(Map<String, dynamic> json) {
    return RestaH(
      id: json['id'],
      nombre: json['nombre'],
      ave: parseEnum(json['ave'], Ave.values),
      huevosMenos: json['huevosMenos'],
      razon: Razon_reduccionH.values
          .firstWhere((c) => c.toString().split('.').last == json['razon']),
      ingreso: json['ingreso'],
      fecha: DateTime.parse(json['fecha']),
    );
  }
}

class TotalH {
  String nombre;
  Ave ave;
  int huevosTotales;
  int huevosReducidos;
  int huevosOtros;
  int huevosConsumo;
  int huevosRoto;
  int huevosVendidos;
  double balance;
  DateTime fecha;

  TotalH({
    required this.nombre,
    required this.ave,
    required this.huevosTotales,
    required this.huevosReducidos,
    required this.huevosVendidos,
    required this.huevosRoto,
    required this.huevosConsumo,
    required this.huevosOtros,
    required this.balance,
    required this.fecha,
  });
}

class CardControllerH extends GetxController {
  RxList<SumaH> sumas = <SumaH>[].obs;
  RxList<RestaH> restas = <RestaH>[].obs;
  RxList<TotalH> totales = <TotalH>[].obs;
  final AveControl aveControl = Get.find();

  Future<void> loadSumas(String userId) async {
    final sumasData = await DatabaseHelper.instance.getSumasH(userId);
    sumas.value = sumasData.map((data) => SumaH.fromJson(data)).toList();
  }

  Future<void> loadRestas(String userId) async {
    final restasData = await DatabaseHelper.instance.getRestasH(userId);
    restas.value = restasData.map((data) => RestaH.fromJson(data)).toList();
  }

  // Método para cargar todos los datos
  Future<void> loadAllData(String userId) async {
    print('pasando datos de huevos a las variables observables');
    await loadSumas(userId);
    await loadRestas(userId);
    ordenarCronologicamente(sumas);
    ordenarCronologicamente(restas);
    sumas.forEach(calcularTotalSuma);
    restas.forEach(calcularTotalResta);
  }

  List<SumaH> get filteredSumas {
    if (aveControl.selectedAveFilter.value == 'Todas') {
      return sumas;
    } else {
      return sumas
          .where((total) =>
              total.ave.displayName == aveControl.selectedAveFilter.value)
          .toList();
    }
  }

  List<RestaH> get filteredRestas {
    if (aveControl.selectedAveFilter.value == 'Todas') {
      return restas;
    } else {
      return restas
          .where((total) =>
              total.ave.displayName == aveControl.selectedAveFilter.value)
          .toList();
    }
  }

  List<TotalH> get filteredTotales {
    if (aveControl.selectedAveFilter.value == 'Todas') {
      return totales;
    } else {
      return totales
          .where((total) =>
              total.ave.displayName == aveControl.selectedAveFilter.value)
          .toList();
    }
  }

  void updateFilteredTotals() {
    // Este método ahora solo notifica a los observadores que deben actualizar la vista
    update();
  }

  void agregarSumaH(SumaH suma) {
    sumas.add(suma);
    totalSuma(suma);
    addObjeto(suma, 'sumasH');
    ordenarCronologicamente(sumas);
    ordenarCronologicamente(totales);
    syncData(suma);
    //actualizarSumas(sumas, 'sumasH');
  }

  void editarSumaH(int index, SumaH suma) {
    updateObjeto(sumas[index], suma, 'sumasH');
    editarSumaYActualizarTotal(suma);
    ordenarCronologicamente(sumas);
    ordenarCronologicamente(totales);
    syncData(suma);
    //actualizarSumas(sumas, 'sumasH');
  }

  void eliminarSumaH(int index, SumaH suma) {
    removeObjeto(suma, 'sumasH');
    totalQuitarSuma(suma);
    sumas.removeAt(index);
    deleteObject(suma);
    //actualizarSumas(sumas, 'sumasH');
  }

  void agregarRestaH(RestaH resta) {
    restas.add(resta);
    totalResta(resta);
    addObjeto(resta, 'restasH');
    ordenarCronologicamente(restas);
    ordenarCronologicamente(totales);
    syncData(resta);
    //actualizarRestas(restas, 'restasH');
  }

  /*void editarRestaH2(String id, RestaH nuevaResta) {
    restas[id] = nuevaResta;
    updateObjeto(restas[id], nuevaResta, 'restasH');
    editarRestaYActualizarTotal(nuevaResta);
    ordenarCronologicamente(restas);
    ordenarCronologicamente(totales);
    syncData(nuevaResta);
  }*/

  void editarRestaH(int index, RestaH resta) {
    updateObjeto(restas[index], resta, 'restasH');
    editarRestaYActualizarTotal(resta);
    ordenarCronologicamente(restas);
    ordenarCronologicamente(totales);
    syncData(resta);
    //actualizarRestas(restas, 'restasH');
  }

  void eliminarRestaH(int index, RestaH resta) {
    removeObjeto(resta, 'restasH');
    totalQuitarResta(resta);
    restas.removeAt(index);
    deleteObject(resta);
    //actualizarRestas(restas, 'restasH');
  }

  void editarSumaYActualizarTotal(SumaH sumaEditada) {
    // Encontrar la suma original en la lista
    var sumaOriginal = sumas.firstWhere((suma) => suma.id == sumaEditada.id);

    // Actualizar la suma en la lista
    int index = sumas.indexWhere((suma) => suma.id == sumaEditada.id);
    sumas[index] = sumaEditada;

    // Buscar el total correspondiente
    var sumasFecha = sumas.where(
        (s) => s.nombre == sumaEditada.nombre && s.ave == sumaEditada.ave);
    var restasFecha = restas.where(
        (s) => s.nombre == sumaEditada.nombre && s.ave == sumaEditada.ave);
    var total = totales.firstWhereOrNull(
        (t) => t.nombre == sumaOriginal.nombre && t.ave == sumaOriginal.ave);
    if (total != null) {
      // Actualizar el total
      total.huevosConsumo -= sumaOriginal.buenos;
      total.huevosTotales -= sumaOriginal.buenos + sumaOriginal.rotos;
      total.huevosRoto -= sumaOriginal.rotos;
      total.fecha = _fechaReciente(
          [...sumasFecha, ...restasFecha], DateTime(1800, 4, 20));
      // Si el nombre o el ave han cambiado
      if (sumaOriginal.nombre != sumaEditada.nombre ||
          sumaOriginal.ave != sumaEditada.ave) {
        // Buscar o crear un nuevo total para el nuevo nombre/ave
        var nuevoTotal = totales.firstWhereOrNull(
            (t) => t.nombre == sumaEditada.nombre && t.ave == sumaEditada.ave);
        if (nuevoTotal == null) {
          totales.add(TotalH(
              nombre: sumaEditada.nombre,
              ave: sumaEditada.ave,
              huevosTotales: sumaEditada.buenos + sumaEditada.rotos,
              huevosReducidos: 0,
              huevosVendidos: 0,
              huevosRoto: sumaEditada.rotos,
              huevosConsumo: sumaEditada.buenos,
              huevosOtros: 0,
              balance: 0,
              fecha: sumaEditada.fecha));
        } else {
          nuevoTotal.huevosConsumo += sumaEditada.buenos;
          nuevoTotal.huevosTotales += sumaEditada.buenos + sumaEditada.rotos;
          nuevoTotal.huevosRoto += sumaEditada.rotos;
          nuevoTotal.fecha = _fechaReciente(
              [...sumasFecha, ...restasFecha], DateTime(1800, 4, 20));
        }
      } else {
        total.huevosConsumo += sumaEditada.buenos;
        total.huevosTotales += sumaEditada.buenos + sumaEditada.rotos;
        total.huevosRoto += sumaEditada.rotos;
        total.fecha = _fechaReciente(
            [...sumasFecha, ...restasFecha], DateTime(1800, 4, 20));
      }
    } else {
      print("Total correspondiente no encontrado");
    }
  }

  void editarRestaYActualizarTotal(RestaH restaEditada) {
    // Encontrar la resta original en la lista
    var restaOriginal =
        restas.firstWhere((resta) => resta.id == restaEditada.id);

    // Calcular la diferencia en huevos menos e ingreso
    int diferenciaHuevos = restaEditada.huevosMenos - restaOriginal.huevosMenos;
    double diferenciaIngreso = restaEditada.ingreso - restaOriginal.ingreso;

    // Actualizar la resta en la lista
    int index = restas.indexWhere((resta) => resta.id == restaEditada.id);
    restas[index] = restaEditada;

    // Buscar el total correspondiente
    var sumasFecha = sumas.where(
        (s) => s.nombre == restaEditada.nombre && s.ave == restaEditada.ave);
    var restasFecha = restas.where(
        (s) => s.nombre == restaEditada.nombre && s.ave == restaEditada.ave);
    var total = totales.firstWhereOrNull(
        (t) => t.nombre == restaOriginal.nombre && t.ave == restaOriginal.ave);

    if (total != null) {
      // Actualizar el total
      // Ajustar los contadores específicos
      switch (restaOriginal.razon) {
        case Razon_reduccionH.Consumo:
          total.huevosConsumo -= restaOriginal.huevosMenos;
          break;
        case Razon_reduccionH.Roto:
          total.huevosRoto -= restaOriginal.huevosMenos;
          break;
        case Razon_reduccionH.Venta:
          total.huevosVendidos -= restaOriginal.huevosMenos;
          break;
        case Razon_reduccionH.Otro:
          total.huevosOtros -= restaOriginal.huevosMenos;
          break;
      }
      total.huevosConsumo += restaOriginal.huevosMenos;
      total.huevosReducidos -= restaOriginal.huevosMenos;
      total.balance -= restaOriginal.ingreso;
      total.fecha = _fechaReciente(
          [...sumasFecha, ...restasFecha], DateTime(1800, 4, 20));
      // Si el nombre o el ave han cambiado
      if (restaOriginal.nombre != restaEditada.nombre ||
          restaOriginal.ave != restaEditada.ave) {
        // Buscar o crear un nuevo total para el nuevo nombre/ave
        var nuevoTotal = totales.firstWhereOrNull((t) =>
            t.nombre == restaEditada.nombre && t.ave == restaEditada.ave);
        if (nuevoTotal == null) {
          totales.add(TotalH(
              nombre: restaEditada.nombre,
              ave: restaEditada.ave,
              huevosTotales: 0,
              huevosReducidos: restaEditada.huevosMenos,
              huevosVendidos: restaEditada.razon == Razon_reduccionH.Venta
                  ? restaEditada.huevosMenos
                  : 0,
              huevosRoto: restaEditada.razon == Razon_reduccionH.Roto
                  ? restaEditada.huevosMenos
                  : 0,
              huevosConsumo: restaEditada.razon == Razon_reduccionH.Consumo
                  ? restaEditada.huevosMenos
                  : 0,
              huevosOtros: restaEditada.razon == Razon_reduccionH.Otro
                  ? restaEditada.huevosMenos
                  : 0,
              balance: restaEditada.ingreso,
              fecha: restaEditada.fecha));
        } else {
          switch (restaEditada.razon) {
            case Razon_reduccionH.Consumo:
              nuevoTotal.huevosConsumo += restaEditada.huevosMenos;
              break;
            case Razon_reduccionH.Roto:
              nuevoTotal.huevosRoto += restaEditada.huevosMenos;
              break;
            case Razon_reduccionH.Venta:
              nuevoTotal.huevosVendidos += restaEditada.huevosMenos;
              break;
            case Razon_reduccionH.Otro:
              nuevoTotal.huevosOtros += restaEditada.huevosMenos;
              break;
          }
          nuevoTotal.huevosConsumo -= restaOriginal.huevosMenos;
          nuevoTotal.huevosReducidos += restaOriginal.huevosMenos;
          nuevoTotal.balance += restaOriginal.ingreso;
          nuevoTotal.fecha = _fechaReciente(
              [...sumasFecha, ...restasFecha], DateTime(1800, 4, 20));
        }
      } else {
        switch (restaEditada.razon) {
          case Razon_reduccionH.Consumo:
            total.huevosConsumo += restaEditada.huevosMenos;
            break;
          case Razon_reduccionH.Roto:
            total.huevosRoto += restaEditada.huevosMenos;
            break;
          case Razon_reduccionH.Venta:
            total.huevosVendidos += restaEditada.huevosMenos;
            break;
          case Razon_reduccionH.Otro:
            total.huevosOtros += restaEditada.huevosMenos;
            break;
        }
        total.huevosConsumo -= restaOriginal.huevosMenos;
        total.huevosReducidos += restaOriginal.huevosMenos;
        total.balance += restaOriginal.ingreso;
        total.fecha = _fechaReciente(
            [...sumasFecha, ...restasFecha], DateTime(1800, 4, 20));
      }
    } else {
      print("Total correspondiente no encontrado");
    }
  }

  void totalQuitarSuma(SumaH suma) {
    var sumasFecha =
        sumas.where((s) => s.nombre == suma.nombre && s.ave == suma.ave);
    var restasFecha =
        restas.where((s) => s.nombre == suma.nombre && s.ave == suma.ave);
    var totalNombre = totales.firstWhereOrNull(
        (t) => (t.nombre == suma.nombre) && (t.ave == suma.ave));
    if (totalNombre != null) {
      totalNombre.huevosConsumo -= suma.buenos;
      totalNombre.huevosTotales -= suma.buenos + suma.rotos;
      totalNombre.huevosRoto -= suma.rotos;
      totalNombre.fecha = _fechaReciente(
          [...sumasFecha, ...restasFecha], DateTime(1800, 4, 20));
      // Procesar
      if (totalNombre.huevosTotales <= 0 && totalNombre.huevosReducidos <= 0) {
        totales.remove(totalNombre);
      }
    } else {
      print('totalQuitarSuma -- no hay total para esa suma');
      // Manejar el caso cuando no se encuentra ningún elemento
    }
  }

  void totalSuma(SumaH suma) {
    var sumasFecha =
        sumas.where((s) => s.nombre == suma.nombre && s.ave == suma.ave);
    var restasFecha =
        restas.where((s) => s.nombre == suma.nombre && s.ave == suma.ave);
    var totalNombre = totales.firstWhereOrNull(
        (t) => (t.nombre == suma.nombre) && (t.ave == suma.ave));
    if (totalNombre != null) {
      totalNombre.huevosConsumo += suma.buenos;
      totalNombre.huevosTotales += suma.buenos + suma.rotos;
      totalNombre.huevosRoto += suma.rotos;
      totalNombre.fecha = _fechaReciente(
          [...sumasFecha, ...restasFecha], DateTime(1800, 4, 20));
      // Procesar ave2
    } else {
      //print('SumaH -- totalNombre es null');
      totales.add(TotalH(
          nombre: suma.nombre,
          ave: suma.ave,
          huevosTotales: suma.buenos + suma.rotos,
          huevosReducidos: 0,
          huevosVendidos: 0,
          huevosRoto: suma.rotos,
          huevosConsumo: suma.buenos,
          huevosOtros: 0,
          balance: 0,
          fecha: suma.fecha));
      // Manejar el caso cuando no se encuentra ningún elemento
    }
  }

  void totalQuitarResta(RestaH resta) {
    var sumasFecha =
        sumas.where((s) => s.nombre == resta.nombre && s.ave == resta.ave);
    var restasFecha =
        restas.where((s) => s.nombre == resta.nombre && s.ave == resta.ave);
    var totalNombre = totales.firstWhereOrNull(
        (t) => (t.nombre == resta.nombre) && (t.ave == resta.ave));
    if (totalNombre != null) {
      switch (resta.razon) {
        case Razon_reduccionH.Consumo:
          totalNombre.huevosConsumo -= resta.huevosMenos;
          break;
        case Razon_reduccionH.Roto:
          totalNombre.huevosRoto -= resta.huevosMenos;
          break;
        case Razon_reduccionH.Venta:
          totalNombre.huevosVendidos -= resta.huevosMenos;
          break;
        case Razon_reduccionH.Otro:
          totalNombre.huevosOtros -= resta.huevosMenos;
          break;
      }
      totalNombre.huevosConsumo += resta.huevosMenos;
      totalNombre.huevosReducidos -= resta.huevosMenos;
      totalNombre.balance -= resta.ingreso;
      totalNombre.fecha = _fechaReciente(
          [...sumasFecha, ...restasFecha], DateTime(1800, 4, 20));
      // Procesar ave2
      if (totalNombre.huevosTotales <= 0 && totalNombre.huevosReducidos <= 0) {
        totales.remove(totalNombre);
      }
    } else {
      print('totalQuitarResta -- totalNombre es null');
      // Manejar el caso cuando no se encuentra ningún elemento
    }
  }

  void totalResta(RestaH resta) {
    var sumasFecha =
        sumas.where((s) => s.nombre == resta.nombre && s.ave == resta.ave);
    var restasFecha =
        restas.where((s) => s.nombre == resta.nombre && s.ave == resta.ave);
    var totalNombre = totales.firstWhereOrNull(
        (t) => (t.nombre == resta.nombre) && (t.ave == resta.ave));
    if (totalNombre != null) {
      switch (resta.razon) {
        case Razon_reduccionH.Consumo:
          totalNombre.huevosConsumo += resta.huevosMenos;
          break;
        case Razon_reduccionH.Roto:
          totalNombre.huevosRoto += resta.huevosMenos;
          break;
        case Razon_reduccionH.Venta:
          totalNombre.huevosVendidos += resta.huevosMenos;
          break;
        case Razon_reduccionH.Otro:
          totalNombre.huevosOtros += resta.huevosMenos;
          break;
      }
      totalNombre.huevosConsumo -= resta.huevosMenos;
      totalNombre.huevosReducidos += resta.huevosMenos;
      totalNombre.balance += resta.ingreso;
      totalNombre.fecha = _fechaReciente(
          [...sumasFecha, ...restasFecha], DateTime(1800, 4, 20));
      // Procesar ave2
    } else {
      print('totalResta -- totalNombre es null');
      // Manejar el caso cuando no se encuentra ningún elemento
    }
  }

  void calcularTotalSuma(SumaH suma) {
    var sumasFecha =
        sumas.where((s) => s.nombre == suma.nombre && s.ave == suma.ave);
    var restasFecha =
        restas.where((s) => s.nombre == suma.nombre && s.ave == suma.ave);
    var totalNombre = totales.firstWhereOrNull(
        (t) => (t.nombre == suma.nombre) && (t.ave == suma.ave));
    if (totalNombre != null) {
      totalNombre.huevosConsumo += suma.buenos;
      totalNombre.huevosTotales += suma.buenos + suma.rotos;
      totalNombre.huevosRoto += suma.rotos;
      totalNombre.fecha = _fechaReciente(
          [...sumasFecha, ...restasFecha], DateTime(1800, 4, 20));
      // Procesar ave2
    } else {
      print('SumaH -- totalNombre es null');
      totales.add(TotalH(
          nombre: suma.nombre,
          ave: suma.ave,
          huevosTotales: suma.buenos + suma.rotos,
          huevosReducidos: 0,
          huevosVendidos: 0,
          huevosRoto: suma.rotos,
          huevosConsumo: suma.buenos,
          huevosOtros: 0,
          balance: 0,
          fecha: suma.fecha));
      ordenarCronologicamente(totales);
      // Manejar el caso cuando no se encuentra ningún elemento
    }
  }

  void calcularTotalResta(RestaH resta) {
    var sumasFecha =
        sumas.where((s) => s.nombre == resta.nombre && s.ave == resta.ave);
    var restasFecha =
        restas.where((s) => s.nombre == resta.nombre && s.ave == resta.ave);
    var totalNombre = totales.firstWhereOrNull(
        (t) => (t.nombre == resta.nombre) && (t.ave == resta.ave));
    if (totalNombre != null) {
      switch (resta.razon) {
        case Razon_reduccionH.Consumo:
          totalNombre.huevosConsumo += resta.huevosMenos;
          break;
        case Razon_reduccionH.Roto:
          totalNombre.huevosRoto += resta.huevosMenos;
          break;
        case Razon_reduccionH.Venta:
          totalNombre.huevosVendidos += resta.huevosMenos;
          break;
        case Razon_reduccionH.Otro:
          totalNombre.huevosOtros += resta.huevosMenos;
          break;
      }
      totalNombre.huevosConsumo -= resta.huevosMenos;
      totalNombre.huevosReducidos += resta.huevosMenos;
      totalNombre.balance += resta.ingreso;
      totalNombre.fecha = _fechaReciente(
          [...sumasFecha, ...restasFecha], DateTime(1800, 4, 20));
      // Procesar ave2
    } else {
      print('calcularTotalResta -- totalNombre es null');
      ordenarCronologicamente(totales);
      // Manejar el caso cuando no se encuentra ningún elemento
    }
  }

  void editarTotalH() {
    List<String> nombres = sumas.map((suma) => suma.nombre).toList();
    totales.removeWhere((total) => !nombres.contains(total.nombre));
  }

  List<num> calcularTotalH2() {
    int totalHuevos = 0;
    int totalReducciones = 0;
    double totalIngresos = 0;
    int totalHuevosOtros = 0;
    int totalHuevosConsumo = 0;
    int totalHuevosRoto = 0;
    int totalHuevosVendidos = 0;

    for (var total in filteredTotales) {
      totalHuevos += total.huevosTotales;
      totalReducciones += total.huevosReducidos;
      totalIngresos += total.balance;
      totalHuevosOtros += total.huevosOtros;
      totalHuevosConsumo += total.huevosConsumo;
      totalHuevosRoto += total.huevosRoto;
      totalHuevosVendidos += total.huevosVendidos;
    }

    return [
      totalHuevos,
      totalIngresos,
      totalReducciones,
      totalHuevosConsumo,
      totalHuevosVendidos,
      totalHuevosRoto,
      totalHuevosOtros,
    ];
  }

  ordenarCronologicamente(RxList carta) {
    //carta.sort((a, b) => a.fecha.compareTo(b.fecha));
    carta.sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  _fechaReciente(List cartas, DateTime fechaMasReciente) {
    for (var carta in cartas) {
      if (carta.fecha.isAfter(fechaMasReciente)) {
        fechaMasReciente = carta.fecha;
      }
    }
    return fechaMasReciente;
  }

  var ascendingOrder = true.obs;
  var sortedColumn = ''.obs;

  void sortBy(String field) {
    totales.sort((a, b) {
      switch (field) {
        case 'nombre':
          sortedColumn.value = field;
          final comparison = a.nombre.compareTo(b.nombre);
          return ascendingOrder.value ? comparison : -comparison;
        case 'consumo':
          sortedColumn.value = field;
          final comparison = a.huevosConsumo.compareTo(b.huevosConsumo);
          return ascendingOrder.value ? comparison : -comparison;
        case 'ventas':
          sortedColumn.value = field;
          final comparison = a.huevosVendidos.compareTo(b.huevosVendidos);
          return ascendingOrder.value ? comparison : -comparison;
        case 'rotos':
          sortedColumn.value = field;
          final comparison = a.huevosRoto.compareTo(b.huevosRoto);
          return ascendingOrder.value ? comparison : -comparison;
        case 'otros':
          sortedColumn.value = field;
          final comparison = a.huevosOtros.compareTo(b.huevosOtros);
          return ascendingOrder.value ? comparison : -comparison;
        case 'ingreso':
          sortedColumn.value = field;
          final comparison = a.balance.compareTo(b.balance);
          return ascendingOrder.value ? comparison : -comparison;
        case 'totales':
          sortedColumn.value = field;
          final comparison = a.huevosTotales.compareTo(b.huevosTotales);
          return ascendingOrder.value ? comparison : -comparison;
        case 'fechaNacimiento':
          sortedColumn.value = field;
          final comparison = a.fecha.compareTo(b.fecha);
          return ascendingOrder.value ? comparison : -comparison;
        default:
          return 0;
      }
    });
    ascendingOrder.toggle();
  }
}

class Huevos extends StatelessWidget {
  final CardControllerH cardControllerH = Get.find();
  final AveControl aveControl = Get.find();
  final controlador;
  Huevos({super.key, required this.controlador});

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
                  label: Text('Total',
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
                    controlador.pageController3.animateToPage(0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease);
                  },
                ),
                const Padding(padding: EdgeInsets.only(right: 10.0)),
                ChoiceChip(
                  label: Text('Agregar',
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
                    controlador.pageController3.animateToPage(1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease);
                  },
                ),
                const Padding(padding: EdgeInsets.only(right: 10.0)),
                ChoiceChip(
                  label: Text('Reducir',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: controlador.botonIndex.value == 2
                              ? customColors.texto1
                              : const Color(0xff828282))),
                  backgroundColor: customColors.boton,
                  selectedColor: const Color(0xffE59A54),
                  checkmarkColor: controlador.botonIndex.value == 2
                      ? customColors.texto1
                      : const Color(0xff828282),
                  padding: const EdgeInsets.only(
                      top: 10, bottom: 10, right: 10, left: 10),
                  side: const BorderSide(style: BorderStyle.none),
                  selected: controlador.botonIndex.value == 2,
                  onSelected: (selected) {
                    controlador.botonIndex.value = 2;
                    controlador.pageController3.animateToPage(2,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease);
                  },
                ),
              ],
            ),
          ),
          //const Padding(padding: EdgeInsets.only(top: 5.0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Aves',
                style: TextStyle(fontSize: 15),
              ),
              Obx(() => DropdownButton<String>(
                    underline: Container(),
                    icon: const SizedBox.shrink(),
                    value: aveControl.selectedAveFilter.value,
                    onChanged: (String? newValue) {
                      aveControl.selectedAveFilter.value = newValue!;
                      cardControllerH.updateFilteredTotals();
                    },
                    items: ['Todas', ...Ave.values.map((e) => e.displayName)]
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                  )),
            ],
          ),
          Obx(() => _getBody(controlador.botonIndex.value, context)),
        ],
      ),
    );
  }

  Widget _getBody(int index, BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return Expanded(
        child: PageView(
      controller: controlador.pageController3,
      onPageChanged: controlador.onPageChanged,
      children: [
        Stack(alignment: Alignment.center, children: [
          Container(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Caja(
                      color1: customColors.card2!,
                      color2: customColors.linea!,
                      txt1: '${cardControllerH.calcularTotalH2()[0]}',
                      txt2: 'Huevos'),
                  const Padding(padding: EdgeInsets.only(left: 10.0)),
                  Caja(
                      color1: customColors.card3!,
                      color2: customColors.linea2!,
                      txt1:
                          '${cardControllerH.calcularTotalH2()[1].toStringAsFixed(0)} \$',
                      txt2: 'Ingreso',
                      oscuro: true),
                  const Padding(padding: EdgeInsets.only(left: 10.0)),
                  Caja(
                      color1: customColors.card4!,
                      color2: customColors.linea3!,
                      txt1: '${cardControllerH.calcularTotalH2()[4]}',
                      txt2: 'Ventas',
                      oscuro: true),
                ],
              ),
              const Padding(padding: EdgeInsets.only(top: 10)),
              /*Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(25)),
                            color: customColors.card),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.only(bottom: 25),
                                  child: Text('Destino de los Huevos',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 17,
                                          color: customColors.texto3)),
                                ),
                              ],
                            ),
                            CustomPieChart(
                                data: [
                              cardControllerH.calcularTotalH2()[3],
                              cardControllerH.calcularTotalH2()[4],
                              cardControllerH.calcularTotalH2()[5],
                              cardControllerH.calcularTotalH2()[6]
                            ].map((numero) => numero.toDouble()).toList()),
                            const Padding(padding: EdgeInsets.only(top: 40)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleColor(
                                        color: Colores.azul1,
                                        texto: Text('Consumo',
                                            style: TextStyle(
                                                fontSize: 15,
                                                color: customColors.texto3))),
                                    CircleColor(
                                        color: Colores.rojo1,
                                        texto: Text('Venta',
                                            style: TextStyle(
                                                fontSize: 15,
                                                color: customColors.texto3))),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleColor(
                                      color: Colores.naranja1,
                                      texto: Text('Rotos',
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: customColors.texto3)),
                                    ),
                                    CircleColor(
                                      color: Colores.verde1,
                                      texto: Text('Otro',
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: customColors.texto3)),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      //_MostrarTotales(),
                      const Padding(padding: EdgeInsets.only(top: 10)),
                      //CustomTable(),
                      //const Padding(padding: EdgeInsets.only(top: 10)),
                      //CustomTable2(contol: cardControllerH,),
                    ],
                  ),
                ),
              ),*/
              _MostrarTotales(),
            ],
          ))
        ]),
        Stack(alignment: Alignment.center, children: [
          Container(child: Column(children: [_MostrarSumas()])),
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
              child: const Icon(Icons.add),
            ),
          )
        ]),
        Stack(alignment: Alignment.center, children: [
          Container(child: Column(children: [_MostrarRestas()])),
          Positioned(
            bottom: 10,
            right: 0,
            child: FloatingActionButton(
              backgroundColor: const Color(0xff03dac6),
              foregroundColor: Colors.black,
              mini: true,
              onPressed: () {
                mostrarDialogo2(context);
              },
              child: const Icon(Icons.remove_rounded),
            ),
          )
        ])
      ],
    ));
  }
}

void mostrarDialogo(BuildContext context, {SumaH? suma, int? index}) {
  final _formKey = GlobalKey<FormState>();
  final CardControllerH cardControllerH = Get.find();
  final CardController cardController = Get.find();
  TextEditingController idC = TextEditingController();
  TextEditingController nombreC = TextEditingController();
  TextEditingController rotosC = TextEditingController(text: '0');
  TextEditingController buenosC = TextEditingController();
  TextEditingController fechaC = TextEditingController();

  if (suma != null) {
    idC = TextEditingController(text: suma.id);
    nombreC = TextEditingController(text: suma.nombre);
    buenosC = TextEditingController(text: suma.buenos.toString());
    rotosC = TextEditingController(text: suma.rotos.toString());
    fechaC =
        TextEditingController(text: intl.DateFormat.yMd().format(suma.fecha));
  }

  Total? selectedTotal = null;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Agregar Huevos'),
        content: SingleChildScrollView(
          child: Container(
            width: double.maxFinite,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownMenu<Total>(
                    expandedInsets: const EdgeInsets.all(0.0),
                    controller: nombreC,
                    label: const Text('Nombre de bandada/grupo'),
                    helperText: '* requerido',
                    onSelected: (newValue) {
                      if (newValue != null) {
                        nombreC.text = newValue.nombre;
                        selectedTotal = newValue;
                      }
                    },
                    //enableFilter: true,
                    dropdownMenuEntries: cardController.totales.map((total) {
                      return DropdownMenuEntry<Total>(
                        value: total,
                        label: '${total.nombre} (${total.ave.displayName})',
                      );
                    }).toList(),
                    inputDecorationTheme: const InputDecorationTheme(
                      filled: false,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.only(top: 10)),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        //width: 150,
                        child: TextFormField(
                          //maxLength: 10,
                          //maxLengthEnforcement: MaxLengthEnforcement.none,
                          controller: buenosC,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            suffixIcon: ClearButton(controller: buenosC),
                            labelText: 'Huevos buenos',
                            helperText: '* requerido',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Introduzca un número';
                            }
                            final n = int.tryParse(value);
                            if (n == null) {
                              return 'Ingrese un número entero';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        //width: 150,
                        child: TextFormField(
                          //maxLength: 10,
                          //maxLengthEnforcement: MaxLengthEnforcement.none,
                          controller: rotosC,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            suffixIcon: ClearButton(controller: rotosC),
                            labelText: 'Huevos rotos',
                            helperText: '* requerido',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Introduzca un número';
                            }
                            final n = int.tryParse(value);
                            if (n == null) {
                              return 'Ingrese un número entero';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.only(top: 10)),
                  if (suma == null)
                    DatePicker(control: fechaC, texto: 'Fecha de adquisición'),
                  if (suma != null)
                    DatePicker(
                        control: fechaC,
                        texto: 'Fecha de adquisición',
                        initialDate: suma.fecha),
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
          ElevatedButton(
            child: const Text('Agregar'),
            onPressed: () {
              if (_formKey.currentState!.validate() && selectedTotal != null) {
                if (suma != null) {
                  cardControllerH.editarSumaH(
                      index!,
                      SumaH(
                        id: idC.text,
                        nombre: nombreC.text,
                        ave: selectedTotal!.ave,
                        buenos: int.parse(buenosC.text),
                        rotos: int.parse(rotosC.text),
                        fecha: intl.DateFormat('M/d/yyyy').parse(fechaC.text),
                      ));
                  //cardControllerH.editarTotalH2(pasado, nombreC.text,
                  //int.parse(buenosC.text) + int.parse(rotosC.text));
                } else {
                  cardControllerH.agregarSumaH(
                    SumaH(
                      nombre: nombreC.text,
                      ave: selectedTotal!.ave,
                      buenos: int.parse(buenosC.text),
                      rotos: int.parse(rotosC.text),
                      fecha: intl.DateFormat('M/d/yyyy').parse(fechaC.text),
                    ),
                  );
                }
                Navigator.of(context).pop();
              } else {}
            },
          ),
        ],
      );
    },
  );
}

void mostrarDialogo2(BuildContext context, {RestaH? resta, int? index}) {
  final _formKey = GlobalKey<FormState>();
  final CardControllerH cardControllerH = Get.find();
  final CardController cardController = Get.find();
  TextEditingController idC = TextEditingController();
  TextEditingController nombreC = TextEditingController();
  TextEditingController huevosMenosC = TextEditingController();
  TextEditingController razonC = TextEditingController();
  TextEditingController ingresoC = TextEditingController();
  TextEditingController fechaC = TextEditingController();
  var bool5 = false.obs;

  Total? selectedTotal;
  if (resta != null) {
    (resta.razon == Razon_reduccionH.Venta)
        ? bool5.value = true
        : bool5.value = false;
    idC = TextEditingController(text: resta.id);
    nombreC = TextEditingController(text: resta.nombre);
    razonC = TextEditingController(text: resta.razon.name.toString());
    ingresoC = TextEditingController(text: resta.ingreso.toString());
    fechaC =
        TextEditingController(text: intl.DateFormat.yMd().format(resta.fecha));
    huevosMenosC = TextEditingController(text: resta.huevosMenos.toString());
    selectedTotal = cardController.totales.firstWhere(
        (total) => total.nombre == resta.nombre && total.ave == resta.ave);
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Reducir Huevos.'),
        content: SingleChildScrollView(
          child: Container(
            width: double.maxFinite,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownMenu<Total>(
                    expandedInsets: const EdgeInsets.all(0.0),
                    controller: nombreC,
                    label: const Text('Nombre de bandada/grupo'),
                    helperText: '* requerido',
                    onSelected: (newValue) {
                      if (newValue != null) {
                        nombreC.text = newValue.nombre;
                        selectedTotal = newValue;
                      }
                    },
                    //enableFilter: true,
                    dropdownMenuEntries: cardController.totales.map((total) {
                      return DropdownMenuEntry<Total>(
                        value: total,
                        label: '${total.nombre} (${total.ave.displayName})',
                      );
                    }).toList(),
                    inputDecorationTheme: const InputDecorationTheme(
                      filled: false,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.only(top: 10)),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        //width: 150,
                        child: TextFormField(
                          //maxLength: 10,
                          //maxLengthEnforcement: MaxLengthEnforcement.none,
                          controller: huevosMenosC,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            suffixIcon: ClearButton(controller: huevosMenosC),
                            labelText: 'No. huevos',
                            helperText: '* requerido',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Introduzca un número';
                            }
                            final n = int.tryParse(value);
                            if (n == null) {
                              return 'Ingrese un número entero';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        //width: 150,
                        //List<String> nombres = sumas.map((suma) => suma.nombre).toList();
                        child: DropdownMenu<Razon_reduccionH>(
                          expandedInsets: const EdgeInsets.all(0.0),
                          controller: razonC,
                          label: const Text('Razon de reducción'),
                          helperText: '* requerido',
                          onSelected: (newValue) {
                            if (newValue != null) {
                              if (newValue == Razon_reduccionH.Venta) {
                                bool5.value = true;
                              } else {
                                bool5.value = false;
                              }
                            }
                          },
                          //enableFilter: true,
                          dropdownMenuEntries: Razon_reduccionH.values
                              .map<DropdownMenuEntry<Razon_reduccionH>>(
                                  (Razon_reduccionH tipo) {
                            return DropdownMenuEntry<Razon_reduccionH>(
                              value: tipo,
                              label: tipo.name,
                              //enabled: tipo != Proposito.ambos,
                            );
                          }).toList(),
                          inputDecorationTheme: const InputDecorationTheme(
                            filled: false,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.only(top: 10)),
                  if (resta == null)
                    DatePicker(control: fechaC, texto: 'Fecha de reducción'),
                  if (resta != null)
                    DatePicker(
                        control: fechaC,
                        texto: 'Fecha de reducción',
                        initialDate: resta.fecha),
                  const Padding(padding: EdgeInsets.only(top: 10)),
                  Obx(() {
                    if (bool5.value) {
                      return TextFormField(
                        //maxLength: 10,
                        //maxLengthEnforcement: MaxLengthEnforcement.none,
                        controller: ingresoC,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          suffixIcon: ClearButton(controller: ingresoC),
                          labelText: 'Ingreso por venta',
                          prefixText: '\$ ',
                          helperText: '* requerido',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Introduzca un número';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Por favor, ingrese un número válido';
                          }
                          return null;
                        },
                      );
                    } else {
                      return const SizedBox();
                    }
                  }),
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
          ElevatedButton(
            child: const Text('Agregar'),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                if (resta != null) {
                  cardControllerH.editarRestaH(
                      index!,
                      RestaH(
                          id: idC.text,
                          nombre: nombreC.text,
                          ave: selectedTotal!.ave,
                          huevosMenos: int.parse(huevosMenosC.text),
                          razon:
                              parseEnum(razonC.text, Razon_reduccionH.values),
                          //costo: double.parse(costoC.text),
                          ingreso: (ingresoC.text.isEmpty
                              ? 0.0
                              : double.parse(ingresoC.text)),
                          fecha: intl.DateFormat('M/d/yyyy')
                              .parse(fechaC.text) //DateTime.parse(fechaC.text),
                          ));
                } else {
                  cardControllerH.agregarRestaH(
                    RestaH(
                        nombre: nombreC.text,
                        ave: selectedTotal!.ave,
                        huevosMenos: int.parse(huevosMenosC.text),
                        razon: parseEnum(razonC.text, Razon_reduccionH.values),
                        //costo: double.parse(costoC.text),
                        ingreso: (ingresoC.text.isEmpty
                            ? 0.0
                            : double.parse(ingresoC.text)),
                        fecha: intl.DateFormat('M/d/yyyy')
                            .parse(fechaC.text) //DateTime.parse(fechaC.text),
                        ),
                  );
                }
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      );
    },
  );
}

class _MostrarSumas extends StatelessWidget {
  final CardControllerH cardControllerH = Get.find();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(
        () => ListView.builder(
          itemCount: cardControllerH.filteredSumas.length,
          itemBuilder: (context, index) {
            var suma = cardControllerH.filteredSumas[index];
            return InkWell(
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              onTap: () {
                mostrarDialogo(context, suma: suma, index: index);
              },
              onLongPress: () {
                // Mostrar diálogo de confirmación para eliminar el card
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Eliminar Card'),
                      content: const Text(
                          '¿Estás seguro de que quieres eliminar este card?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Cerrar el diálogo
                          },
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () {
                            cardControllerH.eliminarSumaH(index, suma);
                            Navigator.pop(
                                context); // Llamar a la función onDelete para eliminar el card
                          },
                          child: const Text('Eliminar'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: TarjetaH(
                nombre: suma.nombre,
                ave: suma.ave,
                buenos: suma.buenos,
                rotos: suma.rotos,
                fecha: formatearFecha(suma.fecha),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MostrarRestas extends StatelessWidget {
  final CardControllerH cardControllerH = Get.find();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(
        () => ListView.builder(
          itemCount: cardControllerH.filteredRestas.length,
          itemBuilder: (context, index) {
            var resta = cardControllerH.filteredRestas[index];
            return InkWell(
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              onTap: () {
                mostrarDialogo2(context, resta: resta, index: index);
              },
              onLongPress: () {
                // Mostrar diálogo de confirmación para eliminar el card
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Eliminar Card'),
                      content: const Text(
                          '¿Estás seguro de que quieres eliminar este card?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Cerrar el diálogo
                          },
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () {
                            cardControllerH.eliminarRestaH(index, resta);
                            Navigator.pop(
                                context); // Llamar a la función onDelete para eliminar el card
                          },
                          child: const Text('Eliminar'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Tarjeta_restarH(
                nombre: resta.nombre,
                ave: resta.ave,
                huevosMenos: resta.huevosMenos,
                razon: resta.razon,
                ingreso: resta.ingreso,
                fecha: formatearFecha(resta.fecha),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MostrarTotales extends StatelessWidget {
  final CardControllerH cardControllerH = Get.find();

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return Expanded(
      child: Obx(
        () => ListView.builder(
          itemCount: cardControllerH.filteredTotales.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Container(
                padding: const EdgeInsets.all(25),
                margin: const EdgeInsets.only(bottom: 5),
                decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.all(const Radius.circular(25)),
                    color: customColors.card),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(bottom: 25),
                          child: Text('Destino de los Huevos',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  color: customColors.texto3)),
                        ),
                      ],
                    ),
                    CustomPieChart(
                        data: [
                      cardControllerH.calcularTotalH2()[3],
                      cardControllerH.calcularTotalH2()[4],
                      cardControllerH.calcularTotalH2()[5],
                      cardControllerH.calcularTotalH2()[6]
                    ].map((numero) => numero.toDouble()).toList()),
                    const Padding(padding: EdgeInsets.only(top: 40)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleColor(
                                color: Colores.azul1,
                                texto: Text('Consumo',
                                    style: TextStyle(
                                        fontSize: 15,
                                        color: customColors.texto3))),
                            CircleColor(
                                color: Colores.rojo1,
                                texto: Text('Venta',
                                    style: TextStyle(
                                        fontSize: 15,
                                        color: customColors.texto3))),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleColor(
                              color: Colores.naranja1,
                              texto: Text('Rotos',
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: customColors.texto3)),
                            ),
                            CircleColor(
                              color: Colores.verde1,
                              texto: Text('Otro',
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: customColors.texto3)),
                            ),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              );
            } else {
              var total = cardControllerH.filteredTotales[index - 1];
              return Tarjeta_totalH(total: total);
            }
          },
        ),
      ),
    );
  }
}

class Tarjeta_totalH extends StatelessWidget {
  final TotalH total;

  Tarjeta_totalH({required this.total});

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return Stack(
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          color: const Color.fromARGB(0, 0, 0, 0),
          elevation: 0,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(25)),
                color: customColors.card),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 20.0, left: 25, right: 50, bottom: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(total.nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w400, fontSize: 20)),
                            Row(
                              children: [
                                Image.asset('assets/income.png',
                                    color: Colors.green),
                                const Padding(
                                    padding: EdgeInsets.only(left: 10.0)),
                                Text('${total.balance.toStringAsFixed(0)} \$',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 20)),
                              ],
                            )
                          ]),
                      const Padding(padding: EdgeInsets.only(top: 10.0)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              /*Image(
                                  image: const AssetImage('assets/goal.png'),
                                  color: customColors.iconos),*/
                              Text('${total.huevosConsumo}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14)),
                              const Text('Consumo',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 13,
                                      color: Colores.gris2)),
                            ],
                          ),
                          Column(
                            children: [
                              /*Image(
                                  image: const AssetImage(
                                      'assets/acquisition.png'),
                                  color: customColors.iconos),*/
                              Text('${total.huevosVendidos}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14)),
                              const Text('Ventas',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 13,
                                      color: Colores.gris2)),
                            ],
                          ),
                          Column(
                            children: [
                              /*Image(
                                  image: const AssetImage(
                                      'assets/acquisition.png'),
                                  color: customColors.iconos),*/
                              Text('${total.huevosRoto}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14)),
                              const Text('Rotos',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 13,
                                      color: Colores.gris2)),
                            ],
                          ),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.only(top: 10.0)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text('${total.huevosOtros}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              const Text('Otros',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 13,
                                      color: Colores.gris2))
                            ],
                          ),
                          Column(
                            children: [
                              Text('${total.huevosTotales}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              const Text('Totales',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 13,
                                      color: Colores.gris2))
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 25,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25)),
                      color: customColors.cardbottom),
                  child: Text(formatearFecha(total.fecha),
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 14)),
                )
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          child: Container(
            margin: const EdgeInsets.only(top: 4, bottom: 4),
            width: 25,
            decoration: BoxDecoration(
              color: getColorForAve(total.ave, customColors),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: RotatedBox(
              quarterTurns: 3,
              child: Center(
                child: Text(
                  total.ave.displayName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TarjetaH extends StatelessWidget {
  final String nombre;
  final Ave ave;
  final int buenos;
  final int rotos;
  final String fecha;

  TarjetaH({
    required this.nombre,
    required this.ave,
    required this.buenos,
    required this.rotos,
    required this.fecha,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return Stack(
      children: [
        Card(
          color: const Color.fromARGB(0, 0, 0, 0),
          elevation: 0,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(25)),
                color: customColors.card),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 20.0, left: 25, right: 25, bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(nombre,
                          style: const TextStyle(
                              fontWeight: FontWeight.w400, fontSize: 20)),
                      const Padding(padding: EdgeInsets.only(left: 10.0)),
                      Column(
                        children: [
                          const Image(image: AssetImage('assets/llema.png')),
                          Text('$rotos',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
                          const Text('Rotos',
                              style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                  color: Colores.gris2)),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.only(top: 10.0)),
                      Column(
                        children: [
                          Image(
                              image: const AssetImage('assets/egg.png'),
                              color: customColors.iconos),
                          Text('$buenos',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
                          const Text('Buenos',
                              style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                  color: Colores.gris2)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 25,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25)),
                      color: customColors.cardbottom),
                  child: Text(fecha,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 14)),
                )
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          child: Container(
            margin: const EdgeInsets.only(top: 4, bottom: 4),
            width: 25,
            decoration: BoxDecoration(
              color: getColorForAve(ave, customColors),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: RotatedBox(
              quarterTurns: 3,
              child: Center(
                child: Text(
                  ave.displayName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class Tarjeta_restarH extends StatelessWidget {
  final String nombre;
  final Ave ave;
  final int huevosMenos;
  final Razon_reduccionH razon;
  final double ingreso;
  final String fecha;

  Tarjeta_restarH(
      {required this.nombre,
      required this.ave,
      required this.huevosMenos,
      required this.razon,
      this.ingreso = 0,
      required this.fecha});

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return Stack(
      children: [
        Card(
          color: const Color.fromARGB(0, 0, 0, 0),
          elevation: 0,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(25)),
                color: customColors.card),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 20.0, left: 25, right: 25, bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(nombre,
                          style: const TextStyle(
                              fontWeight: FontWeight.w400, fontSize: 20)),
                      const Padding(padding: EdgeInsets.only(left: 10.0)),
                      (razon == Razon_reduccionH.Venta)
                          ? Column(
                              children: [
                                Image.asset('assets/income.png',
                                    color: Colors.green),
                                Text('${ingreso.toStringAsFixed(0)} \$',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14)),
                                const Text('Venta',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 13,
                                        color: Colores.gris2)),
                              ],
                            )
                          : Column(
                              children: [
                                Image(
                                    image:
                                        const AssetImage('assets/question.png'),
                                    color: customColors.iconos),
                                Text(razon.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14)),
                                const Text('Uso',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 13,
                                        color: Colores.gris2)),
                              ],
                            ),
                      const Padding(padding: EdgeInsets.only(top: 10.0)),
                      Column(
                        children: [
                          Image(
                              image: const AssetImage('assets/egg.png'),
                              color: customColors.iconos),
                          Text('$huevosMenos',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
                          const Text('Huevos',
                              style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                  color: Colores.gris2)),
                        ],
                      )
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 25,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25)),
                      color: customColors.cardbottom),
                  child: Text(fecha,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 14)),
                )
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          child: Container(
            margin: const EdgeInsets.only(top: 4, bottom: 4),
            width: 25,
            decoration: BoxDecoration(
              color: getColorForAve(ave, customColors),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: RotatedBox(
              quarterTurns: 3,
              child: Center(
                child: Text(
                  ave.displayName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
