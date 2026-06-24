const prisma = require('./_db');
const { respond, respondOptions, verifyToken } = require('./_helpers');

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return respondOptions();

  try {
    const { userId } = verifyToken(event);

    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { girokonto: true },
    });

    if (!user?.girokonto) return respond(404, { error: 'Konto nicht gefunden' });

    if (event.httpMethod === 'GET') {
      const dauerauftraege = await prisma.dauerauftrag.findMany({
        where: { girokontoId: user.girokonto.id },
        orderBy: { createdAt: 'desc' },
      });
      return respond(200, { dauerauftraege });
    }

    if (event.httpMethod === 'POST') {
      const { empfaengerName, iban, bic, betrag, verwendungszweck, turnus, naechsteAusfuehrung } =
        JSON.parse(event.body || '{}');
      const da = await prisma.dauerauftrag.create({
        data: {
          empfaengerName,
          iban,
          bic,
          betrag: parseFloat(betrag),
          verwendungszweck,
          turnus,
          naechsteAusfuehrung: new Date(naechsteAusfuehrung),
          girokontoId: user.girokonto.id,
        },
      });
      return respond(201, { dauerauftrag: da });
    }

    if (event.httpMethod === 'DELETE') {
      const { id } = event.queryStringParameters || {};
      if (!id) return respond(400, { error: 'ID erforderlich' });
      await prisma.dauerauftrag.deleteMany({
        where: { id, girokontoId: user.girokonto.id },
      });
      return respond(200, { success: true });
    }

    if (event.httpMethod === 'PUT') {
      const { id } = event.queryStringParameters || {};
      if (!id) return respond(400, { error: 'ID erforderlich' });
      const { isAktiv } = JSON.parse(event.body || '{}');
      await prisma.dauerauftrag.updateMany({
        where: { id, girokontoId: user.girokonto.id },
        data: { isAktiv },
      });
      return respond(200, { success: true });
    }

    return respond(405, { error: 'Method not allowed' });
  } catch (e) {
    if (e.message === 'No token' || e.name === 'JsonWebTokenError') {
      return respond(401, { error: 'Nicht autorisiert' });
    }
    return respond(500, { error: e.message });
  }
};
