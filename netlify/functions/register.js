const prisma = require('./_db');
const bcrypt = require('bcryptjs');
const { respond, respondOptions, signToken } = require('./_helpers');

function generateIban(kontonummer) {
  const padded = kontonummer.padStart(10, '0');
  const bban = `12030000${padded}`;
  const numeric = (bban + 'DE00').replace(/[A-Z]/g, c => String(c.charCodeAt(0) - 55));
  let r = 0;
  for (const ch of numeric) r = (r * 10 + parseInt(ch)) % 97;
  return `DE${String(98 - r).padStart(2, '0')}${bban}`;
}

function generateCardNumber() {
  const digits = Array.from({ length: 15 }, () => Math.floor(Math.random() * 10)).join('');
  return `4${digits}`;
}

async function generateKontonummer() {
  let kto;
  let exists = true;
  while (exists) {
    kto = String(Math.floor(10000000 + Math.random() * 90000000));
    const user = await prisma.user.findUnique({ where: { kontonummer: kto } });
    exists = !!user;
  }
  return kto;
}

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return respondOptions();
  if (event.httpMethod !== 'POST') return respond(405, { error: 'Method not allowed' });

  try {
    const { name, email, pin, confirmPin } = JSON.parse(event.body || '{}');

    if (!name?.trim()) return respond(400, { error: 'Name ist erforderlich' });
    if (!pin || pin.length !== 4 || !/^\d{4}$/.test(pin))
      return respond(400, { error: 'PIN muss 4 Ziffern haben' });
    if (pin !== confirmPin)
      return respond(400, { error: 'PINs stimmen nicht überein' });

    const kontonummer = await generateKontonummer();
    const iban = generateIban(kontonummer);
    const pinHash = await bcrypt.hash(pin, 10);

    const now = new Date();
    const ablaufJahr = now.getFullYear() + 4;
    const ablaufMonat = String(now.getMonth() + 1).padStart(2, '0');

    const user = await prisma.user.create({
      data: {
        kontonummer,
        pinHash,
        name: name.trim(),
        email: email?.trim() || null,
        kundeSeit: now,
        girokonto: {
          create: {
            iban,
            bic: 'SSKMDEMMXXX',
            kontonummer: `10${kontonummer}`,
            saldo: 0,
            verfuegbar: 0,
            ueberziehungsrahmen: 200,
          },
        },
        visaKarte: {
          create: {
            kartenNummer: generateCardNumber(),
            ablaufdatum: `${ablaufMonat}/${String(ablaufJahr).slice(-2)}`,
            karteninhaber: name.trim().toUpperCase(),
            kreditlimit: 1000,
            aktuellerSaldo: 0,
            unbezahlt: 0,
            abrechnungsperiodeBeginn: new Date(now.getFullYear(), now.getMonth(), 1),
            abrechnungsperiodeEnde: new Date(now.getFullYear(), now.getMonth() + 1, 0),
          },
        },
      },
      include: { girokonto: true, visaKarte: true },
    });

    const token = signToken(user.id);

    return respond(201, {
      token,
      kontonummer,
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
