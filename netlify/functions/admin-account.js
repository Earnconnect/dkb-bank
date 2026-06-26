const bcrypt = require('bcryptjs');
const prisma = require('./_db');
const { respond, respondOptions, verifyAdminToken } = require('./_helpers');

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return respondOptions();
  if (event.httpMethod !== 'POST') return respond(405, { error: 'Method not allowed' });

  try {
    verifyAdminToken(event);

    const { userId, action, newPin } = JSON.parse(event.body || '{}');
    if (!userId || !action) return respond(400, { error: 'userId und action erforderlich' });

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return respond(404, { error: 'Benutzer nicht gefunden' });

    if (action === 'suspend') {
      await prisma.user.update({ where: { id: userId }, data: { gesperrt: true } });
      return respond(200, { message: `Konto von ${user.name} gesperrt` });
    }

    if (action === 'activate') {
      await prisma.user.update({ where: { id: userId }, data: { gesperrt: false } });
      return respond(200, { message: `Konto von ${user.name} aktiviert` });
    }

    if (action === 'reset-pin') {
      if (!newPin || !/^\d{4}$/.test(newPin)) {
        return respond(400, { error: 'Gültige 4-stellige PIN eingeben' });
      }
      const pinHash = await bcrypt.hash(newPin, 10);
      await prisma.user.update({ where: { id: userId }, data: { pinHash } });
      return respond(200, { message: `PIN von ${user.name} auf ${newPin} zurückgesetzt` });
    }

    return respond(400, { error: 'Ungültige Aktion. Erlaubt: suspend, activate, reset-pin' });
  } catch (e) {
    if (e.message === 'No token' || e.message === 'Not admin' || e.name === 'JsonWebTokenError') {
      return respond(401, { error: 'Nicht autorisiert' });
    }
    return respond(500, { error: e.message });
  }
};
