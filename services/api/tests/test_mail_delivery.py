from email import message_from_bytes
import socketserver
import threading

from app.core.config import settings
from app.services.mail import send_password_reset


def test_real_local_smtp_delivery_and_reset_link(monkeypatch):
    messages = []

    class Handler(socketserver.StreamRequestHandler):
        def handle(self):
            self.wfile.write(b"220 local-test SMTP\r\n")
            while line := self.rfile.readline():
                command = line.split(b" ", 1)[0].strip().upper()
                if command in (b"EHLO", b"HELO", b"MAIL", b"RCPT", b"RSET"):
                    self.wfile.write(b"250 OK\r\n")
                elif command == b"DATA":
                    self.wfile.write(b"354 Send message\r\n")
                    content = []
                    while (line := self.rfile.readline()) and line != b".\r\n":
                        content.append(line)
                    messages.append(b"".join(content))
                    self.wfile.write(b"250 Stored locally\r\n")
                elif command == b"QUIT":
                    self.wfile.write(b"221 Bye\r\n")
                    return
                else:
                    self.wfile.write(b"500 Unsupported\r\n")

    with socketserver.TCPServer(("127.0.0.1", 0), Handler) as server:
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        monkeypatch.setattr(settings, "smtp_host", "127.0.0.1")
        monkeypatch.setattr(settings, "smtp_port", server.server_address[1])
        monkeypatch.setattr(settings, "smtp_sender", "sender@example.test")
        monkeypatch.setattr(settings, "smtp_username", "")
        monkeypatch.setattr(settings, "smtp_starttls", False)
        monkeypatch.setattr(settings, "public_web_url", "https://market.example.test")
        try:
            send_password_reset("recipient@example.test", "safe.test-token")
        finally:
            server.shutdown()
            thread.join(timeout=5)
    assert len(messages) == 1
    message = message_from_bytes(messages[0])
    assert message["To"] == "recipient@example.test"
    assert "https://market.example.test/sifre-sifirla?token=safe.test-token" in message.get_payload(decode=True).decode()
