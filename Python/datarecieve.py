import firebase_admin
from firebase_admin import credentials,firestore
from datetime import datetime, timezone

cred = credentials.Certificate("dronetrack-211a2-firebase-adminsdk-fbsvc-30233321f2.json")
firebase_admin.initialize_app(cred)
db = firestore.client()


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


# Specify your Firestore collection name
collection_name = "Telemetry Locations"

lat=10
lon=76
add_note_to_firestore(collection_name, lat, lon)