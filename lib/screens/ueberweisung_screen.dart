import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../data/mock_data.dart';
import '../models/beneficiary.dart';
import '../utils/german_formatter.dart';
import '../widgets/sepa_form_fields.dart';
import '../widgets/transfer_blocked_sheet.dart';
import '../widgets/dkb_connect_sheet.dart';

class UeberweisungScreen extends StatefulWidget {
  const UeberweisungScreen({super.key});

  @override
  State<UeberweisungScreen> createState() => _UeberweisungScreenState();
}

class _UeberweisungScreenState extends State<UeberweisungScreen> {
  final _formKey = GlobalKey<FormState>();
  final _empfaengerController = TextEditingController();
  final _ibanController = TextEditingController();
  final _bicController = TextEditingController();
  final _betragController = TextEditingController();
  final _verwendungszweckController = TextEditingController();
  DateTime _buchungsdatum = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _empfaengerController.dispose();
    _ibanController.dispose();
    _bicController.dispose();
    _betragController.dispose();
    _verwendungszweckController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final rawIban = _ibanController.text.replaceAll(' ', '');
    final state = AppState();

    // ── Gate: must be a saved beneficiary ────────────────────────────────
    if (!state.isBeneficiary(rawIban)) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        builder: (_) => TransferBlockedSheet(
          recipientName: _empfaengerController.text.trim(),
          iban: GermanFormatter.ibanFormatiert(_ibanController.text),
          onAddBeneficiary: () => showDkbConnectSheet(
            context,
            prefillIban: rawIban,
            onSuccess: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Begünstigter verknüpft. Sie können jetzt überweisen.'),
                ),
              );
            },
          ),
        ),
      );
      return;
    }

    // ── Proceed: beneficiary confirmed ────────────────────────────────────
    final betrag = GermanFormatter.parseGermanBetrag(_betragController.text);
    if (betrag > MockData.girokonto.verfuegbar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kontodeckung nicht ausreichend')),
      );
      return;
    }

    // Auto-fill recipient name from beneficiary if field is empty
    final ben = state.findBeneficiary(rawIban);
    if (ben != null && _empfaengerController.text.trim().isEmpty) {
      _empfaengerController.text = ben.name;
    }

    final confirmed = await _showConfirmation(betrag);
    if (!confirmed || !mounted) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    final ref = AppState().ueberweisenAusfuehren(
      empfaengerName: _empfaengerController.text.trim(),
      iban: rawIban,
      bic: _bicController.text.trim().isEmpty ? 'SSKMDEMMXXX' : _bicController.text.trim(),
      betrag: betrag,
      verwendungszweck: _verwendungszweckController.text.trim().isEmpty
          ? 'Überweisung'
          : _verwendungszweckController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    _showSuccess(ref, betrag);
  }

Future<bool> _showConfirmation(double betrag) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(
              'Überweisung bestätigen',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ConfirmRow('Empfänger', _empfaengerController.text),
                _ConfirmRow('IBAN', GermanFormatter.ibanFormatiert(_ibanController.text)),
                _ConfirmRow('BIC', _bicController.text),
                _ConfirmRow('Betrag', GermanFormatter.waehrung(betrag)),
                _ConfirmRow('Verwendungszweck', _verwendungszweckController.text),
                _ConfirmRow('Buchungsdatum', GermanFormatter.datum(_buchungsdatum)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Abbrechen',
                  style: GoogleFonts.inter(color: DkbColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
                child: const Text('Bestätigen'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccess(String ref, double betrag) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: DkbColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: DkbColors.success, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Überweisung ausgeführt',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: DkbColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              GermanFormatter.waehrung(betrag),
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: DkbColors.danger,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'an ${_empfaengerController.text}',
              style: GoogleFonts.inter(color: DkbColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DkbColors.background,
                borderRadius: BorderRadius.circular(DkbRadius.sm),
              ),
              child: Text(
                'Referenz: $ref',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 12,
                  color: DkbColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _formKey.currentState?.reset();
              _empfaengerController.clear();
              _ibanController.clear();
              _bicController.clear();
              _betragController.clear();
              _verwendungszweckController.clear();
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
            child: const Text('Fertig'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Überweisung')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // From account info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DkbColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(DkbRadius.sm),
                border: Border.all(color: DkbColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance, color: DkbColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Von: Girokonto',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: DkbColors.primary,
                        ),
                      ),
                      Text(
                        'Verfügbar: ${GermanFormatter.waehrung(MockData.girokonto.verfuegbar)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: DkbColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Saved beneficiaries quick-select
            if (MockData.beneficiaries.isNotEmpty) ...[
              buildFieldLabel('Gespeicherte Begünstigte'),
              const SizedBox(height: 8),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: MockData.beneficiaries.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final b = MockData.beneficiaries[i];
                    return _BeneficiaryChip(
                      beneficiary: b,
                      onTap: () {
                        _empfaengerController.text = b.name;
                        _ibanController.text = b.ibanFormatiert;
                        _bicController.text = b.bic;
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            buildFieldLabel('Empfänger'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _empfaengerController,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.isEmpty) ? 'Empfänger eingeben' : null,
              decoration: const InputDecoration(
                hintText: 'Vor- und Nachname oder Firmenname',
                prefixIcon: Icon(Icons.person_outline, color: DkbColors.textMuted),
              ),
            ),

            const SizedBox(height: 16),

            buildFieldLabel('IBAN'),
            const SizedBox(height: 6),
            IbanTextField(
              controller: _ibanController,
              onBicResolved: (bic) => setState(() => _bicController.text = bic),
              validator: (val) {
                if (val == null || val.isEmpty) return 'IBAN eingeben';
                final clean = val.replaceAll(' ', '').toUpperCase();
                if (!clean.startsWith('DE')) return 'Bitte eine deutsche IBAN eingeben (DE...)';
                if (clean.length < 15) return 'IBAN ist zu kurz';
                return null;
              },
            ),

            const SizedBox(height: 16),

            buildFieldLabel('BIC'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _bicController,
              readOnly: true,
              style: GoogleFonts.ibmPlexMono(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Wird automatisch ermittelt...',
                fillColor: DkbColors.background,
                filled: true,
                prefixIcon: const Icon(Icons.info_outline, color: DkbColors.textMuted),
              ),
            ),

            const SizedBox(height: 16),

            buildFieldLabel('Betrag'),
            const SizedBox(height: 6),
            BetragTextField(controller: _betragController),

            const SizedBox(height: 16),

            buildFieldLabel('Verwendungszweck (optional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _verwendungszweckController,
              maxLength: 140,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'z.B. Rechnung Mai 2026',
                counterText: '',
              ),
            ),

            const SizedBox(height: 16),

            buildFieldLabel('Buchungsdatum'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _buchungsdatum,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                  locale: const Locale('de', 'DE'),
                  selectableDayPredicate: (d) =>
                      d.weekday != DateTime.saturday && d.weekday != DateTime.sunday,
                );
                if (picked != null) setState(() => _buchungsdatum = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: DkbColors.surface,
                  borderRadius: BorderRadius.circular(DkbRadius.md),
                  border: Border.all(color: DkbColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: DkbColors.textMuted, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      GermanFormatter.datum(_buchungsdatum),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: DkbColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: DkbColors.textMuted, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Jetzt überweisen'),
            ),

            const SizedBox(height: 16),

            Center(
              child: Text(
                'SEPA-Überweisung · Keine Gebühren · Gutschrift 1–2 Werktage',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: DkbColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _BeneficiaryChip extends StatelessWidget {
  final Beneficiary beneficiary;
  final VoidCallback onTap;
  const _BeneficiaryChip({required this.beneficiary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: DkbColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(DkbRadius.md),
          border: Border.all(color: DkbColors.primary.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: DkbColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      beneficiary.name[0].toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: DkbColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    beneficiary.name.split(' ').first,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: DkbColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              beneficiary.ibanMaskiert,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 10,
                color: DkbColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildFieldLabel(String text) {
  return Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: DkbColors.textSecondary,
    ),
  );
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConfirmRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: DkbColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600, color: DkbColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
