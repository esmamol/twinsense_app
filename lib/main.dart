import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Dashboard(),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Map data = {};

  List<double> gasHistory = [];
  List<double> tempHistory = [];
  List<double> currentHistory = [];

  @override
void initState() {
  super.initState();

   FirebaseMessaging.instance.requestPermission();
  // 🔥 TOKEN AL + BACKEND'E GÖNDER
  FirebaseMessaging.instance.getToken().then((token) async {
    print("🔥 TOKEN: $token");

    if (token != null) {
      try {
        await http.post(
          Uri.parse("https://twinsense-backend.onrender.com/api/token"),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "token": token,
          }),
        );

        print("✅ Token backend'e gönderildi");
      } catch (e) {
        print("❌ Token gönderme hatası: $e");
      }
    }
  });

  // 🔔 foreground bildirim
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 Bildirim geldi: ${message.notification?.title}");
  });

  fetchData();

  Future.doWhile(() async {
    await Future.delayed(Duration(seconds: 3));
    if (!mounted) return false;
    fetchData();
    return true;
  });
}

  Future fetchData() async {
    try {
      final res = await http.get(
        Uri.parse("https://twinsense-backend.onrender.com/api/live"),
      );

      if (res.statusCode == 200) {
        setState(() {
          data = jsonDecode(res.body);

          double gasValue = (data["gas"] ?? 0).toDouble();
          double tempValue = (data["temperature"] ?? 0).toDouble();
          double currentValue = (data["current"] ?? 0).toDouble();

          gasHistory.add(gasValue);
          tempHistory.add(tempValue);
          currentHistory.add(currentValue);

          if (gasHistory.length > 10) {
            gasHistory.removeAt(0);
            tempHistory.removeAt(0);
            currentHistory.removeAt(0);
          }
        });
      }
    } catch (e) {
      print("Hata: $e");
    }
  }

  Widget card(String title, String value, {Color? color}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: Colors.white70)),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget multiChart() {
    return Container(
      height: 260,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            "📊 Gaz - Sıcaklık - Akım Grafiği",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("● Gaz", style: TextStyle(color: Colors.red)),
              SizedBox(width: 16),
              Text("● Sıcaklık", style: TextStyle(color: Colors.orange)),
              SizedBox(width: 16),
              Text("● Akım", style: TextStyle(color: Colors.yellow)),
            ],
          ),
          SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(gasHistory.length, (i) {
                      return FlSpot(i.toDouble(), gasHistory[i] / 40);
                    }),
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: List.generate(tempHistory.length, (i) {
                      return FlSpot(i.toDouble(), tempHistory[i]);
                    }),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: List.generate(currentHistory.length, (i) {
                      return FlSpot(i.toDouble(), currentHistory[i] * 20);
                    }),
                    isCurved: true,
                    color: Colors.yellow,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0f172a),
      appBar: AppBar(
        title: Text("TwinSense"),
        backgroundColor: Color(0xFF0f172a),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: 500,
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    card("🌡️ Sıcaklık", "${data["temperature"] ?? 0} °C"),
                    card("💧 Nem", "${data["humidity"] ?? 0} %"),
                    card(
                      "🔥 Gaz",
                      "${data["gas"] ?? 0}",
                      color: (data["gas"] ?? 0) > 2000 ? Colors.red : null,
                    ),
                    card("⚡ Akım", "${data["current"] ?? 0} A"),
                    card(
                      "💡 Işık",
                      data["light_detected"] == true ? "AÇIK" : "KAPALI",
                    ),
                    card(
                      "🔥 Alev",
                      data["flame_detected"] == true ? "VAR" : "YOK",
                      color: data["flame_detected"] == true
                          ? Colors.red
                          : null,
                    ),
                  ],
                ),
                SizedBox(height: 20),
                multiChart(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}