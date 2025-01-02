import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final client = MqttServerClient('192.168.1.173', 'flutter_client');
  Map<String, dynamic> sensorData = {
    "soil_moisture": "Loading...",
    "gaz_sensor": "Loading...",
    "temperature": "25°C", // Constant
    "humidity": "60%",    // Constant
  };

  @override
  void initState() {
    super.initState();
    connectMQTT();
  }

  Future<void> connectMQTT() async {
    client.port = 1883; // Default MQTT port
    client.logging(on: true);
    client.keepAlivePeriod = 60;
    client.onDisconnected = onDisconnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;

    try {
      print('Connecting to MQTT broker...');
      await client.connect().timeout(Duration(seconds: 10)); // Ajoutez un délai
      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        print('Connected to MQTT broker!');
        subscribeToTopic('sensor/data');
      } else {
        print('MQTT connection failed with status: ${client.connectionStatus}');
      }
    } catch (e) {
      print('MQTT connection error: $e');
      Future.delayed(Duration(seconds: 5), connectMQTT); // Reconnectez automatiquement
    }
  }

  void subscribeToTopic(String topic) {
    client.subscribe(topic, MqttQos.atLeastOnce);
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final String payload =
      MqttPublishPayload.bytesToStringAsString(message.payload.message);

      print('Raw MQTT message: $payload'); // Log pour vérifier les données brutes

      setState(() {
        try {
          final data = json.decode(payload);
          sensorData["soil_moisture"] = '${data["soilMoisture"]} AWC'; // Soil moisture value
          sensorData["gaz_sensor"] = '${data["gazSensor"]} PPM';       // Air quality (gas sensor)
        } catch (e) {
          print('Error decoding MQTT message: $e');
        }
      });
    });
  }

  void onDisconnected() {
    print('Disconnected from MQTT broker.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: const Text(
            'Firma - Agricultural Monitoring',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: connectMQTT,
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/wallpaper.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Environmental Conditions',
                  style: Theme.of(context).textTheme.headlineLarge!.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 20),
                _buildSensorCard('Soil Moisture', sensorData["soil_moisture"], Colors.brown, Icons.eco),
                _buildSensorCard('Air Quality', sensorData["gaz_sensor"], Colors.green, Icons.air),
                _buildSensorCard('Temperature', sensorData["temperature"], Colors.red, Icons.thermostat),
                _buildSensorCard('Humidity', sensorData["humidity"], Colors.blue, Icons.water_drop),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard(String title, String value, Color color, IconData icon) {
    return Card(
      color: color.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: Text(value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }
}
