import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/beneficiary.dart';
import '../state/app_state.dart';
import '../utils/iban_validator.dart';
import '../widgets/sepa_form_fields.dart';
import '../screens/ueberweisung_screen.dart';

void showDkbConnectSheet(
  BuildContext context, {
  String? prefillName,
  String? prefillIban,
  VoidCallback? onSuccess,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DkbConnectSheet(
      prefillName: prefillName,
      prefillIban: prefillIban,
      onSuccess: onSuccess,
    ),
  );
}

class DkbConnectSheet extends StatefulWidget {
  final String? prefillName;
  final String? prefillIban;
  final VoidCallback? onSuccess;

  const DkbConnectSheet({
    super.key,
    this.prefillName,
    this.prefillIban,
    this.onSuccess,
  });

  @override
  State<DkbConnectSheet> createState() => _DkbConnectSheetState();
}

class _DkbConnectSheetState extends State<DkbConnectSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ibanCtrl;
  late final TextEditingController _bicCtrl;
  bool _saving = false;
  bool _success = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.prefillName ?? '');
    _ibanCtrl = TextEditingController(
      text: widget.prefillIban != null
          ? IbanValidator.format(widget.prefillIban!)
          : '',
    );
    _bicCtrl = TextEditingController(
      text: widget.prefillIban != null
          ? IbanValidator.bicLookup(widget.prefillIban!) ?? ''
          : '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ibanCtrl.dispose();
    _bicCtrl.dispose();
    super.dispose();
  }

  Future<void> _hinzufuegen() async {
    if (!_formKey.currentState!.validate()) return;

    final rawIban = _ibanCtrl.text.replaceAll(' ', '').toUpperCase();

    // Duplicate check
    if (AppState().isBeneficiary(rawIban)) {
      setState(() => _errorMsg = 'Dieser Empfänger ist bereits als Begünstigter hinterlegt.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMsg = null;
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final ben = Beneficiary(
      id: 'ben-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      kontonummer: '',
      iban: rawIban,
      bic: _bicCtrl.text.trim().isEmpty ? 'NOTPROVIDED' : _bicCtrl.text.trim(),
      verknuepftAm: DateTime.now(),
    );

    AppState().beneficiaryHinzufuegen(ben);

    setState(() {
      _saving = false;
      _success = true;
    });

    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    Navigator.pop(context);
    widget.onSuccess?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _success
            ? _buildSuccess()
            : _saving
                ? _buildSaving()
                : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      key: const ValueKey('form'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E4EF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'Begünstigten hinzufügen',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: DkbColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Speichern Sie eine IBAN als Begünstigten, um Überweisungen zu ermöglichen.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: DkbColors.textSecondary,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            if (_errorMsg != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DkbColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: DkbColors.danger.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: DkbColors.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMsg!,
                        style: GoogleFonts.inter(fontSize: 12, color: DkbColors.danger),
                      ),
                    ),
                  ],
                ),
              ).animate().shake(),
              const SizedBox(height: 16),
            ],

            // Name
            buildFieldLabel('Name des Empfängers'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name eingeben' : null,
              decoration: const InputDecoration(
                hintText: 'Vor- und Nachname oder Firmenname',
                prefixIcon: Icon(Icons.person_outline, color: DkbColors.textMuted),
              ),
            ),

            const SizedBox(height: 16),

            // IBAN — any valid DE IBAN
            buildFieldLabel('IBAN'),
            const SizedBox(height: 6),
            IbanTextField(
              controller: _ibanCtrl,
              onBicResolved: (bic) => setState(() => _bicCtrl.text = bic),
            ),

            const SizedBox(height: 16),

            // BIC (auto-filled, editable)
            buildFieldLabel('BIC'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _bicCtrl,
              style: GoogleFonts.ibmPlexMono(fontSize: 14),
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Wird automatisch ermittelt...',
                prefixIcon: Icon(Icons.info_outline, color: DkbColors.textMuted),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _hinzufuegen,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text('Begünstigten speichern'),
            ),

            const SizedBox(height: 10),

            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Abbrechen',
                  style: GoogleFonts.inter(
                    color: DkbColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaving() {
    return SizedBox(
      key: const ValueKey('saving'),
      height: 280,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(DkbColors.accent),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Begünstigter wird gespeichert...',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: DkbColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Einen Moment bitte',
            style: GoogleFonts.inter(fontSize: 13, color: DkbColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return SizedBox(
      key: const ValueKey('success'),
      height: 300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: DkbColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                color: DkbColors.success, size: 38),
          )
              .animate()
              .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text(
            'Begünstigter gespeichert!',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: DkbColors.textPrimary,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            _nameCtrl.text.trim(),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: DkbColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 6),
          Text(
            'Sie können jetzt an diese IBAN überweisen.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: DkbColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 350.ms),
        ],
      ),
    );
  }
}
