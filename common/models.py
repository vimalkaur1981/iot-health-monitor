# common/models.py
from pydantic import BaseModel
from datetime import datetime

class DeviceHeartbeat(BaseModel):
    device_id: str
    vendor: str
    timestamp: datetime
    status: str
    metrics: dict
