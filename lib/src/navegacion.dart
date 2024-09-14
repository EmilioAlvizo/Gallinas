import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'comida.dart';
import 'fuente.dart';
import 'grafica.dart';
import 'huevos.dart';
import 'gallinas.dart';
import 'invitacion.dart';
import 'opciones.dart';
import 'control.dart';
import 'sqlite.dart';

class BottomNavBar extends StatelessWidget {
  final NavegacionVar navegacionVar = Get.find<NavegacionVar>();
  final FilterController controller = Get.find();
  final InvitationSystem invitationSystem = Get.find();
  final FarmSelectionController farmSelectionController = Get.find();
  //final FilterController controller = Get.put(FilterController());
  void _showFilterOptions(BuildContext context) {
    Scaffold.of(context).openEndDrawer();
  }

  Future<void> _initializeDatabase() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    //final UserSession userSession = Get.find();
    print('_initializeDatabase');
    print(currentUser!.uid);
    try {
      await UserSession.initializeForCurrentUser(currentUser);
      await syncDataFromFirebase(currentUser!.uid);
      //userSession.usuarioSeleccionado.value = currentUser as String?;
      await navegacionVar.inicio(currentUser);
      await farmSelectionController.loadFarms(currentUser);
      print('fin _initializeDatabase');
    } catch (e, stackTrace) {
      print('error en $e');
      print('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _initializeDatabase(),
        builder: (context, snapshot) {
          final UserSession userSession = Get.find();
          userSession.usuarioSeleccionado.value = UserSession.currentUserId;
          //navegacionVar.inicio();
          //farmSelectionController.loadFarms();
          //invitationSystem.checkAndProcessInvitations();
          //invitationSystem.checkAndUpdateInvitation();
          final customColors = Theme.of(context).extension<CustomColors>()!;
          return Obx(() => Scaffold(
                bottomNavigationBar: NavigationBar(
                  //backgroundColor: Colors.white,
                  onDestinationSelected: (index) {
                    navegacionVar.tabIndex.value = index;
                    print(navegacionVar.botonIndex.value);
                    navegacionVar.botonIndex.value = 0;
                    navegacionVar.pageController.jumpToPage(0);
                    navegacionVar.pageController2.jumpToPage(0);
                    navegacionVar.pageController3.jumpToPage(0);
                    navegacionVar.pageController4.jumpToPage(0);
                    print(navegacionVar.botonIndex.value);
                  },
                  selectedIndex: navegacionVar.tabIndex.value,
                  //indicatorColor: Colors.amber,
                  destinations: <Widget>[
                    NavigationDestination(
                      selectedIcon: Image.asset('assets/barn_filled.png',
                          color: customColors.iconos),
                      icon: Image.asset('assets/barn.png',
                          color: customColors.iconos),
                      label: '',
                    ),
                    NavigationDestination(
                      selectedIcon: Image.asset('assets/chicken_filled.png',
                          color: customColors.iconos),
                      icon: Image.asset('assets/chicken.png',
                          color: customColors.iconos),
                      label: '',
                    ),
                    NavigationDestination(
                      selectedIcon: Image.asset('assets/eggs_filled.png',
                          color: customColors.iconos),
                      icon: Image.asset('assets/eggs.png',
                          color: customColors.iconos),
                      label: '',
                    ),
                    NavigationDestination(
                      selectedIcon: Image.asset('assets/grain_filled.png',
                          color: customColors.iconos),
                      icon: Image.asset('assets/grain.png',
                          color: customColors.iconos),
                      label: '',
                    ),
                    NavigationDestination(
                      selectedIcon: Image.asset('assets/chart_filled.png',
                          color: customColors.iconos),
                      icon: Image.asset('assets/chart.png',
                          color: customColors.iconos),
                      label: '',
                    ),
                  ],
                ),
                appBar: AppBar(
                  //leadingWidth: 200.0,
                  toolbarHeight: 80,
                  titleSpacing: 0.0,
                  title: Padding(
                    padding: const EdgeInsets.only(left: 25.0),
                    child: Obx(
                      () => IndexedStack(
                        index: navegacionVar.tabIndex.value,
                        children: const [
                          Text('Granjas!',
                              style: TextStyle(
                                  fontFamily: 'Pangram',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 26)),
                          Text('Aves',
                              style: TextStyle(
                                  fontFamily: 'Pangram',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 26)),
                          Text('Huevos',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 26)),
                          Text('Comida',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 26)),
                          Text('Graficas',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 26)),
                        ],
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    Builder(builder: (context) {
                      return Obx(() {
                        if (navegacionVar.tabIndex.value == 4) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 25.0),
                            child: Container(
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: customColors.opcion),
                              child: IconButton(
                                  icon: const Icon(Icons
                                      .calendar_today), //Icon(Icons.bookmark_sharp),
                                  tooltip: 'Filtro',
                                  onPressed: () => _showFilterOptions(context)),
                            ),
                          );
                        } else {
                          return SizedBox
                              .shrink(); // Retorna un widget vacío si la condición no se cumple
                        }
                      });
                    }),
                    Padding(
                      padding: const EdgeInsets.only(right: 25.0),
                      child: Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: customColors.opcion),
                        child: IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          tooltip: 'Opciones',
                          onPressed: () async {
                            //print(controlformulario.text);
                            //Get.to(OptionsPage());
                            //Get.to(() => OptionsPage());
                            switch (navegacionVar.tabIndex.value) {
                              case 0:
                                //Get.to(() => OptionsPage1());
                                showOptionsSheet(context);
                                break;
                              case 1:
                                showOptionsSheet(context);
                                break;
                              case 2:
                                showOptionsSheet(context);
                                break;
                              case 3:
                                showOptionsSheet(context);
                                break;
                              case 4:
                                showOptionsSheet(context);
                                break;
                              default:
                                Text('no alcanza');
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                body: Obx(
                  () => IndexedStack(
                    index: navegacionVar.tabIndex.value,
                    children: [
                      FarmSelectionScreen(controlador: navegacionVar),
                      Gallinas(controlador: navegacionVar),
                      Huevos(controlador: navegacionVar),
                      Comida(controlador: navegacionVar),
                      Grafica(controlador: navegacionVar),
                      /*ElevatedButton(
                    onPressed: () {
                      final CardController cardController = Get.find();
                      print(cardController.restas);
                      navegacionVar.cargarDatos();
                      //Get.to(() => BottomNavBar());
                    },
                    child: const Text('print'),
                  ), //ProductoListScreen(),*/
                    ],
                  ),
                ),
                endDrawer: Drawer(
                  child: ListView(
                    children: DateFilter.options.entries.map((entry) {
                      return Obx(() {
                        return RadioListTile<DateFilterOption>(
                          title: Text(entry.key),
                          value: entry.value,
                          groupValue: controller.selectedFilter.value,
                          onChanged: (DateFilterOption? newValue) async {
                            if (newValue == DateFilterOption.customRange) {
                              DateTimeRange? picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                controller.customRange.value = picked;
                              }
                            }
                            controller.selectedFilter.value = newValue;
                            controller.filterTotales();
                            //print('filterTotales ${controller.filterTotales()}');
                            Navigator.of(context).pop(); // Close the drawer
                          },
                        );
                      });
                    }).toList(),
                  ),
                ),
              ));
        });
  }
}
