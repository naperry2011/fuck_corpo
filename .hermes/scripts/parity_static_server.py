"""Static file server with SPA rewrites, for the React/Flutter parity sweep.

Same behaviour as `spa_server.py` but the directory and port are arguments, so
the sweep can run the React `dist/` and the Flutter `app/build/web/` builds side
by side on two ports at once.

    python .hermes/scripts/parity_static_server.py app/build/web 8787
    python .hermes/scripts/parity_static_server.py dist          8788
"""

import http.server
import os
import socketserver
import sys
from pathlib import Path

ROOT = Path(sys.argv[1]).resolve()
PORT = int(sys.argv[2])


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def send_head(self):
        # Deep links (/dashboard, /settings) have no file on disk. Both apps are
        # client-routed SPAs, so anything extension-less falls through to the
        # shell, mirroring the Vercel rewrite in app/vercel.json.
        path = self.translate_path(self.path)
        if not os.path.exists(path) and '.' not in self.path.rsplit('/', 1)[-1]:
            self.path = '/index.html'
        return super().send_head()

    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()

    def log_message(self, *args):
        pass


socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(('127.0.0.1', PORT), Handler) as httpd:
    print(f'Serving {ROOT} on http://127.0.0.1:{PORT}', flush=True)
    httpd.serve_forever()
