import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../data/mock_data.dart';
import '../models/dauerauftrag.dart';
import '../utils/german_formatter.dart';
import '../widgets/sepa_form_fields.dart';

class DauerauftragScreen extends StatefulWidget {
  const DauerauftragScreen({super.key});

  @override
  State<DauerauftragScreen> createState() => _DauerauftragScreenState();
}

class _DauerauftragScreenState extends State<DauerauftragScreen> {
  final _state = AppState();

  void _refresh() => setState(() {});

  @override
  void initState() {
    super.initState();
    _state.addListener(_refresh);
  }

  @override
  void dispose() {
    _state.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = MockData.dauerauftraege;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daueraufträge'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showErstellenSheet(),
          ),
        ],
      ),
      body: list.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.repeat, size: 48, color: DkbColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'Keine Daueraufträge vorhanden',
                    style: GoogleFonts.inter(color: DkbColors.textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _showErstellenSheet(),
                    child: Text(
                      'Dauerauftrag einrichten',
                      style: GoogleFonts.inter(color: DkbColors.accent),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final da = list[i];
                return Dismissible(
                  key: Key(da.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: DkbColors.danger,
                      borderRadius: BorderRadius.circular(DkbRadius.md),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('Löschen?',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                        content: Text(
                          'Dauerauftrag an ${da.empfaengerName} wirklich löschen?',
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Abbrechen'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DkbColors.danger,
                              minimumSize: const Size(80, 40),
                            ),
                            child: const Text('Löschen'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) => _state.dauerauftragLoeschen(da.id),
                  child: _DauerauftragCard(
                    da: da,
                    onToggle: () => _state.dauerauftragUmschalten(da.id),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: DkbColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showErstellenSheet(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showErstellenSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DauerauftragErstellenSheet(
        onCreated: (da) => _state.dauerauftragHinzufuegen(da),
      ),
    );
  }
}

class _DauerauftragCard extends StatelessWidget {
  final Dauerauftrag da;
  final VoidCallback onToggle;

  const _DauerauftragCard({required this.da, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final initial = da.empfaengerName.isNotEmpty ? da.empfaengerName[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DkbColors.surface,
        borderRadius: BorderRadius.circular(DkbRadius.md),
        boxShadow: DkbShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: DkbColors.primary,
              borderRadius: BorderRadius.circular(DkbRadius.sm),
            ),
            child: Center(
              child: Text(
                initial,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  da.empfaengerName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DkbColors.textPrimary,
                  ),
                ),
                Text(
                  da.ibanMaskiert,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    color: DkbColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: DkbColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(DkbRadius.xs),
                      ),
                      child: Text(
                        da.turnusLabel,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: DkbColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Nächste: ${GermanFormatter.datumKurz(da.naechsteAusfuehrung)}${da.naechsteAusfuehrung.year}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: DkbColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                GermanFormatter.waehrung(da.betrag),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: DkbColors.textPrimary,
                ),
              ),
              Switch(
                value: da.isAktiv,
                onChanged: (_) => onToggle(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DauerauftragErstellenSheet extends StatefulWidget {
  final void Function(Dauerauftrag) onCreated;

  const _DauerauftragErstellenSheet({required this.onCreated});

  @override
  State<_DauerauftragErstellenSheet> createState() =>
      _DauerauftragErstellenSheetState();
}

class _DauerauftragErstellenSheetState extends State<_DauerauftragErstellenSheet> {
  final _formKey = GlobalKey<FormState>();
  final _empfController = TextEditingController();
  final _ibanController = TextEditingController();
  final _bicController = TextEditingController();
  final _betragController = TextEditingController();
  final _vwzController = TextEditingController();
  Turnus _turnus = Turnus.monatlich;
  DateTime _ersteAusfuehrung = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _empfController.dispose();
    _ibanController.dispose();
    _bicController.dispose();
    _betragController.dispose();
    _vwzController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final da = Dauerauftrag(
      id: 'da-${MockData.dauerauftraege.length + 1}',
      vonKontoId: 'giro-001',
      empfaengerName: _empfController.text.trim(),
      iban: _ibanController.text.replaceAll(' ', ''),
      bic: _bicController.text.trim(),
      betrag: GermanFormatter.parseGermanBetrag(_betragController.text),
      verwendungszweck: _vwzController.text.trim(),
      turnus: _turnus,
      naechsteAusfuehrung: _ersteAusfuehrung,
    );
    widget.onCreated(da);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Dauerauftrag an ${da.empfaengerName} eingerichtet')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DkbColors.surface,
        borderRadius: BorderRadius.circular(DkbRadius.xl),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: DkbColors.divider,
                    borderRadius: BorderRadius.circular(DkbRadius.full),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Dauerauftrag einrichten',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _empfController,
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.isEmpty) ? 'Empfänger eingeben' : null,
                decoration: const InputDecoration(labelText: 'Empfänger'),
              ),
              const SizedBox(height: 12),
              IbanTextField(
                controller: _ibanController,
                onBicResolved: (bic) => setState(() => _bicController.text = bic),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bicController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'BIC',
                  fillColor: DkbColors.background,
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              BetragTextField(controller: _betragController),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vwzController,
                decoration: const InputDecoration(labelText: 'Verwendungszweck'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Turnus>(
                initialValue: _turnus,
                decoration: const InputDecoration(labelText: 'Turnus'),
                items: Turnus.values.map((t) {
                  final label = t == Turnus.woechentlich
                      ? 'Wöchentlich'
                      : t == Turnus.monatlich
                          ? 'Monatlich'
                          : 'Vierteljährlich';
                  return DropdownMenuItem(value: t, child: Text(label));
                }).toList(),
                onChanged: (v) => setState(() => _turnus = v!),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _ersteAusfuehrung,
                    firstDate: DateTime.now().add(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    locale: const Locale('de', 'DE'),
                  );
                  if (picked != null) setState(() => _ersteAusfuehrung = picked);
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
                          color: DkbColors.textMuted, size: 16),
                      const SizedBox(width: 10),
                      Text(
                        'Erste Ausführung: ${GermanFormatter.datum(_ersteAusfuehrung)}',
                        style: GoogleFonts.inter(fontSize: 13, color: DkbColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Dauerauftrag einrichten'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
