import spidev
import time
import paho.mqtt.client as mqtt
import json
import ssl
from datetime import datetime 

# SPI Initialization
spi = spidev.SpiDev()
spi.open(0, 0)
spi.max_speed_hz = 1350000

# MQTT Configuration
BROKER_ADDRESS = "aoh5ek5dxzu6t-ats.iot.eu-west-3.amazonaws.com"  
TOPIC = "sensor/data"
CLIENT_ID = "raspberry_pi_client"

mqtt_client = mqtt.Client(CLIENT_ID)

# Configure SSL/TLS for AWS IoT
mqtt_client.tls_set(
    ca_certs='/home/pi/Desktop/Pi_IoT/rootCA.pem',
    certfile='/home/pi/Desktop/Pi_IoT/certificate.pem.crt',
    keyfile='/home/pi/Desktop/Pi_IoT/private.pem.key',
    tls_version=ssl.PROTOCOL_TLSv1_2
)

def on_disconnect(client, userdata, rc):
    """Handle unexpected MQTT disconnections."""
    if rc != 0:
        print("Unexpected disconnection. Attempting to reconnect...")
        try:
            client.reconnect()
        except Exception as e:
            print(f"Reconnection error: {e}")

mqtt_client.on_disconnect = on_disconnect

try:
    mqtt_client.connect(BROKER_ADDRESS, 8883)
    print(f"Connected to MQTT broker: {BROKER_ADDRESS}")
except Exception as e:
    print(f"Connection error: {e}")
    time.sleep(5)
    exit()

def read_adc(channel):
    """Read analog values from MCP3002 ADC.
    
    Args:
        channel (int): ADC channel to read (0 or 1).
        
    Returns:
        int: ADC value (0-1023).
    """
    if channel not in [0, 1]:
        raise ValueError("Channel must be 0 or 1")

    # Send the command to the ADC
    cmd = [0b11000000 | (channel << 6), 0]
    response = spi.xfer2(cmd)
    
    # Combine the two bytes into a single value
    result = ((response[0] & 0x0F) << 8) | response[1]
    return result

try:
    while True:
        # Read sensor values
        gas_sensor_value = read_adc(0)  # Gas sensor
        soil_moisture_value = read_adc(1)  # Soil moisture sensor

        # Get the current timestamp
        current_time = datetime.utcnow().isoformat() + "Z"  # UTC format

        # Prepare data in JSON format
        payload = {
            "timestamp": current_time,
            "gasValue": gas_sensor_value,
            "soilMoisture": soil_moisture_value,
        }

        # Publish data via MQTT
        mqtt_client.publish(TOPIC, json.dumps(payload))
        print(f"Published: {payload}")

        # Wait before the next reading
        time.sleep(2)
except KeyboardInterrupt:
    # Clean up on exit
    spi.close()
    mqtt_client.disconnect()
    print("Program stopped.")
