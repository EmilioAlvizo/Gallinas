import 'package:flutter/material.dart';

import 'gallinas.dart';

class Colores {
  static const Color card = Color(0xFFF4F5F0);

  static const Color gris1 = Color(0xFFF4F5F0);
  static const Color gris2 = Color(0xFF828282);
  static const Color gris3 = Color(0xFFD9D9D9);
  static const Color grisf = Color(0xffECEEE6);

  static const Color verde1 = Color(0xff1B9C73);
  static const Color azul1 = Color(0xff4595AC);
  static const Color rojo1 = Color(0xffCA7C74);
  static const Color naranja1 = Color(0xffE59A54);

  static const Color verde2 = Color(0xff72C0A5);
  static const Color azul2 = Color(0xffBAE0E5);
  static const Color rojo2 = Color(0xffF0D2CA);
  static const Color naranja2 = Color(0xffF0CB94);

  static const Color verde = Color(0xff34a853);
  static const Color rojo = Color(0xffea4335);
  static const Color naranja  = Color(0xfffbbc05);
  static const Color azul  = Color(0xff4285f4);
  static const Color turquesa = Color(0xff00bfa5);
  static const Color rosa  = Color(0xffe2957d);

}


class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    fontFamily: 'Pangram',
  ).copyWith(extensions: <ThemeExtension<CustomColors>>[CustomColors.light]);

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: 'Pangram',
  ).copyWith(extensions: <ThemeExtension<CustomColors>>[CustomColors.dark]);
}

class CustomColors extends ThemeExtension<CustomColors> {
  final Color? card;
  final Color? cardbottom;
  final Color? iconos;
  final Color? boton;
  final Color? boton2;
  final Color? texto1;
  final Color? opcion;
  final Color? card2;
  final Color? card3;
  final Color? card4;
  final Color? linea;
  final Color? linea2;
  final Color? linea3;
  final Color? texto2;
  final Color? texto3;
  final Color? texto4;
  final Color? verde;
  final Color? rojo;
  final Color? naranja;
  final Color? azul;
  final Color? turquesa;
  final Color? rosa;
  final Color? verde2;
  final Color? rojo2;
  final Color? naranja2;
  final Color? azul2;
  final Color? turquesa2;
  final Color? rosa2;

  const CustomColors({
    this.card,
    this.cardbottom,
    this.iconos,
    this.boton,
    this.boton2,
    this.texto1,
    this.opcion,
    this.card2,
    this.card3,
    this.card4,
    this.linea,
    this.linea2,
    this.linea3,
    this.texto2,
    this.texto3,
    this.texto4,
    this.verde,
    this.rojo,
    this.naranja,
    this.azul,
    this.turquesa,
    this.rosa,
    this.verde2,
    this.rojo2,
    this.naranja2,
    this.azul2,
    this.turquesa2,
    this.rosa2,
  });

  @override
  ThemeExtension<CustomColors> copyWith({
    Color? card, 
    Color? cardbottom,
    Color? iconos,
    Color? boton,
    Color? boton2,
    Color? texto1,
    Color? opcion,
    Color? card2,
    Color? card3,
    Color? card4,
    Color? linea,
    Color? linea2,
    Color? linea3,
    Color? texto2,
    Color? texto3,
    Color? texto4,
    Color? verde,
    Color? rojo,
    Color? naranja,
    Color? azul,
    Color? turquesa,
    Color? rosa,
    Color? verde2,
    Color? rojo2,
    Color? naranja2,
    Color? azul2,
    Color? turquesa2,
    Color? rosa2,
    }) {

    return CustomColors(
      card: card ?? this.card,
      cardbottom: cardbottom ?? this.cardbottom,
      iconos: iconos ?? this.iconos,
      boton: boton ?? this.boton,
      boton2: boton2 ?? this.boton2,
      texto1: texto1 ?? this.texto1,
      opcion: opcion ?? this.opcion,
      card2: card2 ?? this.card2,
      card3: card3 ?? this.card3,
      card4: card4 ?? this.card4,
      linea: linea ?? this.linea,
      linea2: linea2 ?? this.linea2,
      linea3: linea3 ?? this.linea3,
      texto2: texto2 ?? this.texto2,
      texto3: texto3 ?? this.texto3,
      texto4: texto4 ?? this.texto4,
      verde: verde ?? this.verde,
      rojo: rojo ?? this.rojo,
      naranja: naranja ?? this.naranja,
      azul: azul ?? this.azul,
      turquesa: turquesa ?? this.turquesa,
      rosa: rosa ?? this.rosa,
      verde2: verde2 ?? this.verde2,
      rojo2: rojo2 ?? this.rojo2,
      naranja2: naranja2 ?? this.naranja2,
      azul2: azul2 ?? this.azul2,
      turquesa2: turquesa2 ?? this.turquesa2,
      rosa2: rosa2 ?? this.rosa2,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      card: Color.lerp(card, other.card, t),
      cardbottom: Color.lerp(cardbottom, other.cardbottom, t),
      iconos: Color.lerp(iconos, other.iconos, t),
      boton: Color.lerp(boton, other.boton, t),
      boton2: Color.lerp(boton2, other.boton2, t),
      texto1: Color.lerp(texto1, other.texto1, t),
      opcion: Color.lerp(opcion, other.opcion, t),
      card2: Color.lerp(card2, other.card2, t),
      card3: Color.lerp(card3, other.card3, t),
      card4: Color.lerp(card4, other.card4, t),
      linea: Color.lerp(linea, other.linea, t),
      linea2: Color.lerp(linea2, other.linea2, t),
      linea3: Color.lerp(linea3, other.linea3, t),
      texto2: Color.lerp(texto2, other.texto2, t),
      texto3: Color.lerp(texto3, other.texto3, t),
      texto4: Color.lerp(texto4, other.texto4, t),
      verde: Color.lerp(verde, other.verde, t),
      rojo: Color.lerp(rojo, other.rojo, t),
      naranja: Color.lerp(naranja, other.naranja, t),
      azul: Color.lerp(azul, other.azul, t),
      turquesa: Color.lerp(turquesa, other.turquesa, t),
      rosa: Color.lerp(rosa, other.rosa, t),
      verde2: Color.lerp(verde2, other.verde2, t),
      rojo2: Color.lerp(rojo2, other.rojo2, t),
      naranja2: Color.lerp(naranja2, other.naranja2, t),
      azul2: Color.lerp(azul2, other.azul2, t),
      turquesa2: Color.lerp(turquesa2, other.turquesa2, t),
      rosa2: Color.lerp(rosa2, other.rosa2, t),
    );
  }

  static const light = CustomColors(
    card: Colores.gris1,
    cardbottom: Colores.gris3,
    iconos: Colors.black,
    boton: Color(0xffECEEE6),
    boton2: Color(0xFFECEEE6),
    texto1: Color.fromARGB(255, 255, 255, 255),
    opcion: Color(0xFFF4F5F0),
    card2: Color(0xff1C9D74),
    card3: Color(0xffDFECEE),
    card4: Color(0xffEFE0DC),
    linea: Color(0xff72C0A5),
    linea2: Color.fromRGBO(68, 148, 172, 0.5),
    linea3: Color.fromRGBO(202, 124, 116, 0.5),
    texto2: Color(0xff333333),
    texto3: Colores.gris2,
    texto4: Colors.black,
    verde: Color(0xff81C784),
    rojo: Color(0xffE57373),
    naranja: Color(0xffFFB74D),
    azul: Color(0xff64B5F6),
    turquesa: Color(0xff4DB6AC),
    rosa: Color(0xffF06292),
    verde2: Color(0xff0A6E2B),
    rojo2: Color(0xff8B1E1E),
    naranja2: Color(0xffA36700),
    azul2: Color(0xff1B3A73),
    turquesa2: Color(0xff00695C),
    rosa2: Color(0xff8B4A4A),
  );

  static const dark = CustomColors(
    card: Color(0xFF2a2c26),
    cardbottom: Color(0xFF8c918b),
    iconos: Color(0xFFe4e2df),
    boton: Color(0xFF2a2c26),
    boton2: Color(0xFF353730),
    texto1: Colors.black,
    opcion: Color(0xFF2a2c26),
    card2: Color(0xff1C9D74),
    card3: Color(0xff2B2F2F),
    card4: Color(0xff3F332E),
    linea: Color(0xff1A8A67),
    linea2: Color(0xff394242),
    linea3: Color(0xff5A413C),
    texto2: Colors.white,
    texto3: Colors.white,
    texto4: Colors.white,
    verde: Color(0xff0A6E2B),
    rojo: Color(0xff8B1E1E),
    naranja: Color(0xffA36700),
    azul: Color(0xff1B3A73),
    turquesa: Color(0xff00695C),
    rosa: Color(0xff8B4A4A),
    verde2: Color(0xff81C784),
    rojo2: Color(0xffE57373),
    naranja2: Color(0xffFFB74D),
    azul2: Color(0xff64B5F6),
    turquesa2: Color(0xff4DB6AC),
    rosa2: Color(0xffF06292),
  );
}

Color getColorForAve(Ave ave, customColors) {
  switch (ave) {
    case Ave.Gallina:
      return customColors.azul;
    case Ave.PavoReal:
      return customColors.verde;
    default:
      return Colors.grey; // Color por defecto
  }
}