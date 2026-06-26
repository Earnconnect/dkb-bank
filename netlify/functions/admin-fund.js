const prisma = require('./_db');
const { respond, respondOptions, verifyAdminToken } = require('./_helpers');

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return respondOptions();
  if (event.httpMethod !== 'POST') return respond(405, { error: 'Method not allowed' });

  try {
    verifyAdminToken(event);

    const { userId, amount, operation, kontoType } = JSON.parse(event.body || '{}');

    if (!userId || amount == null || !operation || !kontoType) {
      return respond(400, { error: 'userId, amount, operation und kontoType erforderlich' });
    }
    if (!['add', 'remove'].includes(operation)) {
      return respond(400, { error: 'operation muss "add" oder "remove" sein' });
    }
    if (!['girokonto', 'visa'].includes(kontoType)) {
      return respond(400, { error: 'kontoType muss "girokonto" oder "visa" sein' });
    }

    const delta = operation === 'add' ? Math.abs(amount) : -Math.abs(amount);

    if (kontoType === 'girokonto') {
      const girokonto = await prisma.girokonto.findFirst({ where: { userId } });
      if (!girokonto) return respond(404, { error: 'Girokonto nicht gefunden' });

      const newSaldo = girokonto.saldo + delta;
      const updated = await prisma.girokonto.update({
        where: { id: girokonto.id },
        data: {
          saldo: newSaldo,
          verfuegbar: newSaldo + girokonto.ueberziehungsrahmen,
        },
      });
      return respond(200, { saldo: updated.saldo, verfuegbar: updated.verfuegbar, kontoType: 'girokonto' });
    } else {
      const visa = await prisma.visaKarte.findFirst({ where: { userId } });
      if (!visa) return respond(404, { error: 'Visa-Karte nicht gefunden' });

      // aktuellerSaldo = outstanding balance owed on the card
      // "add funds" = reduce what's owed (credit); "remove funds" = increase what's owed (debit)
      const newSaldo = Math.max(0, visa.aktuellerSaldo - delta);
      const updated = await prisma.visaKarte.update({
        where: { id: visa.id },
        data: { aktuellerSaldo: newSaldo },
      });
      return respond(200, { aktuellerSaldo: updated.aktuellerSaldo, kreditlimit: visa.kreditlimit, kontoType: 'visa' });
    }
  } catch (e) {
    if (e.message === 'No token' || e.message === 'Not admin' || e.name === 'JsonWebTokenError') {
      return respond(401, { error: 'Nicht autorisiert' });
    }
    return respond(500, { error: e.message });
  }
};
