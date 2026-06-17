import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/iban_validator.dart';

class IbanTextField extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String bic)? onBicResolved;
  final String? Function(String?)? validator;

  const IbanTextField({
    super.key,
    required this.controller,
    this.onBicResolved,
    this.validator,
  });

  @override
  State<IbanTextField> createState() => _IbanTextFieldState();
}

class _IbanTextFieldState extends State<IbanTextField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.characters,
      maxLength: 29,
      inputFormatters: [_IbanFormatter()],
      onChanged: (val) {
        final clean = val.replaceAll(' ', '');
        final bic = IbanValidator.bicLookup(clean);
        if (bic != null && widget.onBicResolved != null) {
          widget.onBicResolved!(bic);
        }
      },
      validator: widget.validator ??
          (val) {
            if (val == null || val.isEmpty) return 'IBAN eingeben';
            if (!IbanValidator.isValid(val)) return 'Ungültige IBAN';
            return null;
          },
      decoration: const InputDecoration(
        labelText: 'IBAN',
        hintText: 'DE00 0000 0000 0000 0000 00',
        counterText: '',
      ),
      style: GoogleFonts.ibmPlexMono(fontSize: 14, letterSpacing: 1),
    );
  }
}

class _IbanFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.toUpperCase().replaceAll(' ', '');
    if (raw.isEmpty) return newValue.copyWith(text: '');

    final buf = StringBuffer();
    for (int i = 0; i < raw.length && i < 22; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(raw[i]);
    }
    final result = buf.toString();
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

class BetragTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const BetragTextField({
    super.key,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_BetragFormatter()],
      validator: validator ??
          (val) {
            if (val == null || val.isEmpty) return 'Betrag eingeben';
            final amount = double.tryParse(
                val.replaceAll('.', '').replaceAll(',', '.'));
            if (amount == null || amount <= 0) return 'Ungültiger Betrag';
            return null;
          },
      decoration: const InputDecoration(
        labelText: 'Betrag',
        hintText: '0,00',
        suffixText: '€',
      ),
      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
    );
  }
}

class _BetragFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    // Allow digits, comma, period — and only one decimal separator
    final filtered = StringBuffer();
    bool hasDecimal = false;
    for (final c in text.split('')) {
      if (c == ',' || c == '.') {
        if (!hasDecimal) {
          filtered.write(',');
          hasDecimal = true;
        }
      } else if (RegExp(r'[0-9]').hasMatch(c)) {
        filtered.write(c);
      }
    }
    final result = filtered.toString();
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

class VerwendungszweckTextField extends StatelessWidget {
  final TextEditingController controller;

  const VerwendungszweckTextField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: 140,
      maxLines: 2,
      validator: (val) =>
          (val == null || val.isEmpty) ? 'Verwendungszweck eingeben' : null,
      decoration: const InputDecoration(
        labelText: 'Verwendungszweck',
        hintText: 'z.B. Rechnung Mai 2026',
        alignLabelWithHint: true,
      ),
    );
  }
}
