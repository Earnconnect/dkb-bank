const prisma = require('./_db');
const bcrypt = require('bcryptjs');
const { respond, respondOptions, verifyToken } = require('./_helpers');

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return respondOptions();
  if (event.httpMethod !== 'POST') return respond(405, { error: 'Method not allowed' });

  // Caller must be authenticated
  const auth = verifyToken(event);
  if (!auth) return respond(401, { error: 'Nicht autorisiert' });

  try {
    const { kontonummer, pin } = JSON.parse(event.body || '{}');

    if (!kontonummer || !pin) {
      return respond(400, { error: 'Kontonummer und PIN sind erforderlich' });
    }

    // Cannot link yourself
    const self = await prisma.user.findUnique({ where: { id: auth.userId } });
    if (self?.kontonummer === kontonummer) {
      return respond(400, { error: 'Sie können sich nicht selbst als Begünstigten verknüpfen' });
    }

    const user = await prisma.user.findUnique({
      where: { kontonummer },
      include: { girokonto: true },
    });

    if (!user || !user.girokonto) {
      return respond(401, { error: 'DKB-Konto nicht gefunden' });
    }

    const pinOk = await bcrypt.compare(String(pin), user.pinHash);
    if (!pinOk) {
      return respond(401, { error: 'PIN ist nicht korrekt' });
    }

    return respond(200, {
      name: user.name,
      kontonummer: user.kontonummer,
      iban: user.girokonto.iban,
      bic: user.girokonto.bic,
    });
  } catch (e) {
    return respond(500, { error: e.message });
  }
};
