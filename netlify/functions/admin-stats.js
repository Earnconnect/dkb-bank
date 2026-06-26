const prisma = require('./_db');
const { respond, respondOptions, verifyAdminToken } = require('./_helpers');

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return respondOptions();

  try {
    verifyAdminToken(event);

    const [totalUsers, suspendedCount, giroAgg, visaAgg, totalTx, recent] = await Promise.all([
      prisma.user.count(),
      prisma.user.count({ where: { gesperrt: true } }),
      prisma.girokonto.aggregate({ _sum: { saldo: true } }),
      prisma.visaKarte.aggregate({ _sum: { aktuellerSaldo: true } }),
      prisma.umsatz.count(),
      prisma.umsatz.findMany({
        take: 8,
        orderBy: { buchungsdatum: 'desc' },
        include: {
          girokonto: { include: { user: { select: { name: true, kontonummer: true } } } },
          visaKarte: { include: { user: { select: { name: true, kontonummer: true } } } },
        },
      }),
    ]);

    return respond(200, {
      stats: {
        totalUsers,
        activeCount: totalUsers - suspendedCount,
        suspendedCount,
        totalGiroBalance: giroAgg._sum.saldo ?? 0,
        totalVisaBalance: visaAgg._sum.aktuellerSaldo ?? 0,
        totalTransactions: totalTx,
      },
      recentTransactions: recent.map((u) => ({
        id: u.id,
        buchungsdatum: u.buchungsdatum,
        empfaenger: u.empfaenger,
        betrag: u.betrag,
        typ: u.typ,
        kontoTyp: u.girokontoId ? 'girokonto' : 'visa',
        userName: u.girokonto?.user?.name ?? u.visaKarte?.user?.name ?? '–',
        userKontonummer: u.girokonto?.user?.kontonummer ?? u.visaKarte?.user?.kontonummer ?? '–',
      })),
    });
  } catch (e) {
    if (e.message === 'No token' || e.message === 'Not admin' || e.name === 'JsonWebTokenError') {
      return respond(401, { error: 'Nicht autorisiert' });
    }
    return respond(500, { error: e.message });
  }
};
