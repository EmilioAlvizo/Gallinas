import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

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
