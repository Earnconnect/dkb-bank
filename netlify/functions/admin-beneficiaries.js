const prisma = require('./_db');
const { respond, respondOptions, verifyAdminToken } = require('./_helpers');

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return respondOptions();

  try {
    verifyAdminToken(event);

    const beneficiaries = await prisma.beneficiary.findMany({
      include: {
        girokonto: {
          include: { user: { select: { name: true, kontonummer: true } } },
        },
      },
      orderBy: { verknuepftAm: 'desc' },
    });

    return respond(200, {
      beneficiaries: beneficiaries.map((b) => ({
        id: b.id,
        name: b.name,
        kontonummer: b.kontonummer,
        iban: b.iban,
        bic: b.bic,
        verknuepftAm: b.verknuepftAm,
        ownerName: b.girokonto?.user?.name ?? '–',
        ownerKontonummer: b.girokonto?.user?.kontonummer ?? '–',
      })),
    });
  } catch (e) {
    if (e.message === 'No token' || e.message === 'Not admin' || e.name === 'JsonWebTokenError') {
      return respond(401, { error: 'Nicht autorisiert' });
    }
    return respond(500, { error: e.message });
  }
};
