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

    return respond(200, {
      user: {
        id: user.id,
        name: user.name,
        kontonummer: user.kontonummer,
        email: user.email,
        adresse: user.adresse,
        kundeSeit: user.kundeSeit,
      },
      girokonto: user.girokonto,
      visaKarte: user.visaKarte,
    });
  } catch (e) {
    if (e.message === 'No token' || e.name === 'JsonWebTokenError') {
      return respond(401, { error: 'Nicht autorisiert' });
    }
    return respond(500, { error: e.message });
  }
};
