import fs from 'fs';
import path from 'path';

const BACKEND_URL = process.env.BACKEND_URL || 'https://paperkit-backend.onrender.com';
const PDF_PATH = path.join('o:', 'PaperKit', 'Gmail - Action Required_ Your app is not compliant with Google Play Policies (CivicPulse).pdf');

console.log(`=======================================================`);
console.log(`TESTING REMOTE PAPERKIT BACKEND AI ENDPOINTS`);
console.log(`Target Backend: ${BACKEND_URL}`);
console.log(`Target PDF File: ${PDF_PATH}`);
console.log(`=======================================================\n`);

async function runTests() {
  if (!fs.existsSync(PDF_PATH)) {
    console.error(`ERROR: PDF file not found at ${PDF_PATH}`);
    process.exit(1);
  }

  const fileStats = fs.statSync(PDF_PATH);
  console.log(`PDF loaded successfully (${(fileStats.size / 1024).toFixed(2)} KB).\n`);

  // 1. Authenticate to get JWT token
  console.log(`1. Authenticating test user at ${BACKEND_URL} ...`);
  let token = null;
  const testEmail = `tester_${Date.now()}@paperkit.dev`;
  const testPassword = 'Password123!';

  // Step 1: Register
  try {
    const regRes = await fetch(`${BACKEND_URL}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'AI PDF Tester',
        email: testEmail,
        password: testPassword
      })
    });
    const regData = await regRes.json();
    console.log(`   Registration response status: ${regRes.status}`, regData);
  } catch (err) {
    console.log(`   Registration network error: ${err.message}`);
  }

  // Step 2: Login via form-urlencoded (FastAPI OAuth2PasswordRequestForm standard)
  try {
    const loginParams = new URLSearchParams();
    loginParams.append('username', testEmail);
    loginParams.append('password', testPassword);

    const loginRes = await fetch(`${BACKEND_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: loginParams.toString()
    });
    const loginData = await loginRes.json();
    if (loginRes.ok && loginData.access_token) {
      token = loginData.access_token;
      console.log(`   SUCCESS: Logged in & received Bearer JWT token.`);
    } else {
      console.error(`   Login failed:`, loginData);
    }
  } catch (err) {
    console.error(`   Login request failed: ${err.message}`);
  }

  if (!token) {
    console.error(`\nCRITICAL: Could not obtain access token. Stopping.`);
    process.exit(1);
  }

  const fileBuffer = fs.readFileSync(PDF_PATH);

  // Helper function to test an AI endpoint
  async function testAiEndpoint(endpoint, extraFields = {}, label = '') {
    console.log(`\n--- Testing ${label || endpoint} [POST ${BACKEND_URL}${endpoint}] ---`);
    const formData = new FormData();

    // Attach PDF file as multipart form-data
    const blob = new Blob([fileBuffer], { type: 'application/pdf' });
    formData.append('file', blob, 'policy_warning.pdf');

    for (const [k, v] of Object.entries(extraFields)) {
      formData.append(k, v);
    }

    const startTime = Date.now();
    try {
      const res = await fetch(`${BACKEND_URL}${endpoint}`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`
        },
        body: formData
      });

      const duration = ((Date.now() - startTime) / 1000).toFixed(2);
      const status = res.status;
      const data = await res.json();

      if (res.ok) {
        console.log(`STATUS: ${status} OK (${duration}s)`);
        console.log(`RESPONSE PREVIEW:\n`, JSON.stringify(data, null, 2).slice(0, 450) + '...\n');
        return { success: true, endpoint, data, status, duration };
      } else {
        console.error(`STATUS: ${status} FAILED (${duration}s)`);
        console.error(`ERROR DETAIL:`, data);
        return { success: false, endpoint, data, status, duration };
      }
    } catch (err) {
      console.error(`REQUEST ERROR: ${err.message}`);
      return { success: false, endpoint, error: err.message };
    }
  }

  const results = [];

  // Test 1: Summarize PDF
  results.push(await testAiEndpoint('/ai/summarize', { mode: 'detailed', language: 'English' }, 'AI Summarize PDF'));

  // Test 2: Ask Question about PDF
  results.push(await testAiEndpoint('/ai/ask', { question: 'What is the main policy issue or action required described in this document?' }, 'AI Ask PDF Question'));

  // Test 3: OCR PDF
  results.push(await testAiEndpoint('/ai/ocr', {}, 'AI Vision / Multimodal OCR'));

  // Test 4: Classify Document
  results.push(await testAiEndpoint('/ai/classify', {}, 'AI Document Classification'));

  // Test 5: Quality Check
  results.push(await testAiEndpoint('/ai/quality-check', {}, 'AI Document Quality Check'));

  // Test 6: Analyze Research / Policy Document
  results.push(await testAiEndpoint('/ai/analyze-research', {}, 'AI Document & Policy Analysis'));

  // Test 7: Detect Privacy Concerns
  results.push(await testAiEndpoint('/ai/detect-privacy', {}, 'AI Detect Privacy / PII'));

  console.log(`\n=======================================================`);
  console.log(`TEST SUITE SUMMARY RESULTS`);
  console.log(`=======================================================`);
  let passed = 0;
  for (const r of results) {
    const icon = r.success ? '✅ PASS' : '❌ FAIL';
    console.log(`${icon} | ${r.endpoint} | Status: ${r.status || 'ERR'} | Time: ${r.duration || '?'}s`);
    if (r.success) passed++;
  }
  console.log(`\nTotal: ${passed}/${results.length} AI endpoints passed successfully.`);
}

runTests();
