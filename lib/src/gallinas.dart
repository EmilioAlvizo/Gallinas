import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'control.dart';
import 'fuente.dart';
import 'opciones.dart';
import 'sqlite.dart';
import 'texto.dart';

enum Ave { Gallina, PavoReal }

extension AveExtension on Ave {
  String get displayName {
    switch (this) {
      case Ave.Gallina:
        return "Gallina";
      case Ave.PavoReal:
        return "Pavo Real";
      default:
        return "";
    }
  }
}

enum Proposito { Huevos, Carne, Ambos }

enum Tipo_adquisicion { Compra, Incubado, Regalo, Otro }

enum Razon_reduccion { Sacrificio, Muerte, Venta, Robo, Otro }

class Suma {
  final String id;
  String nombre;
  Ave ave;
  int avesNuevas;
  Proposito proposito;
  Tipo_adquisicion adquisicion;
  double costo;
  DateTime fecha;

  Suma({
    String? id,
    required this.nombre,
    required this.ave,
    required this.avesNuevas,
    required this.proposito,
    required this.adquisicion,
    this.costo = 0,
    required this.fecha,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'ave': ave.displayName,
      'avesNuevas': avesNuevas,
      'proposito': proposito.toString().split('.').last,
      'adquisicion': adquisicion.toString().split('.').last,
      'costo': costo,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory Suma.fromJson(Map<String, dynamic> json) {
    return Suma(
      id: json['id'],
      nombre: json['nombre'],
      ave: parseEnum(json['ave'], Ave.values),
      /*ave: Ave.values.firstWhere(
          (c) => c.toString().split('.').last == json['ave']),*/
      avesNuevas: json['avesNuevas'],
      proposito: Proposito.values
          .firstWhere((c) => c.toString().split('.').last == json['proposito']),
      adquisicion: Tipo_adquisicion.values.firstWhere(
          (c) => c.toString().split('.').last == json['adquisicion']),
      costo: json['costo'],
      fecha: DateTime.parse(json['fecha']),
    );
  }
}

class Resta {
  final String id;
  String nombre;
  Ave ave;
  int avesMuertas;
  Razon_reduccion razon;
  double ingreso;
  DateTime fecha;

  Resta(
      {String? id,
      required this.nombre,
      required this.ave,
      required this.avesMuertas,
      required this.razon,
      this.ingreso = 0,
      required this.fecha})
      : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'ave': ave.displayName,
      'avesMuertas': avesMuertas,
      'razon': razon.toString().split('.').last,
      'ingreso': ingreso,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory Resta.fromJson(Map<String, dynamic> json) {
    return Resta(
      id: json['id'],
      nombre: json['nombre'],
      ave: parseEnum(json['ave'], Ave.values),
      avesMuertas: json['avesMuertas'],
      razon: Razon_reduccion.values
          .firstWhere((c) => c.toString().split('.').last == json['razon']),
      ingreso: json['ingreso'],
      fecha: DateTime.parse(json['fecha']),
    );
  }
}

class Total {
  String nombre;
  Ave ave;
  int avesVivas;
  Proposito proposito;
  double balance;
  DateTime fecha;
  int avesMuertas;

  Total({
    required this.nombre,
    required this.ave,
    required this.avesVivas,
    required this.proposito,
    required this.balance,
    required this.fecha,
    required this.avesMuertas,
  });
}

class CardController extends GetxController with WidgetsBindingObserver {
  RxList<Suma> sumas = <Suma>[].obs;
  RxList<Resta> restas = <Resta>[].obs;
  RxList<Total> totales = <Total>[].obs;
  final AveControl aveControl = Get.find();
  //final UserSession userSession = Get.find();
  //final DatabaseHelper databaseHelper = Get.find();

  Future<void> loadSumas(String userId) async {
    final sumasData = await DatabaseHelper.instance.getSumas(userId);
    sumas.assignAll(sumasData.map((data) => Suma.fromJson(data)).toList());
  }

  Future<void> loadRestas(String userId) async {
    final restasData = await DatabaseHelper.instance.getRestas(userId);
    restas.value = restasData.map((data) => Resta.fromJson(data)).toList();
  }

  // Método para cargar todos los datos
  Future<void> loadAllData(String userId) async {
    print('pasando datos de gallinas a las variables observables');
    await loadSumas(userId);
    await loadRestas(userId);
    ordenarCronologicamente(sumas);
    ordenarCronologicamente(restas);
    sumas.forEach(calcularTotalSuma);
    restas.forEach(calcularTotalResta);
    print('listo');
    print('sumas $sumas');
    print('restas $restas');
  }

  List<Suma> get filteredSumas {
    if (aveControl.selectedAveFilter.value == 'Todas') {
      return sumas;
    } else {
      return sumas
          .where((total) =>
              total.ave.displayName == aveControl.selectedAveFilter.value)
          .toList();
    }
  }

  List<Resta> get filteredRestas {
    if (aveControl.selectedAveFilter.value == 'Todas') {
      return restas;
    } else {
      return restas
          .where((total) =>
              total.ave.displayName == aveControl.selectedAveFilter.value)
          .toList();
    }
  }

  List<Total> get filteredTotales {
    if (aveControl.selectedAveFilter.value == 'Todas') {
      return totales;
    } else {
      return totales
          .where((total) =>
              total.ave.displayName == aveControl.selectedAveFilter.value)
          .toList();
    }
  }

  void agregarSuma(Suma suma) {
    sumas.add(suma);
    agregarSumaYActualizarTotal(suma);
    addObjeto(suma, 'sumas');
    //print('suma ${suma.toJson()}');
    syncData(suma);
    //databaseHelper.insertSuma(
    //    userSession.usuarioSeleccionado.value!, suma.toJson());
    //editarTotal();
    //calcularTotal(suma.nombre);
    ordenarCronologicamente(sumas);
    ordenarCronologicamente(totales);
    //actualizarSumas(sumas, 'sumas');
  }

  void editarSuma(int index, Suma suma) {
    updateObjeto(sumas[index], suma, 'sumas');
    editarSumaYActualizarTotal(suma);
    syncData(suma);
    //editarTotal();
    //calcularTotal(suma.nombre);
    ordenarCronologicamente(sumas);
    ordenarCronologicamente(totales);
    //actualizarSumas(sumas, 'sumas');
  }

  void eliminarSuma(int index, Suma suma) {
    removeObjeto(suma, 'sumas');
    sumas.removeAt(index);
    eliminarSumaYActualizarTotal(suma);
    deleteObject(suma);
    //calcularTotal(suma.nombre);
    //editarTotal();
    //actualizarSumas(sumas, 'sumas');
  }

  void agregarResta(Resta resta) {
    restas.add(resta);
    agregarRestaYActualizarTotal(resta);
    addObjeto(resta, 'restas');
    syncData(resta);
    // editarTotal();
    //_actualizarMortalidad(resta);
    //calcularTotal(resta.nombre);
    ordenarCronologicamente(restas);
    ordenarCronologicamente(totales);

    //actualizarRestas(restas, 'restas');
    //onClose();
  }

  void editarResta(int index, Resta resta) {
    updateObjeto(restas[index], resta, 'restas');
    editarRestaYActualizarTotal(resta);
    syncData(resta);
    //editarTotal();
    // _actualizarMortalidad(resta);
    //calcularTotal(resta.nombre);
    ordenarCronologicamente(restas);
    ordenarCronologicamente(totales);
    //actualizarRestas(restas, 'restas');
    //onClose();
  }

  void eliminarResta(int index, Resta resta) {
    removeObjeto(resta, 'restas');
    restas.removeAt(index);
    eliminarRestaYActualizarTotal(resta);
    deleteObject(resta);
    //calcularTotal(resta.nombre);
    //editarTotal();
    //actualizarRestas(restas, 'restas');
    //onClose();
  }

  void agregarSumaYActualizarTotal(Suma nuevaSuma) {
    // Buscar si ya existe un total con el mismo nombre y ave
    var totalExistente = totales.firstWhereOrNull((total) =>
        total.nombre == nuevaSuma.nombre && total.ave == nuevaSuma.ave);

    if (totalExistente != null) {
      // Si existe, actualizamos sus valores
      totalExistente.avesVivas += nuevaSuma.avesNuevas;
      totalExistente.balance -= nuevaSuma.costo;
      totalExistente.fecha = nuevaSuma.fecha;
    } else {
      // Si no existe, creamos un nuevo total
      totales.add(Total(
        nombre: nuevaSuma.nombre,
        ave: nuevaSuma.ave,
        avesVivas: nuevaSuma.avesNuevas,
        proposito: nuevaSuma.proposito,
        balance: -nuevaSuma.costo,
        fecha: nuevaSuma.fecha,
        avesMuertas: 0,
      ));
    }
  }

  void agregarRestaYActualizarTotal(Resta nuevaResta) {
    // Buscar si ya existe un total con el mismo nombre y ave
    var totalExistente = totales.firstWhereOrNull((total) =>
        total.nombre == nuevaResta.nombre && total.ave == nuevaResta.ave);

    if (totalExistente != null) {
      // Si existe, actualizamos sus valores
      totalExistente.avesVivas -= nuevaResta.avesMuertas;
      totalExistente.avesMuertas += nuevaResta.avesMuertas;
      totalExistente.balance += nuevaResta.ingreso;
      totalExistente.fecha = nuevaResta.fecha;
    } else {
      // Si no existe, creamos un nuevo total
      // Nota: Esto es inusual, ya que normalmente deberías tener un total antes de restar
      totales.add(Total(
        nombre: nuevaResta.nombre,
        ave: nuevaResta.ave,
        avesVivas: -nuevaResta.avesMuertas,
        proposito:
            Proposito.Ambos, // Valor por defecto, ajusta según sea necesario
        balance: nuevaResta.ingreso,
        fecha: nuevaResta.fecha,
        avesMuertas: nuevaResta.avesMuertas,
      ));
    }
  }

  void editarSumaYActualizarTotal(Suma nuevaSuma) {
    // Encontrar la suma original
    var suma = sumas.firstWhereOrNull((s) => s.id == nuevaSuma.id);
    if (suma == null) {
      print("Suma no encontrada");
      return;
    }

    // Guardar los valores originales antes de la edición
    String nombreOriginal = suma.nombre;
    Ave aveOriginal = suma.ave;
    int avesCompradasOriginal = suma.avesNuevas;
    double? precioOriginal = suma.costo;

    // Actualizar la suma con los nuevos valores
    suma.nombre = nuevaSuma.nombre;
    suma.ave = nuevaSuma.ave;
    suma.avesNuevas = nuevaSuma.avesNuevas;
    suma.costo = nuevaSuma.costo;
    suma.fecha = nuevaSuma.fecha;
    suma.proposito = nuevaSuma.proposito;
    suma.adquisicion = nuevaSuma.adquisicion;

    // Encontrar el total correspondiente
    var sumasNombre =
        sumas.where((s) => (s.nombre == suma.nombre) && (s.ave == suma.ave));
    var total = totales.firstWhereOrNull(
        (t) => t.nombre == nombreOriginal && t.ave == aveOriginal);

    if (total != null) {
      // Ajustar el total
      total.avesVivas -= avesCompradasOriginal;
      total.balance += precioOriginal;

      // Si el nombre o el ave han cambiado
      if (nombreOriginal != suma.nombre || aveOriginal != suma.ave) {
        // Buscar o crear un nuevo total para el nuevo nombre/ave
        var nuevoTotal = totales.firstWhereOrNull(
            (t) => t.nombre == suma.nombre && t.ave == suma.ave);
        if (nuevoTotal == null) {
          totales.add(Total(
            nombre: suma.nombre,
            ave: suma.ave,
            avesVivas: suma.avesNuevas,
            proposito: suma.proposito,
            balance: -suma.costo,
            fecha: suma.fecha,
            avesMuertas: 0,
          ));
        } else {
          nuevoTotal.avesVivas += suma.avesNuevas;
          nuevoTotal.balance -= suma.costo;
          nuevoTotal.fecha =
              _fechaReciente(sumasNombre.toList(), DateTime(1800, 4, 20));
        }

        // Eliminar el total original si ya no tiene sumas asociadas
        if (!sumas
            .any((s) => s.nombre == nombreOriginal && s.ave == aveOriginal)) {
          totales.remove(total);
        }
      } else {
        total.avesVivas += suma.avesNuevas;
        total.balance -= suma.costo;
        total.fecha =
            _fechaReciente(sumasNombre.toList(), DateTime(1800, 4, 20));
      }
    } else {
      print("Total correspondiente no encontrado");
      // Crear un nuevo total
      totales.add(Total(
        nombre: suma.nombre,
        ave: suma.ave,
        avesVivas: suma.avesNuevas,
        proposito: suma.proposito,
        balance: -suma.costo,
        fecha: suma.fecha,
        avesMuertas: 0,
      ));
    }

    // Notificar a GetX que los datos han cambiado
    sumas.refresh();
    totales.refresh();
  }

  void editarRestaYActualizarTotal(Resta nuevaResta) {
    // Encontrar la resta original
    var resta = restas.firstWhereOrNull((r) => r.id == nuevaResta.id);
    if (resta == null) {
      print("Resta no encontrada");
      return;
    }

    // Guardar los valores originales antes de la edición
    String nombreOriginal = resta.nombre;
    Ave aveOriginal = resta.ave;
    int avesMuertasOriginal = resta.avesMuertas;
    double ingresoOriginal = resta.ingreso;

    // Actualizar la resta con los nuevos valores
    resta.nombre = nuevaResta.nombre;
    resta.ave = nuevaResta.ave;
    resta.avesMuertas = nuevaResta.avesMuertas;
    resta.ingreso = nuevaResta.ingreso;
    resta.fecha = nuevaResta.fecha;
    resta.razon = nuevaResta.razon;

    // Encontrar el total correspondiente
    var restasNombre =
        restas.where((s) => (s.nombre == resta.nombre) && (s.ave == resta.ave));
    var total = totales.firstWhereOrNull(
        (t) => t.nombre == nombreOriginal && t.ave == aveOriginal);

    if (total != null) {
      // Ajustar el total
      total.avesVivas += avesMuertasOriginal;
      total.avesMuertas -= avesMuertasOriginal;
      total.balance -= ingresoOriginal;

      // Si el nombre o el ave han cambiado
      if (nombreOriginal != resta.nombre || aveOriginal != resta.ave) {
        // Buscar o crear un nuevo total para el nuevo nombre/ave
        var nuevoTotal = totales.firstWhereOrNull(
            (t) => t.nombre == resta.nombre && t.ave == resta.ave);
        if (nuevoTotal == null) {
          totales.add(Total(
            nombre: resta.nombre,
            ave: resta.ave,
            avesVivas: -resta.avesMuertas,
            proposito: total.proposito, // Mantener el propósito original
            balance: resta.ingreso,
            fecha: resta.fecha,
            avesMuertas: resta.avesMuertas,
          ));
        } else {
          nuevoTotal.avesVivas -= resta.avesMuertas;
          nuevoTotal.avesMuertas += resta.avesMuertas;
          nuevoTotal.balance += resta.ingreso;
          nuevoTotal.fecha =
              _fechaReciente(restasNombre.toList(), DateTime(1800, 4, 20));
        }

        // Eliminar el total original si ya no tiene restas asociadas
        if (!restas.any(
                (r) => r.nombre == nombreOriginal && r.ave == aveOriginal) &&
            !sumas.any(
                (s) => s.nombre == nombreOriginal && s.ave == aveOriginal)) {
          totales.remove(total);
        }
      } else {
        total.avesVivas -= resta.avesMuertas;
        total.avesMuertas += resta.avesMuertas;
        total.balance += resta.ingreso;
        total.fecha =
            _fechaReciente(restasNombre.toList(), DateTime(1800, 4, 20));
      }
    } else {
      print("Total correspondiente no encontrado");
      // Crear un nuevo total
      totales.add(Total(
        nombre: resta.nombre,
        ave: resta.ave,
        avesVivas: -resta.avesMuertas,
        proposito:
            Proposito.Ambos, // Valor por defecto, ajusta según sea necesario
        balance: resta.ingreso,
        fecha: resta.fecha,
        avesMuertas: resta.avesMuertas,
      ));
    }

    // Notificar a GetX que los datos han cambiado
    restas.refresh();
    totales.refresh();
  }

  void eliminarSumaYActualizarTotal(Suma sumaAEliminar) {
    // Buscar el total correspondiente
    var sumasNombre = sumas.where((s) =>
        (s.nombre == sumaAEliminar.nombre) && (s.ave == sumaAEliminar.ave));
    var totalExistente = totales.firstWhereOrNull((total) =>
        total.nombre == sumaAEliminar.nombre && total.ave == sumaAEliminar.ave);

    if (totalExistente != null) {
      // Actualizar el total
      totalExistente.avesVivas -= sumaAEliminar.avesNuevas;
      totalExistente.balance += sumaAEliminar.costo;

      // Si el total de aves vivas llega a cero y no hay aves muertas, eliminar el total
      if (totalExistente.avesVivas <= 0 && totalExistente.avesMuertas <= 0) {
        totales.remove(totalExistente);
      } else {
        // Actualizar la fecha al último movimiento
        totalExistente.fecha =
            _fechaReciente(sumasNombre.toList(), DateTime(1800, 4, 20));
      }
    }
  }

  void eliminarRestaYActualizarTotal(Resta restaAEliminar) {
    // Buscar el total correspondiente
    var restasNombre = restas.where((s) =>
        (s.nombre == restaAEliminar.nombre) && (s.ave == restaAEliminar.ave));
    var totalExistente = totales.firstWhereOrNull((total) =>
        total.nombre == restaAEliminar.nombre &&
        total.ave == restaAEliminar.ave);

    if (totalExistente != null) {
      // Actualizar el total
      totalExistente.avesVivas += restaAEliminar.avesMuertas;
      totalExistente.avesMuertas -= restaAEliminar.avesMuertas;
      totalExistente.balance -= restaAEliminar.ingreso;

      // Si el total de aves vivas y muertas llega a cero, eliminar el total
      if (totalExistente.avesVivas <= 0 && totalExistente.avesMuertas <= 0) {
        totales.remove(totalExistente);
      } else {
        // Actualizar la fecha al último movimiento
        totalExistente.fecha =
            _fechaReciente(restasNombre.toList(), DateTime(1800, 4, 20));
      }
    }
  }

  /*void _actualizarMortalidad(Resta resta) {
    final index = sumas.indexWhere((suma) => suma.nombre == resta.nombre);
    if (index != -1) {
      sumas[index] = Suma(
        id: sumas[index].id,
        nombre: sumas[index].nombre,
        nombre: sumas[index].nombre,
        avesNuevas: sumas[index].avesNuevas,
        proposito: sumas[index].proposito,
        adquisicion: sumas[index].adquisicion,
        costo: sumas[index].costo,
        fecha: sumas[index].fecha,
      );
    }
  }*/

  void editarTotal() {
    List<String> nombres = sumas.map((suma) => suma.nombre).toList();
    totales.removeWhere((total) => !nombres.contains(total.nombre));
  }

  void calcularTotalSuma(Suma suma) {
    var sumasFecha =
        sumas.where((s) => s.nombre == suma.nombre && s.ave == suma.ave);
    var restasFecha =
        restas.where((s) => s.nombre == suma.nombre && s.ave == suma.ave);
    var totalNombre = totales.firstWhereOrNull(
        (t) => (t.nombre == suma.nombre) && (t.ave == suma.ave));
    if (totalNombre != null) {
      totalNombre.avesVivas += suma.avesNuevas;
      totalNombre.balance -= suma.costo;
      totalNombre.fecha = _fechaReciente(
          [...sumasFecha, ...restasFecha], DateTime(1800, 4, 20));
      // Procesar ave2
    } else {
      //print('totalNombre es null');
      totales.add(Total(
        nombre: suma.nombre,
        ave: suma.ave,
        avesVivas: suma.avesNuevas,
        proposito: suma.proposito,
        balance: -suma.costo,
        avesMuertas: 0,
        fecha: suma.fecha,
      ));
      ordenarCronologicamente(totales);
      // Manejar el caso cuando no se encuentra ningún elemento
    }
  }

  void calcularTotalResta(Resta resta) {
    var sumasFecha =
        sumas.where((s) => s.nombre == resta.nombre && s.ave == resta.ave);
    var restasFecha =
        restas.where((s) => s.nombre == resta.nombre && s.ave == resta.ave);
    var totalNombre = totales.firstWhereOrNull(
        (t) => (t.nombre == resta.nombre) && (t.ave == resta.ave));
    if (totalNombre != null) {
      totalNombre.avesVivas -= resta.avesMuertas;
      totalNombre.balance += resta.ingreso;
      totalNombre.avesMuertas += resta.avesMuertas;
      totalNombre.fecha = _fechaReciente(
          [...sumasFecha, ...restasFecha], DateTime(1800, 4, 20));
      // Procesar ave2
    } else {
      print('calcularTotalResta -- totalNombre es null');
      ordenarCronologicamente(totales);
      // Manejar el caso cuando no se encuentra ningún elemento
    }
  }

  List<num> calcularTotal2() {
    double totalDinero = 0;
    int totalGallinas = 0;
    int totalMuertes = 0;

    for (var total in filteredTotales) {
      totalDinero += total.balance;
      totalGallinas += total.avesVivas;
      totalMuertes += total.avesMuertas;
    }

    return [totalGallinas, totalDinero, totalMuertes];
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
}

class Gallinas extends StatelessWidget {
  final CardController cardController = Get.find();
  final AveControl aveControl = Get.find();
  final controlador;
  Gallinas({super.key, required this.controlador});

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    print('empezo gallinas');
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
                    controlador.pageController.jumpToPage(0);
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
                    controlador.pageController.jumpToPage(1);
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
                    controlador.pageController.jumpToPage(2);
                  },
                ),
              ],
            ),
          ),
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
                      //cardController.updateFilteredTotals();
                    },
                    items: ['Todas', ...Ave.values.map((e) => e.displayName)]
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                  )),
            ],
          ),
          // aqui pon un boton para selecionar el tipo de ave o para ver todas
          Obx(() => _getBody(controlador.botonIndex.value, context)),
        ],
      ),
    );
  }

  Widget _getBody(int index, BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return Expanded(
      child: PageView(
        controller: controlador.pageController,
        onPageChanged: controlador.onPageChanged,
        children: [
          Stack(alignment: Alignment.center, children: [
            Container(
                child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Caja(
                        color1: customColors.card2!,
                        color2: customColors.linea!,
                        txt1: '${cardController.calcularTotal2()[0]}',
                        txt2: aveControl.selectedAveFilter.value),
                    const Padding(padding: EdgeInsets.only(left: 10.0)),
                    Caja(
                        color1: customColors.card3!,
                        color2: customColors.linea2!,
                        txt1: '${cardController.calcularTotal2()[1].toStringAsFixed(0)} \$',
                        txt2: 'Neto',
                        oscuro: true),
                    const Padding(padding: EdgeInsets.only(left: 10.0)),
                    Caja(
                        color1: customColors.card4!,
                        color2: customColors.linea3!,
                        txt1: '${cardController.calcularTotal2()[2]}',
                        txt2: 'Muertes',
                        oscuro: true),
                  ],
                ),
                const Padding(padding: EdgeInsets.only(top: 10)),
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
          ]),
        ],
      ),
    );

    /*switch (index) {
      case 1:
        return Expanded(
            child: Stack(alignment: Alignment.center, children: [
          Container(
              child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Caja(
                      color1: const Color(0xff1C9D74),
                      color2: const Color(0xff72C0A5),
                      txt1: '${cardController.calcularTotal2()[0]}',
                      txt2: 'Gallinas'),
                  const Padding(padding: EdgeInsets.only(left: 10.0)),
                  Caja(
                      color1: const Color(0xffDFECEE),
                      color2: const Color.fromRGBO(68, 148, 172, 0.5),
                      txt1: '${cardController.calcularTotal2()[1]} \$',
                      txt2: 'Neto',
                      oscuro: true),
                  const Padding(padding: EdgeInsets.only(left: 10.0)),
                  Caja(
                      color1: const Color(0xffEFE0DC),
                      color2: const Color.fromRGBO(202, 124, 116, 0.5),
                      txt1: '${cardController.calcularTotal2()[2]}',
                      txt2: 'Muertes',
                      oscuro: true),
                ],
              ),
              const Padding(padding: EdgeInsets.only(top: 10)),
              _MostrarTotales(),
            ],
          ))
        ]));
      case 2:
        return Expanded(
          child: Stack(alignment: Alignment.center, children: [
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
        );
      case 3:
        return Expanded(
          child: Stack(alignment: Alignment.center, children: [
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
          ]),
        );
      default:
        return const Center(child: Text('Error: Page not found'));
    }*/
  }
}

void mostrarDialogo(BuildContext context, {Suma? suma, int? index}) {
  final _formKey = GlobalKey<FormState>();
  final CardController cardController = Get.find();
  TextEditingController idC = TextEditingController();
  TextEditingController nombreC = TextEditingController();
  TextEditingController aveC = TextEditingController();
  TextEditingController nuevasAvesC = TextEditingController();
  TextEditingController propositoC = TextEditingController();
  TextEditingController adquisicionC = TextEditingController();
  TextEditingController costoC = TextEditingController();
  TextEditingController fechaC = TextEditingController();
  var bool5 = false.obs;

  if (suma != null) {
    (suma.adquisicion == Tipo_adquisicion.Compra)
        ? bool5.value = true
        : bool5.value = false;
    idC = TextEditingController(text: suma.id);
    nombreC = TextEditingController(text: suma.nombre);
    aveC = TextEditingController(text: suma.ave.displayName);
    nuevasAvesC = TextEditingController(text: suma.avesNuevas.toString());
    propositoC = TextEditingController(text: suma.proposito.name.toString());
    adquisicionC =
        TextEditingController(text: suma.adquisicion.name.toString());
    costoC = TextEditingController(text: suma.costo.toString());
    fechaC = TextEditingController(text: DateFormat.yMd().format(suma.fecha));
    print('fecha ${suma.fecha}');
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Agregar Ave'),
        content: SingleChildScrollView(
          child: Container(
            width: double.maxFinite,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(padding: EdgeInsets.only(top: 3)),
                  TextFormField(
                    controller: nombreC,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      suffixIcon: ClearButton(controller: nombreC),
                      labelText: 'Nombre de bandada/grupo',
                      helperText: '* requerido',
                      filled: false,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, introduzca un texto';
                      }
                      return null;
                    },
                  ),
                  const Padding(padding: EdgeInsets.only(top: 3)),
                  DropdownMenu<Ave>(
                    enableSearch: false,
                    expandedInsets: const EdgeInsets.all(0.0),
                    controller: aveC,
                    label: const Text('Ave'),
                    helperText: '* requerido',
                    dropdownMenuEntries:
                        Ave.values.map<DropdownMenuEntry<Ave>>((Ave ave) {
                      return DropdownMenuEntry<Ave>(
                        value: ave,
                        label: ave.displayName,
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
                          controller: nuevasAvesC,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            suffixIcon: ClearButton(controller: nuevasAvesC),
                            labelText: 'No. de aves',
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
                        child: DropdownMenu<Proposito>(
                          enableSearch: false,
                          expandedInsets: const EdgeInsets.all(0.0),
                          controller: propositoC,
                          label: const Text('Proposito'),
                          helperText: '* requerido',
                          //enableFilter: true,
                          dropdownMenuEntries: Proposito.values
                              .map<DropdownMenuEntry<Proposito>>(
                                  (Proposito tipo) {
                            return DropdownMenuEntry<Proposito>(
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
                  if (suma == null)
                    DatePicker(control: fechaC, texto: 'Fecha de adquisición'),
                  if (suma != null)
                    DatePicker(
                        control: fechaC,
                        texto: 'Fecha de adquisición',
                        initialDate: suma.fecha),
                  const Padding(padding: EdgeInsets.only(top: 10)),
                  SizedBox(
                    child: DropdownMenu<Tipo_adquisicion>(
                      //IgnorePointer
                      expandedInsets: const EdgeInsets.all(0.0),
                      controller: adquisicionC,
                      label: const Text('Tipo de adquisicion'),
                      helperText: '* requerido',
                      onSelected: (newValue) {
                        if (newValue != null) {
                          if (newValue == Tipo_adquisicion.Compra) {
                            bool5.value = true;
                          } else {
                            bool5.value = false;
                          }
                        }
                      },
                      //enableFilter: true,
                      dropdownMenuEntries: Tipo_adquisicion.values
                          .map<DropdownMenuEntry<Tipo_adquisicion>>(
                              (Tipo_adquisicion tipo) {
                        return DropdownMenuEntry<Tipo_adquisicion>(
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
                  const Padding(padding: EdgeInsets.only(top: 10)),
                  Obx(() {
                    if (bool5.value) {
                      return TextFormField(
                        //maxLength: 10,
                        //maxLengthEnforcement: MaxLengthEnforcement.none,
                        controller: costoC,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          suffixIcon: ClearButton(controller: costoC),
                          labelText: 'Costo de adquisicion',
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
              if (_formKey.currentState!.validate() &&
                  adquisicionC.text.isNotEmpty &&
                  aveC.text.isNotEmpty &&
                  propositoC.text.isNotEmpty) {
                if (suma != null) {
                  cardController.editarSuma(
                      index!,
                      Suma(
                        id: idC.text,
                        nombre: nombreC.text,
                        ave: parseEnum(aveC.text, Ave.values),
                        avesNuevas: int.parse(nuevasAvesC.text),
                        proposito: parseEnum(propositoC.text, Proposito.values),
                        adquisicion: parseEnum(
                            adquisicionC.text, Tipo_adquisicion.values),
                        //costo: double.parse(costoC.text),
                        costo: (costoC.text.isEmpty
                            ? 0.0
                            : double.parse(costoC.text)),
                        fecha: DateFormat('M/d/yyyy').parse(fechaC.text),
                      ));
                } else {
                  cardController.agregarSuma(
                    Suma(
                      nombre: nombreC.text,
                      ave: parseEnum(aveC.text, Ave.values),
                      avesNuevas: int.parse(nuevasAvesC.text),
                      proposito: parseEnum(propositoC.text, Proposito.values),
                      adquisicion:
                          parseEnum(adquisicionC.text, Tipo_adquisicion.values),
                      //costo: double.parse(costoC.text),
                      costo: (costoC.text.isEmpty
                          ? 0.0
                          : double.parse(costoC.text)),
                      fecha: DateFormat('M/d/yyyy').parse(fechaC.text),
                    ),
                  );
                }
                Navigator.of(context).pop();
              } else {
                print('faltan campos por llenar');
                Get.snackbar('Error', 'Faltan campos por llenar');
              }
            },
          ),
        ],
      );
    },
  );
}

void mostrarDialogo2(BuildContext context, {Resta? resta, int? index}) {
  final _formKey = GlobalKey<FormState>();
  final CardController cardController = Get.find();
  TextEditingController idC = TextEditingController();
  TextEditingController nombreC = TextEditingController();
  TextEditingController avesMuertasC = TextEditingController();
  TextEditingController razonC = TextEditingController();
  TextEditingController ingresoC = TextEditingController();
  TextEditingController fechaC = TextEditingController();
  var bool5 = false.obs;

  Total? selectedTotal = null;
  if (resta != null) {
    (resta.razon == Razon_reduccion.Venta)
        ? bool5.value = true
        : bool5.value = false;
    idC = TextEditingController(text: resta.id);
    nombreC = TextEditingController(text: resta.nombre);
    razonC = TextEditingController(text: resta.razon.name.toString());
    ingresoC = TextEditingController(text: resta.ingreso.toString());
    fechaC = TextEditingController(text: DateFormat.yMd().format(resta.fecha));
    avesMuertasC = TextEditingController(text: resta.avesMuertas.toString());
    selectedTotal = cardController.totales.firstWhere(
        (total) => total.nombre == resta.nombre && total.ave == resta.ave);
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Reducir Aves'),
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
                          controller: avesMuertasC,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            suffixIcon: ClearButton(controller: avesMuertasC),
                            labelText: 'No. de aves',
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
                        child: DropdownMenu<Razon_reduccion>(
                          expandedInsets: const EdgeInsets.all(0.0),
                          controller: razonC,
                          label: const Text('Razon de reducción'),
                          helperText: '* requerido',
                          onSelected: (newValue) {
                            if (newValue != null) {
                              if (newValue == Razon_reduccion.Venta) {
                                bool5.value = true;
                              } else {
                                bool5.value = false;
                              }
                            }
                          },
                          //enableFilter: true,
                          dropdownMenuEntries: Razon_reduccion.values
                              .map<DropdownMenuEntry<Razon_reduccion>>(
                                  (Razon_reduccion tipo) {
                            return DropdownMenuEntry<Razon_reduccion>(
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
                          labelText: 'Ingreso de venta',
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
              /*var uuid = Uuid();
              for (var resta in cardController.restas) {
                resta.id = uuid.v4(); // Genera un nuevo ID único
                addObjeto(resta, 'restas');
                print(resta.id);
              }*/
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            child: const Text('Agregar'),
            onPressed: () {
              if (_formKey.currentState!.validate() &&
                  nombreC.text.isNotEmpty &&
                  razonC.text.isNotEmpty) {
                if (resta != null) {
                  cardController.editarResta(
                      index!,
                      Resta(
                          id: idC.text,
                          nombre: nombreC.text,
                          ave: selectedTotal!.ave,
                          avesMuertas: int.parse(avesMuertasC.text),
                          razon: parseEnum(razonC.text, Razon_reduccion.values),
                          //costo: double.parse(costoC.text),
                          ingreso: (ingresoC.text.isEmpty
                              ? 0.0
                              : double.parse(ingresoC.text)),
                          fecha: DateFormat('M/d/yyyy')
                              .parse(fechaC.text) //DateTime.parse(fechaC.text),
                          ));
                } else {
                  cardController.agregarResta(
                    Resta(
                        nombre: nombreC.text,
                        ave: selectedTotal!.ave,
                        avesMuertas: int.parse(avesMuertasC.text),
                        razon: parseEnum(razonC.text, Razon_reduccion.values),
                        //costo: double.parse(costoC.text),
                        ingreso: (ingresoC.text.isEmpty
                            ? 0.0
                            : double.parse(ingresoC.text)),
                        fecha: DateFormat('M/d/yyyy')
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
  final CardController cardController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(
        () => ListView.builder(
          itemCount: cardController.filteredSumas.length,
          itemBuilder: (context, index) {
            var suma = cardController.filteredSumas[index];
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
                            cardController.eliminarSuma(index, suma);
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
              child: Tarjeta(
                nombre: suma.nombre,
                ave: suma.ave,
                avesNuevas: suma.avesNuevas,
                proposito: suma.proposito,
                adquisicion: suma.adquisicion,
                costo: suma.costo,
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
  final CardController cardController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(
        () => ListView.builder(
          itemCount: cardController.filteredRestas.length,
          itemBuilder: (context, index) {
            var resta = cardController.filteredRestas[index];
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
                            cardController.eliminarResta(index, resta);
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
              child: Tarjeta_restar(
                nombre: resta.nombre,
                ave: resta.ave,
                avesMuertas: resta.avesMuertas,
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
  final CardController cardController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(
        () => ListView.builder(
          itemCount: cardController.filteredTotales.length,
          itemBuilder: (context, index) {
            var total = cardController.filteredTotales[index];
            return Tarjeta_total(
              nombre: total.nombre,
              ave: total.ave,
              avesVivas: total.avesVivas,
              proposito: total.proposito,
              balance: total.balance,
              fecha: formatearFecha(total.fecha),
              avesMuertas: total.avesMuertas,
            );
          },
        ),
      ),
    );
  }
}

class Tarjeta_total extends StatelessWidget {
  final String nombre;
  final Ave ave;
  final int avesVivas;
  final Proposito proposito;
  final double balance;
  final String fecha;
  final int avesMuertas;

  Tarjeta_total(
      {required this.nombre,
      required this.ave,
      required this.avesVivas,
      required this.proposito,
      this.balance = 0.0,
      required this.fecha,
      required this.avesMuertas});

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
                            Text(nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w400, fontSize: 20)),
                            Row(
                              children: [
                                Image(
                                    image:
                                        const AssetImage('assets/chicken.png'),
                                    color: customColors.iconos),
                                const Padding(
                                    padding: EdgeInsets.only(left: 20.0)),
                                Text('$avesVivas',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 32)),
                              ],
                            )
                          ]),
                      const Padding(padding: EdgeInsets.only(top: 10.0)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Image(
                                  image: const AssetImage('assets/goal.png'),
                                  color: customColors.iconos),
                              Text(proposito.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14)),
                              const Text('Proposito',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 13,
                                      color: Colores.gris2)),
                            ],
                          ),
                          Column(
                            children: [
                              Image(
                                  image: const AssetImage(
                                      'assets/acquisition.png'),
                                  color: customColors.iconos),
                              Text('${balance.toStringAsFixed(0)} \$',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14)),
                              const Text('Balance',
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
                              Text('$avesMuertas',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.red)),
                              const Text('Muertes',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 13,
                                      color: Colores.gris2))
                            ],
                          ),
                          Image(
                              image: const AssetImage('assets/skull.png'),
                              color: customColors.iconos),
                          Column(
                            children: [
                              Text(
                                  '${((avesMuertas / (avesVivas + avesMuertas)) * 100).toStringAsFixed(2)} %',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.red)),
                              const Text('Mortalidad',
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
            margin: EdgeInsets.only(top: 4, bottom: 4),
            width: 25,
            decoration: BoxDecoration(
              color: getColorForAve(ave, customColors),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: RotatedBox(
              quarterTurns: 3,
              child: Center(
                child: Text(
                  ave.displayName,
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class Tarjeta extends StatelessWidget {
  final String nombre;
  final Ave ave;
  final int avesNuevas;
  final Proposito proposito;
  final Tipo_adquisicion adquisicion;
  final double costo;
  final String fecha;

  Tarjeta(
      {required this.nombre,
      required this.ave,
      required this.avesNuevas,
      required this.proposito,
      required this.adquisicion,
      this.costo = 0.0,
      required this.fecha});

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
                            Text(nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w400, fontSize: 20)),
                            Row(
                              children: [
                                Image(
                                    image:
                                        const AssetImage('assets/chicken.png'),
                                    color: customColors.iconos),
                                const Padding(
                                    padding: EdgeInsets.only(left: 20.0)),
                                Text('$avesNuevas',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 32)),
                              ],
                            )
                          ]),
                      const Padding(padding: EdgeInsets.only(top: 10.0)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Image(
                                  image: const AssetImage('assets/goal.png'),
                                  color: customColors.iconos),
                              Text(proposito.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14)),
                              const Text('Proposito',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 13,
                                      color: Colores.gris2)),
                            ],
                          ),
                          Column(
                            children: [
                              Image(
                                  image: const AssetImage(
                                      'assets/acquisition.png'),
                                  color: customColors.iconos),
                              Text(adquisicion.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14)),
                              const Text('Adquisicion',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 13,
                                      color: Colores.gris2)),
                            ],
                          ),
                          if (adquisicion == Tipo_adquisicion.Compra)
                            Column(
                              children: [
                                Image.asset('assets/outcome.png',
                                    color: Colors.red),
                                Text('${costo.toStringAsFixed(0)} \$',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14)),
                                const Text('Costo',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 13,
                                        color: Colores.gris2)),
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
            margin: EdgeInsets.only(top: 4, bottom: 4),
            width: 25,
            decoration: BoxDecoration(
              color: getColorForAve(ave, customColors),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: RotatedBox(
              quarterTurns: 3,
              child: Center(
                child: Text(
                  ave.displayName,
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class Tarjeta_restar extends StatelessWidget {
  final String nombre;
  final Ave ave;
  final int avesMuertas;
  final Razon_reduccion razon;
  final double ingreso;
  final String fecha;

  Tarjeta_restar({
    required this.nombre,
    required this.ave,
    required this.avesMuertas,
    required this.razon,
    required this.fecha,
    this.ingreso = 0.0,
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
                          Image(
                              image: const AssetImage('assets/question.png'),
                              color: customColors.iconos),
                          Text(razon.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
                          const Text('Razon',
                              style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                  color: Colores.gris2)),
                        ],
                      ),
                      if (razon == Razon_reduccion.Venta)
                        Column(
                          children: [
                            Image.asset('assets/income.png',
                                color: Colors.green),
                            Text('${ingreso.toStringAsFixed(0)} \$',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 14)),
                            const Text('Ingreso',
                                style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 13,
                                    color: Colores.gris2)),
                          ],
                        ),
                      const Padding(padding: EdgeInsets.only(top: 10.0)),
                      Row(
                        children: [
                          Image.asset('assets/reduction.png',
                              color: Colors.red),
                          const Padding(padding: EdgeInsets.only(left: 20.0)),
                          Text('$avesMuertas',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 32)),
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
            margin: EdgeInsets.only(top: 4, bottom: 4),
            width: 25,
            decoration: BoxDecoration(
              color: getColorForAve(ave, customColors),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: RotatedBox(
              quarterTurns: 3,
              child: Center(
                child: Text(
                  ave.displayName,
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
