import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/reset_password_screen.dart';
import 'screens/login_screen.dart';

const supabaseUrl = String.fromEnvironment("SUPABASE_URL");
const supabaseAnonKey = String.fromEnvironment("SUPABASE_ANON_KEY");

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool recoveryMode = false;
  @override
  void initState() {
    super.initState();

    handleRecovery();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() {});
    });
  }

  Future<void> handleRecovery() async {
    final uri = Uri.base;

    if (uri.queryParameters.containsKey("code")) {
      setState(() {
        recoveryMode = true;
      });

      await Supabase.instance.client.auth.exchangeCodeForSession(
        uri.toString(),
      );

      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    final uri = Uri.base;
    final hasCode = uri.queryParameters.containsKey("code");

    if (recoveryMode || hasCode) {
      return ResetPasswordScreen(
        onDone: () async {
          recoveryMode = false;
          await Supabase.instance.client.auth.signOut();
          if (mounted) setState(() {});
        },
      );
    }

    if (session != null) {
      return const CampusScreen();
    }

    return LoginScreen(
      onSuccess: () {
        setState(() {});
      },
    );
  }
}

class CampusScreen extends StatelessWidget {
  const CampusScreen({super.key});

  final List<Map<String, dynamic>> rooms = const [
    {
      "name": "Lab 1",
      "type": "IoT Laboratuvarı",
      "icon": Icons.science,
      "active": true,
      "status": "Canlı veri",
      "color": Color(0xFF38BDF8),
    },
    {
      "name": "Lab 2",
      "type": "Bilgisayar Laboratuvarı",
      "icon": Icons.computer,
      "active": false,
      "status": "Veri yok",
      "color": Color(0xFF64748B),
    },
    {
      "name": "Derslik 101",
      "type": "Normal Sınıf",
      "icon": Icons.school,
      "active": false,
      "status": "Pasif",
      "color": Color(0xFF64748B),
    },
    {
      "name": "Derslik 102",
      "type": "Normal Sınıf",
      "icon": Icons.menu_book,
      "active": false,
      "status": "Pasif",
      "color": Color(0xFF64748B),
    },
    {
      "name": "Koridor",
      "type": "Ortak Alan",
      "icon": Icons.meeting_room,
      "active": false,
      "status": "Pasif",
      "color": Color(0xFF64748B),
    },
    {
      "name": "Tuvalet",
      "type": "Hijyen Alanı",
      "icon": Icons.wc,
      "active": false,
      "status": "Pasif",
      "color": Color(0xFF64748B),
    },
    {
      "name": "Teknik Oda",
      "type": "Enerji / Sistem",
      "icon": Icons.electrical_services,
      "active": false,
      "status": "Pasif",
      "color": Color(0xFF64748B),
    },
    {
      "name": "Depo",
      "type": "Stok Alanı",
      "icon": Icons.inventory_2,
      "active": false,
      "status": "Pasif",
      "color": Color(0xFF64748B),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "TwinSense",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              user?.email ?? "",
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthGate()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF020617), Color(0xFF0F172A), Color(0xFF111827)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heroPanel(),
                  const SizedBox(height: 24),
                  const Text(
                    "1. Kat Alanları",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Bu demo kampüsün 1. katını simüle eder. Gerçek sensör verisi Lab 1 alanına bağlıdır.",
                    style: TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rooms.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 240,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.15,
                        ),
                    itemBuilder: (context, index) {
                      final room = rooms[index];

                      return _roomCard(context, room);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF2563EB), Color(0xFF1E1B4B)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.apartment, color: Colors.white, size: 42),
          SizedBox(height: 16),
          Text(
            "ISUBÜ Kampüs Dijital İkizi",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "1. kat için sınıf, laboratuvar ve ortak alan izleme simülasyonu",
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _roomCard(BuildContext context, Map<String, dynamic> room) {
    final bool active = room["active"] == true;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        if (active) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SensorDetailScreen(roomName: "Lab 1"),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${room["name"]} için henüz sensör verisi yok."),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? const Color(0xFF38BDF8)
                : Colors.white.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: room["color"].withOpacity(0.18),
              child: Icon(room["icon"], color: room["color"]),
            ),
            const Spacer(),
            Text(
              room["name"],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              room["type"],
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? Colors.green.withOpacity(0.15)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                room["status"],
                style: TextStyle(
                  color: active ? Colors.greenAccent : Colors.white54,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SensorDetailScreen extends StatefulWidget {
  final String roomName;

  const SensorDetailScreen({super.key, required this.roomName});

  @override
  State<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {
  Map data = {};
  int selectedMenu = 0;

  List<double> gasHistory = [];
  List<double> tempHistory = [];
  List<double> currentHistory = [];

  final menuItems = const [
    {"title": "Genel İzleme", "icon": Icons.dashboard},
    {"title": "Yeşil Enerji", "icon": Icons.energy_savings_leaf},
    {"title": "Sistem Olayları", "icon": Icons.history},
    {"title": "Kontrol Paneli", "icon": Icons.tune},
  ];

  Future<void> fetchData() async {
    try {
      final res = await http.get(
        Uri.parse("https://twinsense-backend.onrender.com/api/live"),
      );

      if (res.statusCode == 200) {
        setState(() {
          data = jsonDecode(res.body);

          gasHistory.add((data["gas"] ?? 0).toDouble());
          tempHistory.add((data["temperature"] ?? 0).toDouble());
          currentHistory.add((data["current"] ?? 0).toDouble());

          if (gasHistory.length > 18) {
            gasHistory.removeAt(0);
            tempHistory.removeAt(0);
            currentHistory.removeAt(0);
          }
        });
      }
    } catch (e) {
      debugPrint("Hata: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return false;
      await fetchData();
      return true;
    });
  }

  double powerWatt() {
    final current = (data["current"] ?? 0).toDouble();
    return 220.0 * current;
  }

  Color statusColor() {
    final gas = data["gas"] ?? 0;
    final flame = data["flame_detected"] == true;

    if (flame || gas > 2500) return Colors.redAccent;
    if (gas > 1800) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  String statusText() {
    final gas = data["gas"] ?? 0;
    final flame = data["flame_detected"] == true;

    if (flame || gas > 2500) return "Tehlike";
    if (gas > 1800) return "Uyarı";
    return "Normal";
  }

  String energySuggestion() {
    final power = powerWatt();
    final light = data["light_detected"] == true;
    final temp = data["temperature"] ?? 0;

    if (light && power > 50)
      return "Işık açık. Tasarruf için kapatma önerilir.";
    if (temp > 30) return "Sıcaklık yüksek. Havalandırma önerilir.";
    if (power > 150) return "Tüketim yüksek. Cihazlar kontrol edilmeli.";
    return "Enerji kullanımı verimli seviyede.";
  }

  Future<void> toggleLight(bool turnOn) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Backend kontrol servisi sonra eklenecek.")),
    );
  }

  Widget menuButton(int index) {
    final selected = selectedMenu == index;
    final item = menuItems[index];

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => selectedMenu = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF38BDF8) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              item["icon"] as IconData,
              color: selected ? Colors.black : Colors.white70,
            ),
            const SizedBox(width: 10),
            Text(
              item["title"] as String,
              style: TextStyle(
                color: selected ? Colors.black : Colors.white70,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget metric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget chartPanel() {
    return Container(
      height: 340,
      padding: const EdgeInsets.all(18),
      decoration: panelStyle(),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                gasHistory.length,
                (i) => FlSpot(i.toDouble(), gasHistory[i] / 40),
              ),
              isCurved: true,
              color: Colors.redAccent,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: List.generate(
                tempHistory.length,
                (i) => FlSpot(i.toDouble(), tempHistory[i]),
              ),
              isCurved: true,
              color: Colors.orangeAccent,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: List.generate(
                currentHistory.length,
                (i) => FlSpot(i.toDouble(), currentHistory[i] * 20),
              ),
              isCurved: true,
              color: Colors.yellowAccent,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration panelStyle() {
    return BoxDecoration(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    );
  }

  Widget generalPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        statusHeader(),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width < 900 ? 1 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 3.6,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            metric(
              "Sıcaklık",
              "${data["temperature"] ?? 0} °C",
              Icons.thermostat,
              Colors.orangeAccent,
            ),
            metric(
              "Nem",
              "${data["humidity"] ?? 0} %",
              Icons.water_drop,
              Colors.lightBlueAccent,
            ),
            metric(
              "Gaz",
              "${data["gas"] ?? 0}",
              Icons.warning_amber,
              Colors.greenAccent,
            ),
            metric(
              "Akım",
              "${data["current"] ?? 0} A",
              Icons.electric_bolt,
              Colors.yellowAccent,
            ),
            metric(
              "Işık",
              data["light_detected"] == true ? "Açık" : "Kapalı",
              Icons.lightbulb,
              Colors.amberAccent,
            ),
            metric(
              "Alev",
              data["flame_detected"] == true ? "Var" : "Yok",
              Icons.local_fire_department,
              Colors.redAccent,
            ),
          ],
        ),
        const SizedBox(height: 18),
        chartPanel(),
      ],
    );
  }

  Widget statusHeader() {
    final color = statusColor();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: panelStyle(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(Icons.sensors, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Genel Durum",
                  style: TextStyle(color: Colors.white54),
                ),
                Text(
                  statusText(),
                  style: TextStyle(
                    color: color,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            "CANLI",
            style: TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget energyPage() {
    final power = powerWatt();
    final estimatedKwh = (power * 8 / 1000).toStringAsFixed(2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Yeşil Enerji Paneli",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 18),

        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width < 900 ? 1 : 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.8,
          children: [
            metric(
              "Anlık Güç",
              "${power.toStringAsFixed(1)} W",
              Icons.bolt,
              Colors.greenAccent,
            ),
            metric(
              "Tahmini Günlük",
              "$estimatedKwh kWh",
              Icons.energy_savings_leaf,
              Colors.orangeAccent,
            ),
            metric(
              "Enerji Durumu",
              power > 150 ? "Yüksek" : "Verimli",
              Icons.eco,
              power > 150 ? Colors.orangeAccent : Colors.greenAccent,
            ),
          ],
        ),

        const SizedBox(height: 18),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: panelStyle(),
          child: Text(
            "💡 ${energySuggestion()}",
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),

        const SizedBox(height: 18),
        chartPanel(),
      ],
    );
  }

  Widget logsPage() {
    Widget logItem(String text, IconData icon, Color color) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Sistem Olayları",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 18),
        logItem(
          "Sensör verileri canlı olarak güncelleniyor",
          Icons.sensors,
          Colors.lightBlueAccent,
        ),
        logItem(
          "Enerji tüketimi takip ediliyor",
          Icons.bolt,
          Colors.orangeAccent,
        ),
        logItem(
          "Sistem normal çalışıyor",
          Icons.check_circle,
          Colors.greenAccent,
        ),
        logItem(
          "Backend kontrol servisi bekleniyor",
          Icons.cloud_sync,
          Colors.purpleAccent,
        ),
      ],
    );
  }

  Widget controlPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Kontrol Paneli",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(22),
          decoration: panelStyle(),
          child: Column(
            children: [
              metric(
                "Cihaz Bağlantısı",
                "Backend bekleniyor",
                Icons.cloud,
                Colors.blueAccent,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => toggleLight(true),
                      icon: const Icon(Icons.lightbulb),
                      label: const Text("Işığı Aç"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => toggleLight(false),
                      icon: const Icon(Icons.lightbulb_outline),
                      label: const Text("Işığı Kapat"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: panelStyle(),
          child: const Text(
            "Not: Işık kontrol backend bağlantısı Alperen tarafından eklendiğinde bu butonlar gerçek cihazı kontrol edecek.",
            style: TextStyle(color: Colors.white60),
          ),
        ),
      ],
    );
  }

  Widget selectedPage() {
    if (selectedMenu == 1) return energyPage();
    if (selectedMenu == 2) return logsPage();
    if (selectedMenu == 3) return controlPage();
    return generalPage();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 850;

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${widget.roomName} Paneli",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF020617), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: isMobile
              ? Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(menuItems.length, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: menuButton(i),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(child: selectedPage()),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 260,
                      padding: const EdgeInsets.all(18),
                      decoration: panelStyle(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "TwinSense",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Dijital İkiz Yönetimi",
                            style: TextStyle(color: Colors.white54),
                          ),
                          const SizedBox(height: 28),
                          ...List.generate(menuItems.length, menuButton),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: SingleChildScrollView(child: selectedPage()),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
