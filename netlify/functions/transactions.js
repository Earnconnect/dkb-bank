const prisma = require('./_db');
const { respond, respondOptions, verifyToken } = require('./_helpers');

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return respondOptions();

  try {
    const { userId } = verifyToken(event);

    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { girokonto: true, visaKarte: true },
    });

    if (!user) return respond(404, { error: 'Benutzer nicht gefunden' });

    const type = (event.queryStringParameters || {}).type;

    let umsaetze = [];
    if (type === 'visa' && user.visaKarte) {
      umsaetze = await prisma.umsatz.findMany({
        where: { visaKarteId: user.visaKarte.id },
        orderBy: { buchungsdatum: 'desc' },
      });
    } else if (user.girokonto) {
      umsaetze = await prisma.umsatz.findMany({
        where: { girokontoId: user.girokonto.id },
        orderBy: { buchungsdatum: 'desc' },
      });
    }

    return respond(200, { umsaetze });
  } catch (e) {
    if (e.message === 'No token' || e.name === 'JsonWebTokenError') {
      return respond(401, { error: 'Nicht autorisiert' });
    }
    return respond(500, { error: e.message });
  }
};
