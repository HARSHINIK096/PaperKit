import express from 'express';
import { JSDOM } from 'jsdom';
import { BotGuardClient } from 'bgutils-js/botguard';
import { WebPoMinter, createColdStartToken } from 'bgutils-js/webpo';

const PORT = parseInt(process.env.POT_PORT || '4416', 10);
const HOST = process.env.POT_HOST || '127.0.0.1';

const app = express();
app.use(express.json({ limit: '10mb' }));

const dom = new JSDOM('<!DOCTYPE html><html><head></head><body></body></html>', {
  url: 'https://www.youtube.com/',
  referrer: 'https://www.youtube.com/',
});

if (!globalThis.window) {
  globalThis.window = dom.window;
  globalThis.document = dom.window.document;
  if (!globalThis.Node) globalThis.Node = dom.window.Node;
  if (!globalThis.Element) globalThis.Element = dom.window.Element;
}

const minterCache = new Map();

// GET /ping - Health check endpoint expected by bgutil-ytdlp-pot-provider
app.get('/ping', (req, res) => {
  res.json({
    version: '2.0.0',
    status: 'ok',
    service: 'PaperKit POT Provider',
  });
});

// POST /get_pot - Token generation endpoint
app.post('/get_pot', async (req, res) => {
  try {
    const { challenge, content_binding, innertube_context, bypass_cache } = req.body || {};
    const contentBinding = content_binding || '';

    // Check memory cache if not bypassing
    if (!bypass_cache && contentBinding && minterCache.has(contentBinding)) {
      const cached = minterCache.get(contentBinding);
      if (cached.expiresAt > Date.now()) {
        return res.json({ poToken: cached.poToken });
      }
      minterCache.delete(contentBinding);
    }

    let poToken = null;

    if (challenge && challenge.program && challenge.globalName) {
      try {
        const script = dom.window.document.createElement('script');
        script.text = challenge.program;
        dom.window.document.head.appendChild(script);

        const botguard = await BotGuardClient.create({
          globalObject: dom.window,
          globalName: challenge.globalName,
          program: challenge.program,
        });

        const webPoSignalOutput = [];
        const snapshot = await botguard.snapshot({
          contentBinding: contentBinding,
          signedTimestamp: '',
          webPoSignalOutput: webPoSignalOutput,
          skipPrivacyBuffer: false,
        });

        if (webPoSignalOutput.length > 0 && webPoSignalOutput[0]) {
          const minter = await WebPoMinter.create({ integrityToken: snapshot }, webPoSignalOutput);
          poToken = await minter.mintAsWebsafeString(contentBinding);
        } else if (typeof snapshot === 'string') {
          poToken = snapshot;
        }
      } catch (bgErr) {
        console.warn('[POT Server] Direct BotGuard execution note:', bgErr.message);
      }
    }

    // Fallback: Generate cold start token for contentBinding
    if (!poToken && contentBinding) {
      try {
        poToken = createColdStartToken(contentBinding);
      } catch (csErr) {
        console.warn('[POT Server] Cold start token generation note:', csErr.message);
      }
    }

    if (!poToken) {
      return res.status(500).json({
        error: 'Failed to mint PO Token',
      });
    }

    // Cache token for 6 hours
    if (contentBinding) {
      minterCache.set(contentBinding, {
        poToken,
        expiresAt: Date.now() + 6 * 3600 * 1000,
      });
    }

    return res.json({ poToken });
  } catch (error) {
    console.error('[POT Server] /get_pot error:', error);
    return res.status(500).json({
      error: error.message || 'Internal PO Token generation failure',
    });
  }
});

const server = app.listen(PORT, HOST, () => {
  console.log(`[POT Server] Listening on http://${HOST}:${PORT}`);
});

process.on('SIGTERM', () => {
  server.close(() => process.exit(0));
});
