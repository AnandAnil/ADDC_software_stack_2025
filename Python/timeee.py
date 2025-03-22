from pymavlink import mavutil
import time  # Import the time module to log timestamps

connection_string = "udp:127.0.0.1:14441"  

# Connect to the drone
master = mavutil.mavlink_connection(connection_string)
master.wait_heartbeat()
print("✅ Drone connected!")

# Fetch and print telemetry data with timestamp
while True:
    msg = master.recv_match(type='GLOBAL_POSITION_INT', blocking=True)
    if msg:
        # Get the current time as a human-readable string
        current_time = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime())
        
        # Extract telemetry data
        lat = msg.lat / 1e7
        lon = msg.lon / 1e7
        
        # Print telemetry data with the timestamp
        print(f"Time: {current_time}, Latitude: {lat}, Longitude: {lon}")

# Print all received message types (for debugging or reference)
print(master.messages.keys())
