import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:ui' as ui;
import 'dart:ui';

class OutlinedText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color textColor;
  final Color outlineColor;
  final double outlineWidth;
  final FontWeight fontWeight;

  const OutlinedText({
    Key? key,
    required this.text,
    this.fontSize = 24,
    this.textColor = Colors.white,
    this.outlineColor = Colors.black,
    this.outlineWidth = 2,
    this.fontWeight = FontWeight.bold,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // Outline
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = outlineWidth
              ..color = outlineColor,
          ),
        ),
        // Inner text
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class GlassmorphicText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color textColor;
  final double blurIntensity;
  final double opacity;

  const GlassmorphicText({
    Key? key,
    required this.text,
    this.fontSize = 24,
    this.textColor = Colors.white,
    this.blurIntensity = 1,
    this.opacity = 0.2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blurred background
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurIntensity, sigmaY: blurIntensity),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(opacity),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        // Text
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class CreditCardText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color baseColor;
  final Color highlightColor;
  final Color shadowColor;

  const CreditCardText({
    Key? key,
    required this.text,
    this.fontSize = 24,
    this.baseColor = const Color(0xFFD0D0D0),
    this.highlightColor = const Color(0xFFF0F0F0),
    this.shadowColor = const Color(0xFF9E9E9E),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // Base layer
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: baseColor,
          ),
        ),
        // Highlight layer
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..shader = ui.Gradient.linear(
                const Offset(0, 0),
                Offset(0, fontSize),
                [
                  highlightColor,
                  baseColor,
                ],
              ),
          ),
        ),
        // Shadow layer
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..strokeWidth = 2
              ..color = shadowColor
              ..style = PaintingStyle.stroke
              ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4),
          ),
        ),
      ],
    );
  }
}

class DatePicker extends StatefulWidget {
  TextEditingController control;
  String texto;
  DateTime? initialDate;
  DatePicker({super.key, required this.control, required this.texto, this.initialDate});

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  DateTime? selectedDate;
  final DateTime _firstDate = DateTime(DateTime.now().year - 5);
  final DateTime _lastDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.control,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        /*suffixIcon:
                                IconButton(
        icon: const Icon(Icons.edit_calendar_rounded),
        onPressed: () => {},
      ),*/
        labelText: widget.texto,
        helperText: 'DD/MM/YYYY',
        filled: false,
      ),
      readOnly: true, // when true user cannot edit text
      onTap: () async {
        //showDatePicker
        DateTime? date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: _firstDate,
          lastDate: _lastDate,
        );
        if (date != null) {
          String formattedDate =
              DateFormat.yMd().format(date); // date.toString();
          // format date in required form here we use yyyy-MM-dd that means time is removed
          //formatted date output using intl package =>  2022-07-04
          //You can format date as per your need
          setState(() {
            selectedDate = date;
            widget.control.text = formattedDate;
          });
        } else {
          print("Date is not selected");
        }
      },
      //icon: const Icon(Icons.calendar_month),
    );
  }
}

class DatePicker2 extends StatefulWidget {
  TextEditingController control;
  String texto;
  DatePicker2({super.key, required this.control, required this.texto});

  @override
  State<DatePicker2> createState() => _DatePickerState2();
}

class _DatePickerState2 extends State<DatePicker2> {
  DateTime? selectedDate;
  final DateTime _firstDate = DateTime(DateTime.now().year - 5);
  final DateTime _lastDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        controller: widget.control,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                selectedDate = null;
                widget.control.clear();
              });
            },
          ),
          labelText: widget.texto,
          helperText: 'DD/MM/YYYY',
          filled: false,
        ),
        readOnly: true,
        onTap: () async {
          DateTime? date = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: _firstDate,
            lastDate: _lastDate,
          );
          if (date != null) {
            String formattedDate = DateFormat.yMd().format(date);
            setState(() {
              selectedDate = date;
              widget.control.text = formattedDate;
            });
          }
        },
      ),
    );
  }
}

class ClearButton extends StatelessWidget {
  const ClearButton({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => controller.clear(),
      );
}

T parseEnum<T>(String value, List<T> enumValues) {
  for (var enumValue in enumValues) {
    //print('*******');
    //print(value.toLowerCase().replaceAll(' ', ''));
    //print(enumValue.toString().split('.')[1].toLowerCase());
    if (value.toLowerCase().replaceAll(' ', '') ==
        enumValue.toString().split('.')[1].toLowerCase()) {
      return enumValue;
    }
  }
  throw Exception('Texto $value ${value.toLowerCase().replaceAll(' ', '')} no válido para convertir a enum $enumValues ${enumValues[1].toString().split('.')[1].toLowerCase()}');
}

String formatearFecha(DateTime fecha) {
  initializeDateFormatting('es_MX');
  final formato = DateFormat('d \'de\' MMMM yyyy', 'es');
  return formato.format(fecha);
}
