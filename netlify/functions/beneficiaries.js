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
      const beneficiaries = await prisma.beneficiary.findMany({
        where: { girokontoId: user.girokonto.id },
        orderBy: { verknuepftAm: 'desc' },
      });
      return respond(200, { beneficiaries });
    }

    if (event.httpMethod === 'POST') {
      const { name, kontonummer, iban, bic } = JSON.parse(event.body || '{}');
      const existing = await prisma.beneficiary.findFirst({
        where: { girokontoId: user.girokonto.id, iban },
      });
      if (existing) return respond(409, { error: 'Begünstigter bereits vorhanden' });

      const beneficiary = await prisma.beneficiary.create({
        data: { name, kontonummer, iban, bic, girokontoId: user.girokonto.id },
      });
      return respond(201, { beneficiary });
    }

    if (event.httpMethod === 'DELETE') {
      const { id } = event.queryStringParameters || {};
      if (!id) return respond(400, { error: 'ID erforderlich' });
      await prisma.beneficiary.deleteMany({
        where: { id, girokontoId: user.girokonto.id },
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
