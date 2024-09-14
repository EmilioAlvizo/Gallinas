import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:uuid/uuid.dart';

import 'sqlite.dart';
import 'control.dart';
import 'fuente.dart';
import 'gallinas.dart';
import 'opciones.dart';
import 'texto.dart';

class SumaC {
  final String id;
  String nombre;
  Ave ave;
  double cantidad;
  DateTime fecha;
  double? _precio = 0; // Precio
  double? _precioUnitario = 0; // Precio unitario
  DateTime? fechaTermino;

  // Constructor
  SumaC(
      {String? id,
      required this.nombre,
      required this.ave,
      required this.cantidad,
      required this.fecha,
      double? precio,
      double? precioUnitario,
      this.fechaTermino})
      : id = id ?? const Uuid().v4() {
    // Si se proporciona el precio, calcula el precio unitario
    if (precio != null) {
      _precio = precio;
      _precioUnitario = precio / cantidad;
    }
    // Si se proporciona el precio unitario, calcula el precio
    else if (precioUnitario != null) {
      _precioUnitario = precioUnitario;
      _precio = precioUnitario * cantidad;
    }
  }

  // Getters para el precio y el precio unitario
  double? get precio => _precio;
  double? get precioUnitario => _precioUnitario;

  set precio(double? value) {
    _precio = value;
    if (value != null) {
      _precioUnitario = value / cantidad;
    } else {
      _precioUnitario = null;
    }
  }

  set precioUnitario(double? value) {
    _precioUnitario = value;
    if (value != null) {
      _precio = value * cantidad;
    } else {
      _precio = null;
    }
  }

  void setFechaTermino(DateTime fecha) {
    fechaTermino = fecha;
  }

  // Obtener la duración total en días
  int get duracionTotal {
    if (fechaTermino != null) {
      return fechaTermino!.difference(fecha).inDays;
    } else {
      return DateTime.now().difference(fecha).inDays;
    }
  }

  DateTime get fechafinal {
    if (fechaTermino != null) {
      return fechaTermino!;
    } else {
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      return today;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'ave': ave.displayName,
      'cantidad': cantidad,
      'precio': precio,
      'precioUnitario': precioUnitario,
      'fecha': fecha.toIso8601String(),
      'fechaTermino': fechaTermino?.toIso8601String(),
    };
  }

  factory SumaC.fromJson(Map<String, dynamic> json) {
    return SumaC(
      id: json['id'],
      nombre: json['nombre'],
      ave: parseEnum(json['ave'], Ave.values),
      cantidad: (json['cantidad'] as num).toDouble(),
      precio: json['precio'],
      precioUnitario: json['precioUnitario'],
      fecha: DateTime.parse(json['fecha']),
      fechaTermino: json['fechaTermino'] != null
          ? DateTime.parse(json['fechaTermino'])
          : null,
    );
  }
}

class TotalC {
  String nombre;
  Ave ave;
  double cantidad;
  double egreso;
  DateTime fecha;

  TotalC({
    required this.nombre,
    required this.ave,
    required this.cantidad,
    required this.egreso,
    required this.fecha,
  });
}

class CardControllerC extends GetxController {
  RxList<SumaC> sumas = <SumaC>[].obs;
  RxList<TotalC> totales = <TotalC>[].obs;
  final AveControl aveControl = Get.find();

  Future<void> loadSumas(String userId) async {
    final sumasData = await DatabaseHelper.instance.getSumasC(userId);
    sumas.value = sumasData.map((data) => SumaC.fromJson(data)).toList();
  }
  // Método para cargar todos los datos
  Future<void> loadAllData(String userId) async {
    print('pasando datos de comida a las variables observables');
    await loadSumas(userId);
    ordenarCronologicamente(sumas);
    sumas.forEach(calcularTotalC);
  }


  List<SumaC> get filteredSumas {
    if (aveControl.selectedAveFilter.value == 'Todas') {
      return sumas;
    } else {
      return sumas
          .where((total) => total.ave.displayName == aveControl.selectedAveFilter.value)
          .toList();
    }
  }
  List<TotalC> get filteredTotales {
    if (aveControl.selectedAveFilter.value == 'Todas') {
      return totales;
    } else {
      return totales
          .where((total) => total.ave.displayName == aveControl.selectedAveFilter.value)
          .toList();
    }
  }

  void agregarSumaC(SumaC nuevaSuma) {
    // Primero, agregamos la nueva suma a la lista de sumas
    sumas.add(nuevaSuma);
    agregarSumaYActualizarTotal(nuevaSuma);
    ordenarCronologicamente(sumas);
    ordenarCronologicamente(totales);
    addObjeto(nuevaSuma, 'sumasC');
    syncData(nuevaSuma);
    //actualizarSumas(sumas, 'sumasC');
  }

  void editarSumaC(int index, SumaC suma) {
    editarSumaYActualizarTotal(suma);
    updateObjeto(sumas[index], suma, 'sumasC');
    ordenarCronologicamente(sumas);
    ordenarCronologicamente(totales);
    syncData(suma);
    //actualizarSumas(sumas, 'sumasC');
  }

  void eliminarSumaC(int index, SumaC suma) {
    eliminarSumaYActualizarTotal(suma);
    removeObjeto(suma, 'sumasC');
    deleteObject(suma);
    //actualizarSumas(sumas, 'sumasC');
  }

  void agregarSumaYActualizarTotal(SumaC nuevaSuma) {
    // Buscamos si ya existe un total con el mismo nombre y ave
    var totalExistente = totales.firstWhereOrNull((total) =>
        total.nombre == nuevaSuma.nombre && total.ave == nuevaSuma.ave);

    if (totalExistente != null) {
      // Si existe, actualizamos sus valores
      totalExistente.cantidad += nuevaSuma.cantidad;
      totalExistente.egreso += nuevaSuma.precio ?? 0;
      totalExistente.fecha = nuevaSuma.fecha;
    } else {
      // Si no existe, creamos un nuevo total
      totales.add(TotalC(
        nombre: nuevaSuma.nombre,
        ave: nuevaSuma.ave,
        cantidad: nuevaSuma.cantidad,
        egreso: nuevaSuma.precio ?? 0,
        fecha: nuevaSuma.fecha,
      ));
    }
  }

  void editarSumaYActualizarTotal(SumaC nuevaSuma) {
    // Encontrar la suma original
    var suma = sumas.firstWhereOrNull((suma) => suma.id == nuevaSuma.id);
    if (suma == null) {
      print("Suma no encontrada");
      return;
    }
    // Guardar los valores originales antes de la edición
    String nombreOriginal = suma.nombre;
    Ave aveOriginal = suma.ave;
    double cantidadOriginal = suma.cantidad;
    double? precioOriginal = suma.precio;
    DateTime fechaOriginal = suma.fecha;
    DateTime? fechaTerminoOriginal = suma.fechaTermino;

    // Actualizar la suma con los nuevos valores
    suma.nombre = nuevaSuma.nombre;
    suma.ave = nuevaSuma.ave;
    suma.cantidad = nuevaSuma.cantidad;
    suma.precio = nuevaSuma.precio;
    suma.fecha = nuevaSuma.fecha;
    suma.fechaTermino = nuevaSuma.fechaTermino;

    // Encontrar el total correspondiente
    var sumasNombre =
        sumas.where((s) => (s.nombre == suma.nombre) && (s.ave == suma.ave));
    var total = totales.firstWhereOrNull(
        (total) => total.nombre == nombreOriginal && total.ave == aveOriginal);

    if (total != null) {
      // Ajustar el total
      total.cantidad -= cantidadOriginal;
      total.egreso -= precioOriginal!;

      // Si el nombre o el ave han cambiado, puede que necesites manejar eso
      if (nombreOriginal != suma.nombre || aveOriginal != suma.ave) {
        print('el nombre o el ave han cambiado');
        // Crear un nuevo total para el nuevo nombre/ave si no existe
        var nuevoTotal = totales.firstWhereOrNull(
            (t) => t.nombre == suma.nombre && t.ave == suma.ave);
        if (nuevoTotal == null) {
          totales.add(TotalC(
            nombre: suma.nombre,
            ave: suma.ave,
            cantidad: suma.cantidad,
            egreso: suma.precio!,
            fecha: suma.fecha,
          ));
        } else {
          nuevoTotal.cantidad += suma.cantidad;
          nuevoTotal.egreso += suma.precio ?? 0;
          nuevoTotal.fecha =
              _fechaReciente(sumasNombre.toList(), DateTime(1800, 4, 20));
        }

        // Eliminar el total original si ya no tiene sumas asociadas
        if (!sumas
            .any((s) => s.nombre == nombreOriginal && s.ave == aveOriginal)) {
          totales.remove(total);
        }
      } else {
        print('el nombre o el ave es igual');
        total.cantidad += suma.cantidad;
        total.egreso += suma.precio ?? 0;
        total.fecha =
            _fechaReciente(sumasNombre.toList(), DateTime(1800, 4, 20));
      }
    } else {
      print("Total correspondiente no encontrado");
      // Aquí podrías decidir crear un nuevo total si no existe uno correspondiente
    }

    // Notificar a GetX que los datos han cambiado
    sumas.refresh();
    totales.refresh();
  }

  void eliminarSumaYActualizarTotal(SumaC suma) {
    // Encontrar la suma a eliminar
    var sumaAEliminar = suma;
    if (sumaAEliminar == null) {
      print("Suma no encontrada");
      return;
    }

    // Eliminar la suma
    sumas.remove(sumaAEliminar);

    // Encontrar el total correspondiente
    var totalCorrespondiente = totales.firstWhereOrNull((total) =>
        total.nombre == sumaAEliminar.nombre && total.ave == sumaAEliminar.ave);

    if (totalCorrespondiente != null) {
      // Ajustar el total
      totalCorrespondiente.cantidad -= sumaAEliminar.cantidad;
      totalCorrespondiente.egreso -= (sumaAEliminar.precio ?? 0);

      // Si el total queda en cero, eliminarlo
      if (totalCorrespondiente.cantidad <= 0 &&
          totalCorrespondiente.egreso <= 0) {
        totales.remove(totalCorrespondiente);
      }
    } else {
      print("Total correspondiente no encontrado");
    }

    // Notificar a GetX que los datos han cambiado
    sumas.refresh();
    totales.refresh();
  }

  void calcularTotalC(suma) {
    var totalNombre = totales.firstWhereOrNull(
        (total) => (total.nombre == suma.nombre) && (total.ave == suma.ave));
    var sumasNombre = sumas.where(
        (suma) => (suma.nombre == suma.nombre) && (suma.ave == suma.ave));
    if (totalNombre != null) {
      totalNombre.egreso += suma.precio;
      totalNombre.cantidad += suma.cantidad;
      totalNombre.fecha =
          _fechaReciente(sumasNombre.toList(), DateTime(1800, 4, 20));
      // Procesar ave2
    } else {
      print('totalNombre es null');
      totales.add(TotalC(
        nombre: suma.nombre,
        ave: suma.ave,
        cantidad: suma.cantidad,
        egreso: suma.precio,
        fecha: suma.fecha,
      ));
      ordenarCronologicamente(totales);
      // Manejar el caso cuando no se encuentra ningún elemento
    }
  }

  List<num> calcularTotalC2() {
    double totalCantidad = 0;
    double totalEgresos = 0;

    for (var total in totales) {
      totalCantidad += total.cantidad;
      totalEgresos += total.egreso;
    }

    return [totalCantidad, totalEgresos];
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

class Comida extends StatelessWidget {
  final CardControllerC cardControllerC = Get.find();
  final controlador;
  Comida({super.key, required this.controlador});

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
                    controlador.pageController2.animateToPage(0,
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
                    controlador.pageController2.animateToPage(1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease);
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
    return Expanded(
      child: PageView(
        controller: controlador.pageController2,
        onPageChanged: controlador.onPageChanged,
        children: [
          Stack(alignment: Alignment.center, children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Caja(
                        color1: customColors.card2!,
                        color2: customColors.linea!,
                        txt1: '${cardControllerC.calcularTotalC2()[0]}',
                        txt2: 'Kg'),
                    const Padding(padding: EdgeInsets.only(left: 10.0)),
                    Caja(
                        color1: customColors.card3!,
                        color2: customColors.linea2!,
                        txt1: '${cardControllerC.calcularTotalC2()[1].toStringAsFixed(0)} \$',
                        txt2: 'Egreso',
                        oscuro: true),
                    const Padding(padding: EdgeInsets.only(left: 10.0)),
                    Caja(
                        color1: customColors.card4!,
                        color2: customColors.linea3!,
                        txt1: '----',
                        txt2: '----',
                        oscuro: true),
                  ],
                ),
                const Padding(padding: EdgeInsets.only(top: 10)),
                _MostrarTotales(),
              ],
            )
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
          ])
        ],
      ),
    );
  }
}

void mostrarDialogo(BuildContext context, {SumaC? suma, int? index}) {
  final _formKey = GlobalKey<FormState>();
  final CardControllerC cardControllerC = Get.find();
  final CardController cardController = Get.find();
  TextEditingController idC = TextEditingController();
  TextEditingController nombreC = TextEditingController();
  TextEditingController aveC = TextEditingController();
  //TextEditingController rotosC = TextEditingController(text: '0');
  TextEditingController cantidadC = TextEditingController();
  TextEditingController precioC = TextEditingController();
  TextEditingController precioUnitarioC = TextEditingController();
  TextEditingController fechaC = TextEditingController();
  TextEditingController fechaTerminoC = TextEditingController();

  // Variables observables para el estado de los campos
  RxBool field1Enabled = true.obs;
  RxBool field2Enabled = true.obs;

  // Método para manejar los cambios en el campo 1
  void onField1Changed(String value) {
    if (value.isNotEmpty) {
      precioUnitarioC.clear(); // Limpiar campo 2
      field2Enabled.value = false; // Desactivar campo 2
    } else {
      field2Enabled.value = true; // Activar campo 2
    }
  }

  // Método para manejar los cambios en el campo 2
  void onField2Changed(String value) {
    if (value.isNotEmpty) {
      precioC.clear(); // Limpiar campo 1
      field1Enabled.value = false; // Desactivar campo 1
    } else {
      field1Enabled.value = true; // Activar campo 1
    }
  }

  if (suma != null) {
    idC = TextEditingController(text: suma.id);
    nombreC = TextEditingController(text: suma.nombre);
    aveC = TextEditingController(text: suma.ave.displayName);
    cantidadC = TextEditingController(text: suma.cantidad.toString());
    precioC = TextEditingController(text: suma.precio.toString());
    precioUnitarioC =
        TextEditingController(text: suma.precioUnitario.toString());
    fechaC =
        TextEditingController(text: intl.DateFormat.yMd().format(suma.fecha));
    fechaTerminoC = TextEditingController(
        text: suma.fechaTermino != null
            ? intl.DateFormat.yMd().format(suma.fechaTermino!)
            : '');
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Agregar Alimentos'),
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
                    controller: nombreC,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      suffixIcon: ClearButton(controller: nombreC),
                      labelText: 'Alimento',
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
                          controller: precioC,
                          enabled: field1Enabled.value,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            suffixIcon: ClearButton(controller: precioC),
                            labelText: 'Precio',
                            helperText: '* requerido',
                          ),
                          onChanged: onField1Changed,
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
                          controller: precioUnitarioC,
                          enabled: field1Enabled.value,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            suffixIcon:
                                ClearButton(controller: precioUnitarioC),
                            labelText: 'Precio unitario',
                            helperText: '* requerido',
                          ),
                          onChanged: onField2Changed,
                        ),
                      ),
                    ],
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
                          controller: cantidadC,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              suffixIcon: ClearButton(controller: cantidadC),
                              labelText: 'Cantidad',
                              helperText: '* requerido',
                              suffixText: 'Kg'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Introduzca un número';
                            }
                            final n = double.tryParse(value);
                            if (n == null) {
                              return 'Ingrese un número double';
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
                        child: DropdownMenu<Ave>(
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
                  if (suma != null)
                    DatePicker2(
                        control: fechaTerminoC, texto: 'Fecha de termino'),
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
          Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                child: const Text('Agregar'),
                onPressed: () {
                  if (_formKey.currentState!.validate() && aveC.text.isNotEmpty) {
                    if (suma != null) {
                      cardControllerC.editarSumaC(
                          index!,
                          SumaC(
                            id: idC.text,
                            nombre: nombreC.text,
                            ave: parseEnum(aveC.text, Ave.values),
                            cantidad: double.parse(cantidadC.text),
                            precio: (precioC.text.isEmpty)
                                ? null
                                : double.parse(precioC.text),
                            precioUnitario: (precioUnitarioC.text.isEmpty)
                                ? null
                                : double.parse(precioUnitarioC.text),
                            fecha: intl.DateFormat('M/d/yyyy').parse(fechaC.text),
                            fechaTermino: (fechaTerminoC.text.isEmpty)
                                ? null
                                : intl.DateFormat('M/d/yyyy')
                                    .parse(fechaTerminoC.text),
                          ));
                    } else {
                      cardControllerC.agregarSumaC(
                        SumaC(
                          nombre: nombreC.text,
                          ave: parseEnum(aveC.text, Ave.values),
                          cantidad: double.parse(cantidadC.text),
                          precio: (precioC.text.isEmpty)
                              ? null
                              : double.parse(precioC.text),
                          precioUnitario: (precioUnitarioC.text.isEmpty)
                              ? null
                              : double.parse(precioUnitarioC.text),
                          fecha: intl.DateFormat('M/d/yyyy').parse(fechaC.text),
                          fechaTermino: (fechaTerminoC.text.isEmpty)
                              ? null
                              : intl.DateFormat('M/d/yyyy')
                                  .parse(fechaTerminoC.text),
                        ),
                      );
                    }
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('Hay campos sin completar'),
                        action: SnackBarAction(
                          label: 'Cerrar',
                          onPressed: () {},
                        ),
                      ),
                    );
                  }
                },
              );
            }
          ),
        ],
      );
    },
  );
}

class _MostrarSumas extends StatelessWidget {
  final CardControllerC cardControllerC = Get.find();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(
        () => ListView.builder(
          itemCount: cardControllerC.sumas.length,
          itemBuilder: (context, index) {
            var suma = cardControllerC.sumas[index];
            return InkWell(
              highlightColor:
                            Colors.transparent,
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
                            cardControllerC.eliminarSumaC(index, suma);
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
              child: TarjetaC(
                nombre: suma.nombre,
                ave: suma.ave,
                cantidad: suma.cantidad,
                precio: suma.precio!,
                fecha: formatearFecha(suma.fecha),
                fechaTermino: suma.duracionTotal,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MostrarTotales extends StatelessWidget {
  final CardControllerC cardControllerC = Get.find();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(
        () => ListView.builder(
            itemCount: cardControllerC.totales.length,
            itemBuilder: (context, index) {
              var total = cardControllerC.totales[index];
              return Tarjeta_totalC(
                nombre: total.nombre,
                ave: total.ave,
                cantidad: total.cantidad,
                egreso: total.egreso,
                fecha: formatearFecha(total.fecha),
              );
            }),
      ),
    );
  }
}

class Tarjeta_totalC extends StatelessWidget {
  final String nombre;
  final Ave ave;
  final double cantidad;
  final double egreso;
  final String fecha;

  Tarjeta_totalC({
    required this.nombre,
    required this.ave,
    required this.cantidad,
    required this.egreso,
    required this.fecha,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return Stack(children: [
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
                        Image.asset('assets/outcome.png', color: Colors.red),
                        Text('${egreso.toStringAsFixed(0)} \$',
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 14)),
                        const Text('Egreso',
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
                            image: const AssetImage('assets/kg.png'),
                            color: customColors.iconos),
                        Text('$cantidad Kg',
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 14)),
                        const Text('Cantidad',
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
      /*Positioned(
        top: 0,
        right: 10,
        child: Icon(
          Icons.bookmark,
          size: 40,
          color: customColors.iconos,
        ),
      ),*/
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
    ]);
  }
}

class TarjetaC extends StatelessWidget {
  final String nombre;
  final Ave ave;
  final double cantidad;
  final double precio;
  final String fecha;
  final int fechaTermino;

  TarjetaC({
    required this.nombre,
    required this.ave,
    required this.cantidad,
    required this.precio,
    required this.fecha,
    required this.fechaTermino,
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
                              image: const AssetImage('assets/price.png'),
                              color: customColors.iconos),
                          Text('${precio.toStringAsFixed(0)} \$',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
                          const Text('Precio',
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
                              image: const AssetImage('assets/kg.png'),
                              color: customColors.iconos),
                          Text('$cantidad Kg',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
                          const Text('Cantidad',
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
                  child: Text('$fecha   $fechaTermino dias',
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
