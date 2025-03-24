// ignore_for_file: non_constant_identifier_names

import 'package:brasil_fields/brasil_fields.dart';
import 'package:cirurgiapp/src/components/style_constants/colors.dart';
import 'package:cirurgiapp/src/components/style_constants/text_field_style.dart';
import 'package:cirurgiapp/src/components/style_constants/tipography.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// A simple text field to be used for a simple text input, with options to
/// validate cpf, email or if the input is empty. There is also a option to only allow digits in case you need this. <br/>
/// <br/>
/// If you want to hide the label, pass this atribute as an empty string.<br/>
/// <br/>
/// There is a dark and a light version to be **used accordingly**.
class SimpleTextField extends StatefulWidget {
  const SimpleTextField({
    super.key,
    required this.dark,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.errorMessage,
    this.onChanged,
    this.isCPF = false,
    this.isEmail = false,
    this.digitsOnly = false,
    this.validation,
    this.initialValue,
  });

  final bool dark;
  final String label;
  final String hintText;
  final TextEditingController controller;
  final String errorMessage;
  final String? Function(String? value)? onChanged;
  final bool isCPF;
  final bool isEmail;
  final bool digitsOnly;
  final bool? validation;
  final String? initialValue;

  @override
  State<SimpleTextField> createState() => _SimpleTextFieldState();
}

class _SimpleTextFieldState extends State<SimpleTextField> {
  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      widget.controller.text = widget.initialValue!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty)
          Text(
            widget.label,
            style: BODY(textColor: widget.dark ? MY_WHITE : MY_BLACK)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        const SizedBox(height: 5),
        TextFormField(
          // initialValue: widget.controller.text,
          controller: widget.controller,
          keyboardType: (widget.digitsOnly || widget.isCPF)
              ? const TextInputType.numberWithOptions(decimal: true)
              : null,
          inputFormatters: [
            if (widget.isCPF || widget.digitsOnly)
              FilteringTextInputFormatter.digitsOnly,
            if (widget.isCPF) CpfInputFormatter(),
          ],
          cursorColor: widget.dark ? MY_WHITE : MY_BLACK,
          style: GoogleFonts.mulish(
            color: widget.dark ? MY_WHITE : MY_BLACK,
            fontWeight: FontWeight.w700,
          ),
          decoration: widget.dark
              ? darkTextFieldDecor.copyWith(
                  hintText: widget.hintText,
                  hintStyle: BODY(textColor: MY_WHITE)
                      .copyWith(fontWeight: FontWeight.w600),
                )
              : lightTextFieldDecor.copyWith(
                  hintText: widget.hintText,
                  hintStyle: BODY().copyWith(fontWeight: FontWeight.w600),
                ),
          onChanged: widget.onChanged,
          validator: (value) {
            if (widget.isEmail &&
                EmailValidator.validate(widget.controller.text) == false) {
              return 'Digite um email válido';
            } else if (widget.isCPF &&
                UtilBrasilFields.isCPFValido(widget.controller.text) == false) {
              return 'Digite um CPF válido';
            } else if (widget.controller.text.isEmpty) {
              return "Este campo não pode ser nulo";
            } else if (widget.validation != null && widget.validation == true) {
              return widget.errorMessage;
            } else {
              return null;
            }
          },
        ),
      ],
    );
  }
}

/// A text field to be used for a simple text input that requires an option to
/// obscure the input, to be used for password or sensitive data that the user
/// may like to hide. The default validation of this widget is validate a
/// password with 6 digits, in case you set the atributte "isPassword" to false
/// the validation will allow any combinations minus an empty input. <br/>
/// _**This widget is a variation of the SimpleTextField**_ <br/>
/// <br/>
/// If you want to hide the label, pass this atribute as an empty string.<br/>
/// <br/>
/// There is a dark and a light version to be **used accordingly**.

// Componente ObscureTextField Atualizado
class ObscureTextField extends StatefulWidget {
  const ObscureTextField({
    super.key,
    required this.dark,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.errorMessage,
    this.onChanged,
    this.validation, // Tipo corrigido
    this.initialValue,
  });

  final bool dark;
  final String label;
  final String hintText;
  final TextEditingController controller;
  final String errorMessage;
  final ValueChanged<String?>? onChanged;
  final bool Function(String?)? validation; // Tipo corrigido
  final String? initialValue;

  @override
  State<ObscureTextField> createState() => _ObscureTextFieldState();
}

class _ObscureTextFieldState extends State<ObscureTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      widget.controller.text = widget.initialValue!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: BODY(textColor: widget.dark ? MY_WHITE : MY_BLACK)
              .copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          cursorColor: widget.dark ? MY_WHITE : MY_BLACK, // Adicione esta linha
          style: GoogleFonts.mulish(
            // Adicione este bloco de estilo
            color: widget.dark ? MY_WHITE : MY_BLACK,
            fontWeight: FontWeight.w700,
          ),
          decoration: _buildDecoration(),
          onChanged: widget.onChanged,
          validator: _validateInput,
        ),
      ],
    );
  }

  InputDecoration _buildDecoration() {
    return (widget.dark ? darkTextFieldDecor : lightTextFieldDecor).copyWith(
      hintText: widget.hintText,
      hintStyle: BODY(textColor: widget.dark ? MY_WHITE : MY_BLACK)
          .copyWith(fontWeight: FontWeight.w600),
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: widget.dark ? MY_WHITE : MY_BLACK,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      ),
    );
  }

  String? _validateInput(String? value) {
    if (widget.validation != null && !widget.validation!(value)) {
      return widget.errorMessage;
    }
    return null;
  }
}

/// A text field to be used when you need to get a date information of your
/// user. <br/>
/// You need to pass a _**start date**_ and an _**end date**_ of the
/// timeframe you want, then it will only allow your user to select a date in
/// between these two, avoiding an input error. Validation takes place only for
/// this interval and the mandatory completion of the field. <br/>
/// <br/>
/// The default start date and end date entries are 01/01/1920 and the present
/// date, respectively. If you want to set the timeframe there is a few
/// restrictions you must follow. The start date **MUST NOT** exceed the date
/// 01/01/1920, otherwise the widget will automatically set the start date to
/// that one. On the other hand, the **ONLY** restriction of the end date is to
/// be after the start date, otherwise it will automatically set the date to
/// the present day.<br/>
/// <br/>
/// If you want to hide the label, pass this atribute as an empty string.<br/>
/// <br/>
/// There is a dark and a light version to be **used accordingly**.
class DatePickerTextField extends StatefulWidget {
  const DatePickerTextField({
    super.key,
    required this.dark,
    required this.label,
    required this.hintText,
    required this.errorMessage,
    required this.dateController,
    required this.startDate,
    required this.endDate,
    this.onChanged,
    this.initialValue,
  });

  final bool dark;
  final String label;
  final String hintText;
  final String errorMessage;
  final TextEditingController dateController;
  final String? Function(String? value)? onChanged;
  final DateTime startDate;
  final DateTime endDate;
  final String? initialValue;

  @override
  State<DatePickerTextField> createState() => _DatePickerTextFieldState();
}

class _DatePickerTextFieldState extends State<DatePickerTextField> {
  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      widget.dateController.text = widget.initialValue!;
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime initialDateCalendar;
    final bool dark = widget.dark;
    final String label = widget.label;
    final String hintText = widget.hintText;
    final TextEditingController dateController = widget.dateController;
    final String errorMessage = widget.errorMessage;
    final String? Function(String? value)? onChanged = widget.onChanged;
    final DateTime startDate = widget.startDate.isBefore(DateTime(1920, 01, 01))
        ? DateTime(1920, 01, 01)
        : widget.startDate;
    final DateTime endDate =
        widget.endDate.isBefore(startDate) ? DateTime.now() : widget.endDate;

    if (endDate.isBefore(DateTime.now())) {
      initialDateCalendar = endDate;
    } else {
      initialDateCalendar = DateTime.now();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Text(
            label,
            style: BODY(textColor: dark ? MY_WHITE : MY_BLACK)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        const SizedBox(height: 5),
        TextFormField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            DataInputFormatter(),
          ],
          controller: dateController,
          cursorColor: dark ? MY_WHITE : MY_BLACK,
          style: GoogleFonts.mulish(
            color: dark ? MY_WHITE : MY_BLACK,
            fontWeight: FontWeight.w700,
          ),
          decoration: dark
              ? darkTextFieldDecor.copyWith(
                  hintText: hintText,
                  hintStyle: BODY(textColor: MY_WHITE)
                      .copyWith(fontWeight: FontWeight.w600),
                )
              : lightTextFieldDecor.copyWith(
                  hintText: hintText,
                  hintStyle: BODY(textColor: MY_BLACK)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
          onChanged: onChanged,
          readOnly: true,
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              locale: const Locale('pt'),
              context: context,
              initialDate: initialDateCalendar,
              firstDate: startDate,
              lastDate: endDate,
            );

            if (pickedDate != null) {
              String formattedDate = UtilData.obterDataDDMMAAAA(pickedDate);
              setState(() {
                dateController.text =
                    formattedDate; //set foratted date to TextField value.

                initialDateCalendar = pickedDate;
              });
            }
          },
          validator: (value) {
            if (dateController.text.isEmpty) {
              return errorMessage;
            } else {
              return null;
            }
          },
        ),
      ],
    );
  }
}

/// A text field to be used when you need to get a time information of your
/// user. <br/>
/// <br/>
/// Unlike the widget DatePickerTextField, this widget doesn't require a start
/// and end date, because the user will only select a time.<br/>
/// <br/>
/// If you want to hide the label, pass this atribute as an empty string.<br/>
/// <br/>
/// There is a dark and a light version to be **used accordingly**.
class TimePickerTextField extends StatefulWidget {
  const TimePickerTextField({
    super.key,
    required this.dark,
    required this.label,
    required this.hintText,
    required this.errorMessage,
    required this.timeController,
    this.onChanged,
    this.initialValue,
  });

  final bool dark;
  final String label;
  final String hintText;
  final String errorMessage;
  final TextEditingController timeController;
  final String? Function(String? value)? onChanged;
  final String? initialValue;

  @override
  State<TimePickerTextField> createState() => _TimePickerTextFieldState();
}

class _TimePickerTextFieldState extends State<TimePickerTextField> {
  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      widget.timeController.text = widget.initialValue!;
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    final bool dark = widget.dark;
    final String label = widget.label;
    final String hintText = widget.hintText;
    final String errorMessage = widget.errorMessage;
    final String? Function(String? value)? onChanged = widget.onChanged;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Text(
            label,
            style: BODY(textColor: dark ? MY_WHITE : MY_BLACK)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        const SizedBox(height: 5),
        TextFormField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            HoraInputFormatter(),
          ],
          controller: widget.timeController,
          cursorColor: dark ? MY_WHITE : MY_BLACK,
          style: GoogleFonts.mulish(
            color: dark ? MY_WHITE : MY_BLACK,
            fontWeight: FontWeight.w700,
          ),
          decoration: dark
              ? darkTextFieldDecor.copyWith(
                  hintText: hintText,
                  hintStyle: BODY(textColor: MY_WHITE)
                      .copyWith(fontWeight: FontWeight.w600),
                )
              : lightTextFieldDecor.copyWith(
                  hintText: hintText,
                  hintStyle: BODY(textColor: MY_BLACK)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
          onChanged: onChanged,
          readOnly: true,
          onTap: () async {
            TimeOfDay? pickedHour = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );

            if (pickedHour != null) {
              String formattedDate = UtilData.obterHoraHHMM(
                DateTime(
                  now.year,
                  now.month,
                  now.day,
                  pickedHour.hour,
                  pickedHour.minute,
                ),
              );
              setState(() {
                widget.timeController.text =
                    formattedDate; //set foratted date to TextField value.
              });
            }
          },
          validator: (value) {
            if (widget.timeController.text.isEmpty) {
              return errorMessage;
            } else {
              return null;
            }
          },
        ),
      ],
    );
  }
}
