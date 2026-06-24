const prisma = require('./_db');
const bcrypt = require('bcryptjs');
const { respond, respondOptions } = require('./_helpers');

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return respondOptions();
  if (event.httpMethod !== 'POST') return respond(405, { error: 'Method not allowed' });

  const existing = await prisma.user.findUnique({ where: { kontonummer: '12345678' } });
  if (existing) return respond(409, { error: 'Datenbank bereits befüllt' });

  try {
    const pinHash = await bcrypt.hash('1234', 10);

    const user = await prisma.user.create({
      data: {
        kontonummer: '12345678',
        pinHash,
        name: 'Max Mustermann',
        email: 'max.mustermann@email.de',
        adresse: 'Musterstraße 1, 10115 Berlin',
        kundeSeit: new Date('2018-03-15'),
        girokonto: {
          create: {
            iban: 'DE12120300001012345678',
            bic: 'SSKMDEMMXXX',
            kontonummer: '1012345678',
            saldo: 2847.50,
            verfuegbar: 2847.50,
            ueberziehungsrahmen: 500.0,
          },
        },
        visaKarte: {
          create: {
            kartenNummer: '4000000000004521',
            ablaufdatum: '09/29',
            karteninhaber: 'MAX MUSTERMANN',
            kreditlimit: 3000.0,
            aktuellerSaldo: 156.80,
            unbezahlt: 156.80,
            abrechnungsperiodeBeginn: new Date('2026-06-01'),
            abrechnungsperiodeEnde: new Date('2026-06-30'),
          },
        },
      },
      include: { girokonto: true, visaKarte: true },
    });

    const giroId = user.girokonto.id;
    const visaId = user.visaKarte.id;

    await prisma.umsatz.createMany({
      data: [
        { girokontoId: giroId, buchungsdatum: new Date('2026-06-15'), wertstellung: new Date('2026-06-15'), auftraggeber: 'Muster GmbH', empfaenger: 'Max Mustermann', verwendungszweck: 'Gehalt Juni 2026', betrag: 2800.00, typ: 'gutschrift', kategorie: 'gehalt', referenznummer: 'REF-001' },
        { girokontoId: giroId, buchungsdatum: new Date('2026-06-14'), wertstellung: new Date('2026-06-14'), auftraggeber: 'Max Mustermann', empfaenger: 'Wohnungsgesellschaft Berlin GmbH', verwendungszweck: 'Miete Juni 2026 Musterstraße 1', betrag: 950.00, typ: 'belastung', kategorie: 'miete' },
        { girokontoId: giroId, buchungsdatum: new Date('2026-06-13'), wertstellung: new Date('2026-06-13'), auftraggeber: 'Max Mustermann', empfaenger: 'REWE Supermarkt', verwendungszweck: 'Einkauf REWE Berlin Mitte', betrag: 67.43, typ: 'belastung', kategorie: 'lebensmittel' },
        { girokontoId: giroId, buchungsdatum: new Date('2026-06-12'), wertstellung: new Date('2026-06-12'), auftraggeber: 'Max Mustermann', empfaenger: 'Deutsche Bahn AG', verwendungszweck: 'BahnCard 50 Verlängerung', betrag: 89.00, typ: 'belastung', kategorie: 'transport' },
        { girokontoId: giroId, buchungsdatum: new Date('2026-06-11'), wertstellung: new Date('2026-06-11'), auftraggeber: 'Amazon EU SARL', empfaenger: 'Max Mustermann', verwendungszweck: 'Amazon Rückerstattung', betrag: 34.99, typ: 'gutschrift', kategorie: 'onlineEinkauf' },
        { girokontoId: giroId, buchungsdatum: new Date('2026-06-10'), wertstellung: new Date('2026-06-10'), auftraggeber: 'Max Mustermann', empfaenger: 'Spotify AB', verwendungszweck: 'Spotify Premium Monatsbeitrag', betrag: 9.99, typ: 'belastung', kategorie: 'abonnement' },
        { girokontoId: giroId, buchungsdatum: new Date('2026-06-10'), wertstellung: new Date('2026-06-10'), auftraggeber: 'Max Mustermann', empfaenger: 'Netflix International B.V.', verwendungszweck: 'Netflix Monatsabo Standard', betrag: 17.99, typ: 'belastung', kategorie: 'abonnement' },
        { girokontoId: giroId, buchungsdatum: new Date('2026-06-09'), wertstellung: new Date('2026-06-09'), auftraggeber: 'Max Mustermann', empfaenger: 'Lidl Dienstleistung', verwendungszweck: 'Lidl Filiale Berlin Mitte', betrag: 45.12, typ: 'belastung', kategorie: 'lebensmittel' },
        { girokontoId: giroId, buchungsdatum: new Date('2026-06-08'), wertstellung: new Date('2026-06-08'), auftraggeber: 'PayPal Europe SARL', empfaenger: 'Max Mustermann', verwendungszweck: 'Rückzahlung Urlaub Mallorca', betrag: 250.00, typ: 'gutschrift', kategorie: 'ueberweisung' },
        { girokontoId: giroId, buchungsdatum: new Date('2026-06-07'), wertstellung: new Date('2026-06-07'), auftraggeber: 'Max Mustermann', empfaenger: 'BVG Berliner Verkehrsbetriebe', verwendungszweck: 'Monatskarte Juni 2026 AB', betrag: 86.00, typ: 'belastung', kategorie: 'transport' },
        { girokontoId: giroId, buchungsdatum: new Date('2026-06-06'), wertstellung: new Date('2026-06-06'), auftraggeber: 'Max Mustermann', empfaenger: 'Vodafone GmbH', verwendungszweck: 'Mobilfunk Rechnung Mai 2026', betrag: 29.99, typ: 'belastung', kategorie: 'versicherung' },
        { girokontoId: giroId, buchungsdatum: new Date('2026-06-05'), wertstellung: new Date('2026-06-05'), auftraggeber: 'Max Mustermann', empfaenger: 'AOK Berlin-Brandenburg', verwendungszweck: 'Krankenversicherungsbeitrag Juni 2026', betrag: 120.50, typ: 'belastung', kategorie: 'versicherung' },
        { girokontoId: giroId, buchungsdatum: new Date('2026-06-04'), wertstellung: new Date('2026-06-04'), auftraggeber: 'Max Mustermann', empfaenger: 'Zalando SE', verwendungszweck: 'Zalando Bestellung Nr. Z-4829-1100', betrag: 129.90, typ: 'belastung', kategorie: 'onlineEinkauf' },
        { girokontoId: giroId, buchungsdatum: new Date('2026-06-03'), wertstellung: new Date('2026-06-03'), auftraggeber: 'Max Mustermann', empfaenger: "McDonald's Berlin Alexanderplatz", verwendungszweck: 'Restaurant Bezahlung', betrag: 8.50, typ: 'belastung', kategorie: 'restaurant' },
        { girokontoId: giroId, buchungsdatum: new Date('2026-06-02'), wertstellung: new Date('2026-06-02'), auftraggeber: 'Max Mustermann', empfaenger: 'Shell Deutschland GmbH', verwendungszweck: 'Tankstelle Shell Berlin Prenzlauer Berg', betrag: 65.00, typ: 'belastung', kategorie: 'transport' },
        { girokontoId: giroId, buchungsdatum: new Date('2026-06-02'), wertstellung: new Date('2026-06-02'), auftraggeber: 'Max Mustermann', empfaenger: 'Apotheke am Bahnhof', verwendungszweck: 'Medikamente Rezept', betrag: 23.60, typ: 'belastung', kategorie: 'gesundheit' },
        { girokontoId: giroId, buchungsdatum: new Date('2026-06-01'), wertstellung: new Date('2026-06-01'), auftraggeber: 'Max Mustermann', empfaenger: 'ARD ZDF Deutschlandradio', verwendungszweck: 'Rundfunkbeitrag 2. Quartal 2026', betrag: 18.36, typ: 'belastung', kategorie: 'gebuehr' },
        { girokontoId: giroId, buchungsdatum: new Date('2026-06-01'), wertstellung: new Date('2026-06-01'), auftraggeber: 'Max Mustermann', empfaenger: 'H&M Hennes & Mauritz', verwendungszweck: 'H&M Online Shop Bestellung', betrag: 55.00, typ: 'belastung', kategorie: 'onlineEinkauf' },
        { girokontoId: giroId, buchungsdatum: new Date('2026-05-31'), wertstellung: new Date('2026-05-31'), auftraggeber: 'Max Mustermann', empfaenger: 'Klaus Mustermann', verwendungszweck: 'Rückzahlung Abendessen', betrag: 200.00, typ: 'belastung', kategorie: 'ueberweisung' },
        { visaKarteId: visaId, buchungsdatum: new Date('2026-06-13'), wertstellung: new Date('2026-06-13'), auftraggeber: 'Max Mustermann', empfaenger: 'Amazon.de', verwendungszweck: 'Amazon.de Marketplace Einkauf', betrag: 34.99, typ: 'belastung', kategorie: 'onlineEinkauf' },
        { visaKarteId: visaId, buchungsdatum: new Date('2026-06-11'), wertstellung: new Date('2026-06-11'), auftraggeber: 'Max Mustermann', empfaenger: 'Airbnb Ireland UC', verwendungszweck: 'Airbnb Unterkunft Barcelona', betrag: 89.50, typ: 'belastung', kategorie: 'sonstiges' },
        { visaKarteId: visaId, buchungsdatum: new Date('2026-06-08'), wertstellung: new Date('2026-06-08'), auftraggeber: 'Max Mustermann', empfaenger: 'Rossmann Drogerie', verwendungszweck: 'Rossmann Drogerie Berlin', betrag: 32.31, typ: 'belastung', kategorie: 'lebensmittel' },
      ],
    });

    await prisma.dauerauftrag.createMany({
      data: [
        { girokontoId: giroId, empfaengerName: 'Wohnungsgesellschaft Berlin GmbH', iban: 'DE89370400440532013000', bic: 'COBADEFFXXX', betrag: 950.00, verwendungszweck: 'Miete Musterstraße 1, 10115 Berlin', turnus: 'monatlich', naechsteAusfuehrung: new Date('2026-07-01') },
        { girokontoId: giroId, empfaengerName: 'Netflix International B.V.', iban: 'DE21200400600003157801', bic: 'COBADEFFXXX', betrag: 17.99, verwendungszweck: 'Netflix Monatsabo', turnus: 'monatlich', naechsteAusfuehrung: new Date('2026-07-10') },
      ],
    });

    await prisma.beneficiary.create({
      data: {
        name: 'Klaus Mustermann',
        kontonummer: '87654321',
        iban: 'DE57120300000087654321',
        bic: 'SSKMDEMMXXX',
        girokontoId: giroId,
      },
    });

    return respond(201, { message: 'Datenbank erfolgreich befüllt', userId: user.id });
  } catch (e) {
    return respond(500, { error: e.message });
  }
};
