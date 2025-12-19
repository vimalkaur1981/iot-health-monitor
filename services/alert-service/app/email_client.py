import json
import os
import smtplib
import time
from email.message import EmailMessage
from kafka import KafkaConsumer, errors

BOOTSTRAP_SERVERS = os.environ.get("KAFKA_BOOTSTRAP_SERVERS", "kafka:9092")
ALERT_TOPIC = "device-alerts"

GMAIL_USER = os.environ["GMAIL_USER"]
GMAIL_PASSWORD = os.environ["GMAIL_APP_PASSWORD"]
ALERT_RECIPIENT = os.environ.get("ALERT_RECIPIENT", GMAIL_USER)

# --------------------
# Kafka retry loop
# --------------------
while True:
    try:
        consumer = KafkaConsumer(
            ALERT_TOPIC,
            bootstrap_servers=BOOTSTRAP_SERVERS,
            group_id = f"alert-consumer-{int(time.time())}",
            value_deserializer=lambda m: json.loads(m.decode("utf-8")),
            auto_offset_reset="earliest",
            api_version=(2, 8, 0)  # ⭐ IMPORTANT
        )
        print("✅ Alert service connected to Kafka")
        break
    except errors.NoBrokersAvailable:
        print("⏳ Kafka not available, retrying in 3s...")
        time.sleep(3)

# --------------------
# Email sender
# --------------------
def send_email(alert):
    email_msg = EmailMessage()
    email_msg["From"] = GMAIL_USER
    email_msg["To"] = ALERT_RECIPIENT
    email_msg["Subject"] = f"🚨 {alert['alert_type']} - {alert['device_id']}"

    email_msg.set_content(
        f"""
Device ID: {alert['device_id']}
Severity: {alert['severity']}
Time: {alert['timestamp']}

Message:
{alert['message']}
"""
    )

    print("Received email:\n", email_msg.as_string())

    try:
        with smtplib.SMTP("smtp.gmail.com", 587) as server:
            server.starttls()
            server.login(GMAIL_USER, GMAIL_PASSWORD)
            server.send_message(email_msg)
        print("✅ Email sent")
    except Exception as e:
        print("❌ Failed to send email:", e)

print("📨 Alert Service running")

for record in consumer:
    send_email(record.value)
    print(f"📧 Email sent for device {record.value['device_id']}")
