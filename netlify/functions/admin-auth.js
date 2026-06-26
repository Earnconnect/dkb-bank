const { respond, respondOptions, signAdminToken, ADMIN_PASSWORD } = require('./_helpers');

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return respondOptions();
  if (event.httpMethod !== 'POST') return respond(405, { error: 'Method not allowed' });

  try {
    const { password } = JSON.parse(event.body || '{}');
    if (!password || password !== ADMIN_PASSWORD) {
      return respond(401, { error: 'Falsches Admin-Passwort' });
    }
    const token = signAdminToken();
    return respond(200, { token });
  } catch (e) {
    return respond(500, { error: e.message });
  }
};
