import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// استيراد المكتبات بناءً على المنصة
import 'js_stub.dart' if (dart.library.js) 'dart:js' as js;
import 'package:flutter_libserialport/flutter_libserialport.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام الميزان المتعدد المنصات',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ScaleHomePage(),
    );
  }
}

class ScaleHomePage extends StatefulWidget {
  const ScaleHomePage({super.key});

  @override
  State<ScaleHomePage> createState() => _ScaleHomePageState();
}

class _ScaleHomePageState extends State<ScaleHomePage> {
  String _weight = '0.0';
  bool _isConnected = false;
  Timer? _timer;
  
  // خاص لسطح المكتب
  SerialPort? _desktopPort;
  SerialPortReader? _reader;
  String _desktopBuffer = ""; // مخزن مؤقت لنسخة سطح المكتب

  // --- منطق الويب (Web Logic) ---
  Future<void> _toggleWebConnection() async {
    if (_isConnected) {
      js.context.callMethod('disconnectScale');
      _stopTimer();
      setState(() {
        _isConnected = false;
        _weight = '0.0';
      });
    } else {
      final bool success = await js.context.callMethod('connectScale');
      if (success) {
        setState(() => _isConnected = true);
        _startWebTimer();
      }
    }
  }

  void _startWebTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final currentWeight = js.context.callMethod('getLiveWeight');
      if (mounted) setState(() => _weight = currentWeight.toString());
    });
  }

  // --- منطق سطح المكتب (Desktop Logic) ---
  Future<void> _toggleDesktopConnection() async {
    if (_isConnected) {
      _reader?.close();
      _desktopPort?.close();
      setState(() {
        _isConnected = false;
        _weight = '0.0';
      });
    } else {
      // البحث عن المنافذ المتاحة
      final availablePorts = SerialPort.availablePorts;
      if (availablePorts.isEmpty) {
        _showError("لم يتم العثور على منافذ COM متصلة");
        return;
      }

      // عرض قائمة لاختيار المنفذ (تبسيطاً سنأخذ الأول أو نظهر قائمة)
      final String? selectedPort = await _showPortPicker(availablePorts);
      
      if (selectedPort != null) {
        try {
          _desktopPort = SerialPort(selectedPort);
          if (_desktopPort!.openReadWrite()) {
            // إعدادات RS232
            SerialPortConfig config = _desktopPort!.config;
            config.baudRate = 9600;
            config.bits = 8;
            config.stopBits = 1;
            config.parity = 0;
            _desktopPort!.config = config;

            _reader = SerialPortReader(_desktopPort!);
            _reader!.stream.listen((data) {
              // 1. تحويل البيانات القادمة إلى نص وإضافتها للمخزن
              final String chunk = String.fromCharCodes(data);
              _desktopBuffer += chunk;

              // 2. معالجة البيانات فقط عند اكتمال السطر (بناءً على \r أو \n)
              if (_desktopBuffer.contains('\r') || _desktopBuffer.contains('\n')) {
                List<String> lines = _desktopBuffer.split(RegExp(r'[\r\n]+'));
                
                // نقوم بمعالجة كل الأسطر المكتملة لنصل لأحدث قراءة
                for (int i = 0; i < lines.length - 1; i++) {
                  String completeLine = lines[i].trim();
                  if (completeLine.isEmpty) continue;

                  // 3. استخراج كافة الأرقام من السطر
                  final matches = RegExp(r'[0-9.]+').allMatches(completeLine).toList();
                  if (matches.isNotEmpty) {
                    // ترتيب الأرقام حسب الطول (الأطول هو الوزن غالباً)
                    matches.sort((a, b) => b.group(0)!.length.compareTo(a.group(0)!.length));
                    String val = matches.first.group(0)!;
                    
                    // تجاهل الأرقام التي تمثل سرعة المنفذ فقط
                    if (val != "9600" && val != "9200") {
                      if (mounted) {
                        setState(() {
                          // تحويل الرقم لنص نظيف (إزالة الأصفار الزائدة والكسور)
                          double? parsed = double.tryParse(val);
                          if (parsed != null) {
                            _weight = parsed.toStringAsFixed(0);
                            _isConnected = true; 
                          }
                        });
                      }
                    }
                  }
                }

                // 4. الاحتفاظ بالجزء المتبقي (غير المكتمل) للمرة القادمة
                _desktopBuffer = lines.last;
                
                // منع تراكم البيانات في المخزن إذا كان كبيراً جداً
                if (_desktopBuffer.length > 100) _desktopBuffer = "";
              }
            });

            setState(() {
              _isConnected = true;
              _desktopBuffer = ""; // تصفير المخزن عند البداية
            });
          }
        } catch (e) {
          _showError("خطأ في فتح المنفذ: $e");
        }
      }
    }
  }

  Future<String?> _showPortPicker(List<String> ports) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("اختر منفذ الميزان (COM Port)"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: ports.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(ports[index]),
              onTap: () => Navigator.pop(context, ports[index]),
            ),
          ),
        ),
      ),
    );
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _stopTimer();
    _reader?.close();
    _desktopPort?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kIsWeb ? 'ميزان البسكول (ويب)' : 'ميزان البسكول (سطح المكتب)'),
        backgroundColor: _isConnected ? Colors.green : Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isConnected ? "الحالة: متصل بالكابل" : "الحالة: غير متصل",
              style: TextStyle(color: _isConnected ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blueAccent, width: 4),
              ),
              child: Text(
                "$_weight KG",
                style: const TextStyle(fontSize: 70, color: Colors.greenAccent, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton.icon(
              onPressed: kIsWeb ? _toggleWebConnection : _toggleDesktopConnection,
              icon: Icon(_isConnected ? Icons.stop : Icons.play_arrow),
              label: Text(_isConnected ? "إيقاف القراءة" : "بدء قراءة الميزان"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: _isConnected ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            if (!kIsWeb) ...[
              const SizedBox(height: 20),
              const Text("نسخة سطح المكتب (Windows/macOS/Linux)", style: TextStyle(color: Colors.grey)),
            ]
          ],
        ),
      ),
    );
  }
}
