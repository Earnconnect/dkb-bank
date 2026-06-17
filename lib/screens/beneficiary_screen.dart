import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../models/beneficiary.dart';
import '../utils/german_formatter.dart';
import '../widgets/dkb_connect_sheet.dart';

class BeneficiaryScreen extends StatefulWidget {
  const BeneficiaryScreen({super.key});

  @override
  State<BeneficiaryScreen> createState() => _BeneficiaryScreenState();
}

class _BeneficiaryScreenState extends State<BeneficiaryScreen> {
  void _refresh() => setState(() {});

  @override
  void initState() {
    super.initState();
    AppState().addListener(_refresh);
  }

  @override
  void dispose() {
    AppState().removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = MockData.beneficiaries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Begünstigte'),
        actions: [
          TextButton.icon(
            onPressed: () => showDkbConnectSheet(
              context,
              onSuccess: () => setState(() {}),
            ),
            icon: const Icon(Icons.add, color: DkbColors.accent, size: 18),
            label: Text(
              'Hinzufügen',
              style: GoogleFonts.inter(
                color: DkbColors.accent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header info banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DkbColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(DkbRadius.md),
              border:
                  Border.all(color: DkbColors.primary.withValues(alpha: 0.12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    color: DkbColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nur verknüpfte DKB-Konten können Überweisungsempfänger sein. '
                    'Verknüpfen Sie das Konto des Empfängers mit dessen DKB-Zugangsdaten.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: DkbColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (list.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: DkbColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.people_outline,
                          color: DkbColors.primary, size: 36),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Keine Begünstigten',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: DkbColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fügen Sie DKB-Konten als Begünstigte hinzu,\num Überweisungen zu ermöglichen.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: DkbColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => showDkbConnectSheet(
                        context,
                        onSuccess: () => setState(() {}),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Begünstigten hinzufügen'),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _BeneficiaryTile(
                  beneficiary: list[i],
                  onDelete: () {
                    AppState().beneficiaryLoeschen(list[i].id);
                  },
                ).animate().fadeIn(
                      duration: 300.ms,
                      delay: Duration(milliseconds: i * 60),
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BeneficiaryTile extends StatelessWidget {
  final Beneficiary beneficiary;
  final VoidCallback onDelete;

  const _BeneficiaryTile({
    required this.beneficiary,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(beneficiary.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: DkbColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(DkbRadius.md),
        ),
        child: const Icon(Icons.delete_outline, color: DkbColors.danger),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Begünstigten entfernen',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            content: Text(
              '${beneficiary.name} aus den Begünstigten entfernen?',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Abbrechen',
                    style: GoogleFonts.inter(color: DkbColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DkbColors.danger,
                  minimumSize: const Size(80, 40),
                ),
                child: const Text('Entfernen'),
              ),
            ],
          ),
        ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DkbColors.surface,
          borderRadius: BorderRadius.circular(DkbRadius.md),
          border: Border.all(color: DkbColors.divider),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: DkbColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  beneficiary.name.isNotEmpty
                      ? beneficiary.name[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: DkbColors.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    beneficiary.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DkbColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    beneficiary.ibanMaskiert,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 12,
                      color: DkbColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: DkbColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified,
                                color: DkbColors.success, size: 11),
                            const SizedBox(width: 3),
                            Text(
                              'DKB verifiziert',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: DkbColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'seit ${GermanFormatter.datum(beneficiary.verknuepftAm)}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: DkbColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right,
                color: DkbColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
