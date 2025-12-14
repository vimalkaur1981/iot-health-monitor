import smtplib
from email.message import EmailMessage

def send_email(to, subject, body):
    msg = EmailMessage()
    msg["From"] = "alerts@iot-monitor.com"
    msg["To"] = to
    msg["Subject"] = subject
    msg.set_content(body)

    with smtplib.SMTP("smtp.server.com", 587) as s:
        s.starttls()
        s.login("user", "password")
        s.send_message(msg)