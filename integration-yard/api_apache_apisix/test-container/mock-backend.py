#!/usr/bin/env python3

from http.server import BaseHTTPRequestHandler, HTTPServer


class MockBackendHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/yard-probe":
            self.send_error(404)
            return

        body = b"APISIX integration-yard mock backend\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, _format, *_args):
        return


HTTPServer(("0.0.0.0", 8081), MockBackendHandler).serve_forever()
