import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';
import 'package:file_picker/file_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VocatApp());
}

class VocatApp extends StatelessWidget {
  const VocatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const VocatLockScreen(),
    );
  }
}

class VocatLockScreen extends StatefulWidget {
  const VocatLockScreen({super.key});

  @override
  State<VocatLockScreen> createState() => _VocatLockScreenState();
}

class _VocatLockScreenState extends State<VocatLockScreen> {
  bool isMeaningVisible = false;
  bool isHintVisible = false; // İpucunun görünüp görünmeyeceğini tutan YENİ değişken
  bool isLoading = true;

  Map<String, dynamic>? currentWord;

  @override
  void initState() {
    super.initState();
    _loadRandomWord();
  }

  Future<void> _pickAndLoadNewCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;

        setState(() { isLoading = true; });

        await DatabaseHelper.instance.replaceDatabaseWithNewCSV(filePath);
        await _loadRandomWord();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Yeni kelime listesi başarıyla yüklendi! ✅'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { isLoading = false; });
      }
    }
  }

  Future<void> _loadRandomWord() async {
    setState(() {
      isLoading = true;
      isMeaningVisible = false;
      isHintVisible = false; // Yeni kelime geldiğinde ipucunu da tekrar GİZLE
    });

    await DatabaseHelper.instance.loadCSVToDatabase();
    final word = await DatabaseHelper.instance.getRandomWord();

    setState(() {
      currentWord = word;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Center(
            child: isLoading
                ? const CircularProgressIndicator()
                : currentWord == null
                ? const Card(child: Padding(padding: EdgeInsets.all(20), child: Text("Kelime bulunamadı!")))
                : GestureDetector(
              onTap: () {
                // Karta tıklanınca anlamı göster (ama ipucunu otomatik açma)
                setState(() {
                  isMeaningVisible = true;
                });
              },
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "🇬🇧 KELİME",
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentWord!['W'] ?? '',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // İPUCU KISMI (Eğer veritabanında "Yok" yazmıyorsa veya boş değilse)
                      if (currentWord!['S'] != "Yok" && currentWord!['S'].toString().trim().isNotEmpty) ...[
                        // İpucu henüz açılmadıysa Buton göster
                        if (!isHintVisible)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                isHintVisible = true;
                              });
                            },
                            icon: const Icon(Icons.lightbulb_outline, color: Colors.amber),
                            label: const Text("İpucunu Göster", style: TextStyle(color: Colors.amber, fontSize: 16)),
                          )
                        // Butona basıldıysa İpucunu göster
                        else ...[
                          const Text(
                            "💡 İPUCU",
                            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentWord!['S'],
                            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ]
                      ],

                      const SizedBox(height: 24),

                      // ANLAM KISMI
                      if (!isMeaningVisible)
                        const Text(
                          "👇 Anlamını görmek için karta dokun",
                          style: TextStyle(color: Colors.blueAccent),
                        )
                      else ...[
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          "🇹🇷 ANLAMI",
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentWord!['M'] ?? '',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.green),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  SystemNavigator.pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text("KAPAT"),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _loadRandomWord,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text("SONRAKİ"),
                              ),
                            ),
                          ],
                        )
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.file_upload, color: Colors.white, size: 32),
              onPressed: _pickAndLoadNewCSV,
              tooltip: "Yeni CSV Yükle",
            ),
          ),
        ],
      ),
    );
  }
}