const prisma = require('./_db');
const { respond, respondOptions, verifyAdminToken } = require('./_helpers');

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return respondOptions();

  try {
    verifyAdminToken(event);

    const limit = Math.min(parseInt(event.queryStringParameters?.limit || '200', 10), 500);
    const userId = event.queryStringParameters?.userId;

    const where = userId
      ? { OR: [{ girokonto: { userId } }, { visaKarte: { userId } }] }
      : {};

    const umsaetze = await prisma.umsatz.findMany({
      where,
      include: {
        girokonto: { include: { user: { select: { name: true, kontonummer: true } } } },
        visaKarte: { include: { user: { select: { name: true, kontonummer: true } } } },
      },
      orderBy: { buchungsdatum: 'desc' },
      take: limit,
    });

    const transactions = umsaetze.map((u) => ({
      id: u.id,
      buchungsdatum: u.buchungsdatum,
      wertstellung: u.wertstellung,
      empfaenger: u.empfaenger,
      auftraggeber: u.auftraggeber,
      verwendungszweck: u.verwendungszweck,
      betrag: u.betrag,
      typ: u.typ,
      kategorie: u.kategorie,
      referenznummer: u.referenznummer,
      kontoTyp: u.girokontoId ? 'girokonto' : 'visa',
      userName: u.girokonto?.user?.name ?? u.visaKarte?.user?.name ?? '–',
      userKontonummer: u.girokonto?.user?.kontonummer ?? u.visaKarte?.user?.kontonummer ?? '–',
    }));

    return respond(200, { transactions });
  } catch (e) {
    if (e.message === 'No token' || e.message === 'Not admin' || e.name === 'JsonWebTokenError') {
      return respond(401, { error: 'Nicht autorisiert' });
    }
    return respond(500, { error: e.message });
  }
};
