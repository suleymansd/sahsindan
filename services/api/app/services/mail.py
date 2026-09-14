"""Use an explicitly configured SMTP account; no paid mail API or automatic retry."""
from email.message import EmailMessage
import smtplib
import ssl
from urllib.parse import urlencode

from app.core.config import settings


def send_password_reset(email: str, token: str):
    if not settings.smtp_host or not settings.smtp_sender:
        raise RuntimeError("Password reset delivery not configured")
    message = EmailMessage()
    message["From"] = settings.smtp_sender
    message["To"] = email
    message["Subject"] = "Şahsından — şifre sıfırlama"
    url = settings.public_web_url.rstrip("/") + "/sifre-sifirla?" + urlencode({"token": token})
    message.set_content(f"Şifrenizi 30 dakika içinde bu bağlantıdan sıfırlayabilirsiniz:\n{url}\n\nBu isteği siz yapmadıysanız mesajı yok sayabilirsiniz.")
    with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=5) as smtp:
        if settings.smtp_starttls:
            smtp.starttls(context=ssl.create_default_context())
        if settings.smtp_username:
            smtp.login(settings.smtp_username, settings.smtp_password)
        smtp.send_message(message)
