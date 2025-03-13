import firebase_admin
from firebase_admin import credentials

cred = credentials.Certificate("dronetrack-211a2-firebase-adminsdk-fbsvc-30233321f2.json")
firebase_admin.initialize_app(cred)
