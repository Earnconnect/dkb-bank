const prisma = require('./_db');
const { respond, respondOptions, verifyToken } = require('./_helpers');

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return respondOptions();
  if (event.httpMethod !== 'POST') return respond(405, { error: 'Method not allowed' });

  try {
    const { userId } = verifyToken(event);
    const { empfaenger, iban, bic, betrag, verwendungszweck, buchungsdatum } =
      JSON.parse(event.body || '{}');

    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { girokonto: true },
    });

    if (!user?.girokonto) return respond(404, { error: 'Konto nicht gefunden' });

    const amount = parseFloat(betrag);
    if (isNaN(amount) || amount <= 0) return respond(400, { error: 'Ungültiger Betrag' });

    const limit = user.girokonto.verfuegbar + user.girokonto.ueberziehungsrahmen;
    if (amount > limit) return respond(400, { error: 'Deckung nicht ausreichend' });

    const date = buchungsdatum ? new Date(buchungsdatum) : new Date();
    const ref = `TAN${Date.now() % 100000000}`;

    const [umsatz, girokonto] = await prisma.$transaction([
      prisma.umsatz.create({
        data: {
          buchungsdatum: date,
          wertstellung: date,
          auftraggeber: user.name,
          empfaenger,
          verwendungszweck: verwendungszweck || 'Überweisung',
          betrag: amount,
          typ: 'belastung',
          kategorie: 'ueberweisung',
          referenznummer: ref,
          girokontoId: user.girokonto.id,
        },
      }),
      prisma.girokonto.update({
        where: { id: user.girokonto.id },
        data: {
          saldo: { decrement: amount },
          verfuegbar: { decrement: amount },
        },
      }),
    ]);

    return respond(200, { umsatz, girokonto, referenznummer: ref });
  } catch (e) {
    if (e.message === 'No token' || e.name === 'JsonWebTokenError') {
      return respond(401, { error: 'Nicht autorisiert' });
    }
    return respond(500, { error: e.message });
  }
};
