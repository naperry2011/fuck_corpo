import http.server
import os
import socketserver
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2] / 'app' / 'build' / 'web'
PORT = 8787

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def send_head(self):
        path = self.translate_path(self.path)
        if not os.path.exists(path) and '.' not in self.path.rsplit('/', 1)[-1]:
            self.path = '/index.html'
        return super().send_head()

    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()

with socketserver.TCPServer(('127.0.0.1', PORT), Handler) as httpd:
    print(f'Serving {ROOT} on http://127.0.0.1:{PORT}', flush=True)
    httpd.serve_forever()
