import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:side_sheet/side_sheet.dart';

import 'cerrar.dart';
import 'comida.dart';
import 'control.dart';
import 'gallinas.dart';
import 'huevos.dart';

enum DateFilterOption {
  last7Days,
  last3Months,
  last12Months,
  currentYear,
  previousYear,
  last3Years,
  allTime,
  customRange,
  currentMonth,
  previousMonth,
}

class DateFilter {
  static Map<String, DateFilterOption> options = {
    'Últimos 7 días': DateFilterOption.last7Days,
    'Mes actual': DateFilterOption.currentMonth,
    'Mes previo': DateFilterOption.previousMonth,
    'Últimos 3 meses': DateFilterOption.last3Months,
    'Últimos 12 meses': DateFilterOption.last12Months,
    'Año actual': DateFilterOption.currentYear,
    'Año previo': DateFilterOption.previousYear,
    'Últimos 3 años': DateFilterOption.last3Years,
    'Todo el tiempo': DateFilterOption.allTime,
    'Rango personalizado': DateFilterOption.customRange,
  };

  static DateTimeRange getDateRange(DateFilterOption option,
      {DateTimeRange? customRange}) {
    final now = DateTime.now();
    switch (option) {
      case DateFilterOption.last7Days:
        return DateTimeRange(
          start: now.subtract(Duration(days: 7)),
          end: now,
        );
      case DateFilterOption.currentMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
      case DateFilterOption.previousMonth:
        final firstDayPreviousMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayPreviousMonth = DateTime(now.year, now.month, 0);
        return DateTimeRange(
          start: firstDayPreviousMonth,
          end: lastDayPreviousMonth,
        );
      case DateFilterOption.last3Months:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 3, now.day),
          end: now,
        );
      case DateFilterOption.last12Months:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 12, now.day),
          end: now,
        );
      case DateFilterOption.currentYear:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year + 1, 1, 0),
        );
      case DateFilterOption.previousYear:
        return DateTimeRange(
          start: DateTime(now.year - 1, 1, 1),
          end: DateTime(now.year, 1, 0),
        );
      case DateFilterOption.last3Years:
        return DateTimeRange(
          start: DateTime(now.year - 3, now.month, now.day),
          end: now,
        );
      case DateFilterOption.allTime:
        return DateTimeRange(
          start: DateTime(1900, 1, 1),
          end: now,
        );
      case DateFilterOption.customRange:
        if (customRange != null) {
          return customRange;
        }
        return DateTimeRange(start: now, end: now);
      default:
        return DateTimeRange(start: now, end: now);
    }
  }
}

class AveControl extends GetxController {
  var selectedAveFilter = 'Todas'.obs;
}

class ThemeController extends GetxController {
  var isDarkMode = false.obs;

  inicio(context) {
    isDarkMode.value =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }
}

class FilterController extends GetxController {
  Rx<DateFilterOption?> selectedFilter = Rx<DateFilterOption?>(null);
  Rx<DateTimeRange?> customRange = Rx<DateTimeRange?>(null);
  RxBool isExpanded = false.obs;
  List<SumaH> filteredSumas = <SumaH>[];
  List<RestaH> filteredRestas = <RestaH>[];
  final CardControllerH cardControllerH = Get.find();

  RxInt huevosTotales = 0.obs;
  RxInt huevosConsumo = 0.obs;
  RxInt huevosVendidos = 0.obs;
  RxInt huevosRoto = 0.obs;
  RxInt huevosOtros = 0.obs;
  RxDouble balance = 0.0.obs;

  agregar_TotalH(sumas, restas) {
    huevosTotales.value =
        sumas.map((suma) => suma.buenos + suma.rotos).fold(0, (a, b) => a + b);
    huevosRoto.value = restas
            .where((resta) => resta.razon == Razon_reduccionH.Roto)
            .map((resta) => resta.huevosMenos)
            .fold(0, (a, b) => a + b) +
        sumas.map((suma) => suma.rotos).fold(0, (a, b) => a + b);
    huevosVendidos.value = restas
        .where((resta) => resta.razon == Razon_reduccionH.Venta)
        .map((resta) => resta.huevosMenos)
        .fold(0, (a, b) => a + b);
    huevosOtros.value = restas
        .where((resta) => resta.razon == Razon_reduccionH.Otro)
        .map((resta) => resta.huevosMenos)
        .fold(0, (a, b) => a + b);
    huevosConsumo.value = huevosTotales.value -
        huevosVendidos.value -
        huevosOtros.value -
        huevosRoto.value;
    balance.value =
        restas.map((resta) => resta.ingreso).fold(0.0, (a, b) => a + b);
  }

  var ascendingOrder = true.obs;
  var sortedColumn = ''.obs;

  void sortBy(String field) {
    filteredSumas.sort((a, b) {
      switch (field) {
        case 'nombre':
          sortedColumn.value = field;
          final comparison = a.nombre.compareTo(b.nombre);
          return ascendingOrder.value ? comparison : -comparison;
        case 'buenos':
          sortedColumn.value = field;
          final comparison = a.buenos.compareTo(b.buenos);
          return ascendingOrder.value ? comparison : -comparison;
        case 'rotos':
          sortedColumn.value = field;
          final comparison = a.rotos.compareTo(b.rotos);
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

  @override
  void onInit() {
    super.onInit();
    //filteredSumas.addAll(totales);
  }

  void filterTotales() {
    if (selectedFilter.value != null) {
      DateTimeRange dateRange;
      if (selectedFilter.value == DateFilterOption.customRange &&
          customRange.value != null) {
        dateRange = customRange.value!;
      } else {
        dateRange = DateFilter.getDateRange(selectedFilter.value!);
        print(selectedFilter.value!);
      }
      filteredSumas = cardControllerH.sumas.where((total) {
        return total.fecha.isAfter(dateRange.start) &&
            total.fecha.isBefore(dateRange.end);
      }).toList();
      filteredRestas = cardControllerH.restas.where((total) {
        return total.fecha.isAfter(dateRange.start) &&
            total.fecha.isBefore(dateRange.end);
      }).toList();
      print('filteredSumas.value ${filteredSumas}');
      print('filteredRestas.value ${filteredRestas}');
      agregar_TotalH(filteredSumas, filteredRestas);
    }
  }
}

class OptionsPage1 extends StatelessWidget {
  final NavegacionVar navegacionVar = Get.find();
  final CardController cardController = Get.find();
  final CardControllerH cardControllerH = Get.find();
  final CardControllerC cardControllerC = Get.find();
  final ThemeController themeController = Get.find();

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    themeController.inicio(context);
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(),
            SizedBox(height: 20),
            // Información del usuario
            if (user != null) ...[
              CircleAvatar(
                backgroundImage:
                    user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null ? Icon(Icons.person) : null,
                radius: 40,
              ),
              SizedBox(height: 10),
              Text(
                user.displayName ?? 'Usuario',
              ),
              Text(
                user.email ?? '',
              ),
              SizedBox(height: 20),
            ],
            // Cambio de tema
            ListTile(
              leading: Obx(() => Icon(
                    themeController.isDarkMode.value
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  )),
              title: Text('Cambiar tema'),
              onTap: () => themeController.toggleTheme(),
            ),
            // Botón de sincronización
            /*ListTile(
              leading: Icon(Icons.sync),
              title: Text('Sincronizar datos'),
              onTap: () {
                print('cardController.sumas 1 ${cardController.sumas}');
                Map<String, RxList<dynamic>> dataMap =
                    navegacionVar.getDataMap();
                navegacionVar.loadFromFirebase(cardController.sumas, 'sumas');
                navegacionVar.loadFromFirebase(cardController.restas, 'restas');
                navegacionVar.loadFromFirebase(cardControllerH.sumas, 'sumasH');
                navegacionVar.loadFromFirebase(
                    cardControllerH.restas, 'restasH');
                navegacionVar.loadFromFirebase(cardControllerC.sumas, 'sumasC');
                print('cardController.sumas fin ${cardController.sumas}');
              },
            ),*/
            Spacer(),
            // Botón de cerrar sesión
            /*ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).popUntil((route) => route.isFirst);
                // Aquí puedes navegar a la pantalla de inicio de sesión si es necesario
              },
              child: Text('Cerrar sesión'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),*/
            CerrarSesionBoton()
          ],
        ),
      ),
    );
  }
}

void showOptionsSheet(BuildContext context) {
  SideSheet.right(
    context: context,
    width: MediaQuery.of(context).size.width * 0.8,
    body: OptionsPage1(),
  );
}

class OptionsPage3 extends StatelessWidget {
  final NavegacionVar navegacionVar = Get.find();
  final CardController cardController = Get.find();
  final CardControllerH cardControllerH = Get.find();
  final CardControllerC cardControllerC = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opciones'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seleccionar datos a mostrar:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Mostrar Nombre'),
              trailing: Obx(() => Switch(
                    value: navegacionVar.showNombre.value,
                    onChanged: (value) {
                      navegacionVar.showNombre.value = value;
                    },
                  )),
            ),
            ListTile(
              title: const Text('Mostrar Consumo'),
              trailing: Obx(() => Switch(
                    value: navegacionVar.showConsumo.value,
                    onChanged: (value) {
                      navegacionVar.showConsumo.value = value;
                    },
                  )),
            ),
            ListTile(
              title: const Text('Mostrar Ventas'),
              trailing: Obx(() => Switch(
                    value: navegacionVar.showVentas.value,
                    onChanged: (value) {
                      navegacionVar.showVentas.value = value;
                    },
                  )),
            ),
            ListTile(
              title: const Text('Mostrar Rotos'),
              trailing: Obx(() => Switch(
                    value: navegacionVar.showRotos.value,
                    onChanged: (value) {
                      navegacionVar.showRotos.value = value;
                    },
                  )),
            ),
            ListTile(
              title: const Text('Mostrar Otros'),
              trailing: Obx(() => Switch(
                    value: navegacionVar.showOtros.value,
                    onChanged: (value) {
                      navegacionVar.showOtros.value = value;
                    },
                  )),
            ),
            ListTile(
              title: const Text('Mostrar Ingreso'),
              trailing: Obx(() => Switch(
                    value: navegacionVar.showIngreso.value,
                    onChanged: (value) {
                      navegacionVar.showIngreso.value = value;
                    },
                  )),
            ),
            ListTile(
              title: const Text('Mostrar Totales'),
              trailing: Obx(() => Switch(
                    value: navegacionVar.showTotales.value,
                    onChanged: (value) {
                      navegacionVar.showTotales.value = value;
                    },
                  )),
            ),
            const SizedBox(height: 20),
            /*ElevatedButton(
              onPressed: () async {
                navegacionVar.syncWithFirebase(cardController.sumas, 'sumas');
                navegacionVar.syncWithFirebase(cardController.restas, 'restas');
                navegacionVar.syncWithFirebase(cardControllerH.sumas, 'sumasH');
                navegacionVar.syncWithFirebase(
                    cardControllerH.restas, 'restasH');
                navegacionVar.syncWithFirebase(cardControllerC.sumas, 'sumasC');
              },
              child: const Text('SUBIR'),
            ),*/
            /*ElevatedButton(
              onPressed: () {
                print('cardController.sumas 1 ${cardController.sumas}');
                navegacionVar.loadFromFirebase(cardController.sumas, 'sumas');
                navegacionVar.loadFromFirebase(cardController.restas, 'restas');
                navegacionVar.loadFromFirebase(cardControllerH.sumas, 'sumasH');
                navegacionVar.loadFromFirebase(
                    cardControllerH.restas, 'restasH');
                navegacionVar.loadFromFirebase(cardControllerC.sumas, 'sumasC');
                /*cardController.restas.forEach(
                    (resta) => cardController.calcularTotal(resta.nombre));
                cardController.sumas.forEach(
                    (suma) => cardController.calcularTotal(suma.nombre));
                cardControllerH.restas.forEach(
                    (resta) => cardControllerH.calcularTotalH(resta.nombre));
                cardControllerH.sumas.forEach(
                    (suma) => cardControllerH.calcularTotalH(suma.nombre));
                cardControllerC.sumas.forEach(
                    (suma) => cardControllerC.calcularTotalC(suma.nombre));*/
                print('cardController.sumas fin ${cardController.sumas}');
                //navegacionVar.guardarDatos();
              },
              child: const Icon(Icons.sync),
            ),*/
            /*ElevatedButton(
              onPressed: () {
                Get.back();
                //Get.to(() => BottomNavBar());
              },
              child: const Text('Volver'),
            ),*/
          ],
        ),
      ),
    );
  }
}

class OptionsPage4 extends StatelessWidget {
  final NavegacionVar navegacionVar = Get.find();
  final CardController cardController = Get.find();
  final CardControllerH cardControllerH = Get.find();
  final CardControllerC cardControllerC = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opciones'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /*ElevatedButton(
              onPressed: () {
                print('cardController.sumas 1 ${cardController.sumas}');
                navegacionVar.loadFromFirebase(cardController.sumas, 'sumas');
                navegacionVar.loadFromFirebase(cardController.restas, 'restas');
                navegacionVar.loadFromFirebase(cardControllerH.sumas, 'sumasH');
                navegacionVar.loadFromFirebase(
                    cardControllerH.restas, 'restasH');
                navegacionVar.loadFromFirebase(cardControllerC.sumas, 'sumasC');
              },
              child: const Icon(Icons.sync),
            ),*/
          ],
        ),
      ),
    );
  }
}
