import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'control.dart';
import 'fuente.dart';
import 'gallinas.dart';
import 'huevos.dart';
import 'opciones.dart';
import 'texto.dart';


class Grafica extends StatelessWidget {
  final CardControllerH cardControllerH = Get.find();
  final AveControl aveControl = Get.find();
  final CalculoController calculoController = Get.put(CalculoController());
  final controlador;

  Grafica({super.key, required this.controlador});

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25),
      child: Container(
        child: Column(
          children: [
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
                            style: TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                    )),
              ],
            ),
            /*Tarjeta_grafica(
              contol: filterController,
            ),
            const Padding(padding: EdgeInsets.only(top: 10)),
            CustomTable2(
              contol: cardControllerH,
              navegacionVar: controlador,
            ),
            const Padding(padding: EdgeInsets.only(top: 10)),*/
            Expanded(
              child: Obx(() {
                var datosEconomicos = calculoController.datosEconomicos;

                return ListView.builder(
                  itemCount: datosEconomicos.length,
                  itemBuilder: (context, index) {
                    var fechaInicio =
                        datosEconomicos[index]['fechaInicio'] as DateTime;
                    var fechaFin =
                        datosEconomicos[index]['fechaFin'] as DateTime;
                    var costoTotal = datosEconomicos[index]['costoTotal'];
                    var consumoTotal = datosEconomicos[index]['consumoTotal'];
                    var costoPromedioPorKg =
                        datosEconomicos[index]['costoPromedioPorKg'];
                    var promedioGallinas =
                        datosEconomicos[index]['promedioPonderadoGallinas'];
                    var consumodiario = datosEconomicos[index]['consumodiario'];
                    var consumodiarioporgallina =
                        datosEconomicos[index]['consumodiarioporgallina'];
                    var huevos = datosEconomicos[index]['huevos'];
                    var puntoequilibrio =
                        datosEconomicos[index]['puntoequilibrio'];

                    return Tarjeta_grafica2(
                      puntoequilibrio: puntoequilibrio,
                      costoTotal: costoTotal,
                      consumoTotal: consumoTotal,
                      promedioGallinas: promedioGallinas,
                      consumodiarioporgallina: consumodiarioporgallina,
                      huevos: huevos,
                      inicio: fechaInicio,
                      fin: fechaFin,
                    );

                    /*Card(
                      child: ListTile(
                        title: Text(
                            'fechaInicio: ${fechaInicio.toLocal()} - fechaFin: ${fechaFin.toLocal()}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Costo Total de Alimentos: \$${costoTotal.toStringAsFixed(2)}'),
                            Text(
                                'Consumo Total de Alimentos: ${consumoTotal.toStringAsFixed(2)} kg'),
                            Text(
                                'Promedio Ponderado de Gallinas: ${promedioGallinas.toStringAsFixed(2)}'),
                            Text(
                                'consumodiarioporgallina: ${consumodiarioporgallina.toStringAsFixed(2)} kg/(dia * gallina)'),
                            Text('huevos: ${huevos}'),
                            Text(
                                'puntoequilibrio: ${puntoequilibrio.toStringAsFixed(2)} \$/\u{1F95A}'),
                          ],
                        ),
                      ),
                    );*/
                  },
                );
              }),
            ),
            /*Expanded(
                child: CustomTable3(
              contol: filterController,
              navegacionVar: controlador,
            )),*/
          ],
        ),
      ),
    );
  }
}

class Tarjeta_grafica2 extends StatelessWidget {
  final double puntoequilibrio;
  final double costoTotal;
  final double consumoTotal;
  final double promedioGallinas;
  final double consumodiarioporgallina;
  final int huevos;
  final DateTime inicio;
  final DateTime fin;

  Tarjeta_grafica2({
    required this.puntoequilibrio,
    required this.costoTotal,
    required this.consumoTotal,
    required this.promedioGallinas,
    required this.consumodiarioporgallina,
    required this.huevos,
    required this.inicio,
    required this.fin,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return Card(
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
                  top: 20.0, left: 25, right: 25, bottom: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Column(
                      children: [
                        /*Image(
                              image: const AssetImage('assets/goal.png'),
                              color: customColors.iconos),*/
                        Text('${puntoequilibrio.toStringAsFixed(2)} \$/huevo',
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 16)),
                        const Text('Punto de equilibrio',
                            style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 15,
                                color: Colores.gris2)),
                      ],
                    ),
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
                          Text('$consumoTotal Kg',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
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
                              image: const AssetImage('assets/acquisition.png'),
                              color: customColors.iconos),*/
                          Text('${costoTotal.toStringAsFixed(0)} \$',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
                          const Text('Costo',
                              style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                  color: Colores.gris2)),
                        ],
                      ),
                      /*Column(
                        children: [
                          /*Image(
                              image: const AssetImage('assets/acquisition.png'),
                              color: customColors.iconos),*/
                          Text('${(consumoTotal / huevos).toStringAsFixed(2)} Kg/huevo',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
                          const Text('Conversion',
                              style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                  color: Colores.gris2)),
                        ],
                      ),*/
                      Column(
                        children: [
                          Text(
                              '${consumodiarioporgallina.toStringAsFixed(2)} kg/(dia*ave)',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
                          const Text('Consumo',
                              style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                  color: Colores.gris2))
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
                          /*Image(
                              image: const AssetImage('assets/acquisition.png'),
                              color: customColors.iconos),*/
                          Text('${promedioGallinas.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
                          const Text('Aves',
                              style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                  color: Colores.gris2)),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                              '${((huevos / promedioGallinas) / fin.difference(inicio).inDays).toStringAsFixed(2)} huevo/(dia*ave)',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
                          const Text('Huevos',
                              style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                  color: Colores.gris2))
                        ],
                      ),
                      /*Image(
                          image: const AssetImage('assets/skull.png'),
                          color: customColors.iconos),*/
                      Column(
                        children: [
                          Text('$huevos',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
                          const Text('Huevos',
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
              child: Text(
                  '${formatearFecha(inicio)} - ${formatearFecha(fin)} ${fin.difference(inicio).inDays}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14)),
            )
          ],
        ),
      ),
    );
  }
}

class Tarjeta_grafica extends StatelessWidget {
  var contol;
  Tarjeta_grafica({required this.contol});
  /*final String nombre;
  final int avesVivas;
  final Proposito proposito;
  final double balance;
  final String fecha;
  final int avesMuertas;

  Tarjeta_grafica(
      {required this.nombre,
      required this.avesVivas,
      required this.proposito,
      this.balance = 0.0,
      required this.fecha,
      required this.avesMuertas});*/

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return Card(
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
                  top: 20.0, left: 25, right: 25, bottom: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Huevos',
                            style: const TextStyle(
                                fontWeight: FontWeight.w400, fontSize: 20)),
                        TextButton(
                          onPressed: () {
                            // Respond to button press
                          },
                          style: TextButton.styleFrom(
                            backgroundColor:
                                customColors.boton2, // Cambia el color de fondo
                            foregroundColor: const Color.fromARGB(255, 7, 2,
                                2), // Cambia el color del texto e icono
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  15.0), // Define la redondez del borde
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("TEXT BUTTON"),
                              SizedBox(
                                  width:
                                      8.0), // Espacio entre el texto y el icono
                              Icon(Icons.calendar_month_rounded, size: 18),
                            ],
                          ),
                        )
                      ]),
                  const Padding(padding: EdgeInsets.only(top: 10.0)),
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: customColors.verde,
                              image: DecorationImage(
                                  image:
                                      const AssetImage('assets/topographi.png'),
                                  colorFilter: ColorFilter.mode(
                                      customColors.verde2!.withOpacity(0.5),
                                      BlendMode.srcIn),
                                  fit: BoxFit.none,
                                  alignment:
                                      Alignment.center)), // Bordes redondeados
                          child: Column(
                            children: [
                              Text('${contol.huevosTotales}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              const Text('Totales',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 13,
                                  )),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                              color: customColors
                                  .rojo, // Cambia el color de fondo aquí
                              borderRadius: BorderRadius.circular(10.0),
                              image: DecorationImage(
                                  image:
                                      const AssetImage('assets/topographi.png'),
                                  colorFilter: ColorFilter.mode(
                                      customColors.rojo2!.withOpacity(0.5),
                                      BlendMode.srcIn),
                                  fit: BoxFit.none,
                                  alignment: Alignment.center)),
                          child: Column(
                            children: [
                              Text('${contol.huevosConsumo}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              const Text('Consumo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 13,
                                  )),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                              color: customColors
                                  .naranja, // Cambia el color de fondo aquí
                              borderRadius: BorderRadius.circular(10.0),
                              image: DecorationImage(
                                  image:
                                      const AssetImage('assets/topographi.png'),
                                  colorFilter: ColorFilter.mode(
                                      customColors.naranja2!.withOpacity(0.5),
                                      BlendMode.srcIn),
                                  fit: BoxFit.none,
                                  alignment: Alignment.center)),
                          child: Column(
                            children: [
                              Text('${contol.huevosVendidos}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              const Text('Ventas',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 13)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const Padding(padding: EdgeInsets.only(top: 10.0)),
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                              color: customColors
                                  .azul, // Cambia el color de fondo aquí
                              borderRadius: BorderRadius.circular(10.0),
                              image: DecorationImage(
                                  image:
                                      const AssetImage('assets/topographi.png'),
                                  colorFilter: ColorFilter.mode(
                                      customColors.azul2!.withOpacity(0.5),
                                      BlendMode.srcIn),
                                  fit: BoxFit.none,
                                  alignment: Alignment.center)),
                          child: Column(
                            children: [
                              Text('${contol.huevosRoto}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              const Text('Rotos',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                              color: customColors
                                  .turquesa, // Cambia el color de fondo aquí
                              borderRadius: BorderRadius.circular(10.0),
                              image: DecorationImage(
                                  image:
                                      const AssetImage('assets/topographi.png'),
                                  colorFilter: ColorFilter.mode(
                                      customColors.turquesa2!.withOpacity(0.5),
                                      BlendMode.srcIn),
                                  fit: BoxFit.none,
                                  alignment: Alignment.center)),
                          child: Column(
                            children: [
                              Text('${contol.huevosOtros}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              const Text('Otros',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                              color: customColors
                                  .rosa, // Cambia el color de fondo aquí
                              borderRadius: BorderRadius.circular(10.0),
                              image: DecorationImage(
                                  image:
                                      const AssetImage('assets/topographi.png'),
                                  colorFilter: ColorFilter.mode(
                                      customColors.rosa2!.withOpacity(0.5),
                                      BlendMode.srcIn),
                                  fit: BoxFit.none,
                                  alignment: Alignment.center)),
                          child: Column(
                            children: [
                              Text('${contol.balance} \$',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              const Text('Ingreso',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 13)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
