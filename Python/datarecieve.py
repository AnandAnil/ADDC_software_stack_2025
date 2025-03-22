import firebase_admin
from firebase_admin import credentials,firestore
from datetime import datetime, timezone
from pymavlink import mavutil
cred = credentials.Certificate("dronetrack-211a2-firebase-adminsdk-fbsvc-30233321f2.json")
firebase_admin.initialize_app(cred)
db = firestore.client()
connection_string = "udp:127.0.0.1:14441"  

# Connect to the drone
master = mavutil.mavlink_connection(connection_string)
master.wait_heartbeat()
print("✅ Drone connected!")

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

# Fetch and print telemetry data
while True:
    msg = master.recv_match(type='GLOBAL_POSITION_INT', blocking=True)
    if msg:
        lat = msg.lat / 1e7
        lon = msg.lon / 1e7
        add_note_to_firestore("Telemetry Locations", lat, lon)
        print(f"Latitude: {lat}, Longitude: {lon}")
print(master.messages.keys())
