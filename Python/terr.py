from pymavlink import mavutil


connection_string = "udp:127.0.0.1:14441"  

# Connect to the drone
master = mavutil.mavlink_connection(connection_string)
master.wait_heartbeat()
print("✅ Drone connected!")

# Fetch and print telemetry data
while True:
    msg = master.recv_match(type='GLOBAL_POSITION_INT', blocking=True)
    if msg:
        lat = msg.lat / 1e7
        lon = msg.lon / 1e7
    
        print(f"Latitude: {lat}, Longitude: {lon}")