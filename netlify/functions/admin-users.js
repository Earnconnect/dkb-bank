const prisma = require('./_db');
const { respond, respondOptions, verifyAdminToken } = require('./_helpers');

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return respondOptions();

  try {
    verifyAdminToken(event);

    const users = await prisma.user.findMany({
      include: {
        girokonto: {
          select: { id: true, iban: true, bic: true, saldo: true, verfuegbar: true, ueberziehungsrahmen: true },
        },
        visaKarte: {
          select: { id: true, kartenNummer: true, aktuellerSaldo: true, kreditlimit: true, gesperrt: true, ablaufdatum: true },
        },
      },
      orderBy: { kundeSeit: 'desc' },
    });

    return respond(200, {
      users: users.map((u) => ({
        id: u.id,
        kontonummer: u.kontonummer,
        name: u.name,
        email: u.email,
        adresse: u.adresse,
        kundeSeit: u.kundeSeit,
        gesperrt: u.gesperrt,
        girokonto: u.girokonto,
        visaKarte: u.visaKarte,
      })),
    });
  } catch (e) {
    if (e.message === 'No token' || e.message === 'Not admin' || e.name === 'JsonWebTokenError') {
      return respond(401, { error: 'Nicht autorisiert' });
    }
    return respond(500, { error: e.message });
  }
};
