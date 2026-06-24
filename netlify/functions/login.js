const prisma = require('./_db');
const bcrypt = require('bcryptjs');
const { respond, respondOptions, signToken } = require('./_helpers');

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return respondOptions();
  if (event.httpMethod !== 'POST') return respond(405, { error: 'Method not allowed' });

  try {
    const { kontonummer, pin } = JSON.parse(event.body || '{}');
    if (!kontonummer || !pin) return respond(400, { error: 'Kontonummer und PIN erforderlich' });

    const user = await prisma.user.findUnique({
      where: { kontonummer },
      include: { girokonto: true, visaKarte: true },
    });

    if (!user) return respond(401, { error: 'Ungültige Anmeldedaten' });

    const valid = await bcrypt.compare(pin, user.pinHash);
    if (!valid) return respond(401, { error: 'Ungültige Anmeldedaten' });

    const token = signToken(user.id);

    return respond(200, {
      token,
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
    return respond(500, { error: e.message });
  }
};
