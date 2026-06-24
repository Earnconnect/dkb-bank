const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'dkb-demo-secret-change-in-prod';

const corsHeaders = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
};

function respond(statusCode, body) {
  return { statusCode, headers: corsHeaders, body: JSON.stringify(body) };
}

function respondOptions() {
  return { statusCode: 200, headers: corsHeaders, body: '' };
}

function signToken(userId) {
  return jwt.sign({ userId }, JWT_SECRET, { expiresIn: '30d' });
}

function verifyToken(event) {
  const auth = event.headers.authorization || event.headers.Authorization || '';
  if (!auth.startsWith('Bearer ')) throw new Error('No token');
  return jwt.verify(auth.slice(7), JWT_SECRET);
}

module.exports = { respond, respondOptions, signToken, verifyToken };
