import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timezone
from pymavlink import mavutil
import time  # Import for rate-limiting

# Firebase setup
cred = credentials.Certificate("dronetrack-211a2-firebase-adminsdk-fbsvc-30233321f2.json")  # Update with your correct JSON file path
firebase_admin.initialize_app(cred)
db = firestore.client()

connection_string = "udp:127.0.0.1:14441"

# Connect to the drone
master = mavutil.mavlink_connection(connection_string)
master.wait_heartbeat()
print("✅ Drone connected!")

# Function to add data to Firestore
def add_note_to_firestore(collection_name, latitude, longitude):
    try:
        timestamp = datetime.now(timezone.utc)
        data = {
            'latitude': latitude,
            'longitude': longitude,
            'timestamp': timestamp
        }
        db.collection(collection_name).add(data)
        print(f"Document added to '{collection_name}' with data: {data}")
    except Exception as e:
        print(f"Error adding document: {e}")

# Fetch and print telemetry data with rate-limiting
RATE_LIMIT_SECONDS = 5  # Limit data collection/upload to once every 5 seconds

while True:
    master.wait_heartbeat()
    msg = master.recv_match(type='GLOBAL_POSITION_INT', blocking=True)
    if msg:
        lat = msg.lat / 1e7
        lon = msg.lon / 1e7
        add_note_to_firestore("Telemetry Locations", lat, lon)
        print(f"Latitude: {lat}, Longitude: {lon}")

        # Introduce rate-limiting
        time.sleep(RATE_LIMIT_SECONDS)
