from pymavlink import mavutil

connection_string = "udp:127.0.0.1:14441"

# Connect to the drone
master = mavutil.mavlink_connection(connection_string)
master.wait_heartbeat()
print("✅ Drone connected!")


while True:
    master.wait_heartbeat()
    msg = master.recv_match(type='STATUSTEXT', blocking=True)
    if msg:
        message = msg.text
        print(f"Message: {message}")
