import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const IsadApp());
}

class IsadApp extends StatefulWidget {
  const IsadApp({super.key});

  @override
  State<IsadApp> createState() => _IsadAppState();
}

class _IsadAppState extends State<IsadApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    bool isDark = prefs.getBool('is_dark_theme') ?? true;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_theme', isDark);
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Isad - Ration Manager',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFf8fafc),
        primaryColor: const Color(0xFF2563eb),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2563eb),
          surface: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0b0f19),
        primaryColor: const Color(0xFF38bdf8),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38bdf8),
          surface: Color(0xFF1e293b),
        ),
      ),
      home: HomeScreen(onThemeToggle: toggleTheme, isDark: _themeMode == ThemeMode.dark),
    );
  }
}

class Entry {
  int id;
  String name;
  String date;
  String item;
  double price;

  Entry({required this.id, required this.name, required this.date, required this.item, required this.price});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'date': date,
        'item': item,
        'price': price,
      };

  factory Entry.fromJson(Map<String, dynamic> json) => Entry(
        id: json['id'],
        name: json['name'],
        date: json['date'],
        item: json['item'],
        price: json['price'].toDouble(),
      );
}

class HomeScreen extends StatefulWidget {
  final Function(bool) onThemeToggle;
  final bool isDark;

  const HomeScreen({super.key, required this.onThemeToggle, required this.isDark});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Entry> entries = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('isad_entries');
    if (data != null) {
      List decoded = jsonDecode(data);
      setState(() {
        entries = decoded.map((e) => Entry.fromJson(e)).toList();
      });
    }
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    String encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString('isad_entries', encoded);
    setState(() {});
  }

  void _showAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddEntryModal(
        existingEntries: entries,
        onSave: (newEntry) {
          setState(() {
            entries.add(newEntry);
          });
          saveData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double grandTotal = entries.fold(0, (sum, item) => sum + item.price);

    final List<Widget> pages = [
      DashboardTab(
        entries: entries,
        onDelete: (id) {
          setState(() {
            entries.removeWhere((e) => e.id == id);
          });
          saveData();
        },
      ),
      HistoryTab(
        entries: entries,
        onDelete: (id) {
          setState(() {
            entries.removeWhere((e) => e.id == id);
          });
          saveData();
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Isad - Ration Khata', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => widget.onThemeToggle(!widget.isDark),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
            child: Text('₹$grandTotal', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        height: 65,
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home, color: _currentIndex == 0 ? Theme.of(context).colorScheme.primary : Colors.grey),
                  const Text('Home', style: TextStyle(fontSize: 10))
                ],
              ),
              onPressed: () => setState(() => _currentIndex = 0),
            ),
            FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.primary,
              elevation: 2,
              onPressed: _showAddModal,
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
            IconButton(
              icon: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.table_chart, color: _currentIndex == 1 ? Theme.of(context).colorScheme.primary : Colors.grey),
                  const Text('Sheet', style: TextStyle(fontSize: 10))
                ],
              ),
              onPressed: () => setState(() => _currentIndex = 1),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  final List<Entry> entries;
  final Function(int) onDelete;

  const DashboardTab({super.key, required this.entries, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    Map<String, double> memberTotals = {};
    for (var e in entries) {
      memberTotals[e.name] = (memberTotals[e.name] ?? 0) + e.price;
    }

    if (entries.isEmpty) {
      return const Center(child: Text('Data uplabdh nahi hai.\n(+) dabakar entry jodein.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)));
    }

    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        const Text('Members Total Summary', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...memberTotals.entries.map((entry) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Total Kharcha', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Text('₹${entry.value}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                ],
              ),
            )),
      ],
    );
  }
}

class HistoryTab extends StatelessWidget {
  final List<Entry> entries;
  final Function(int) onDelete;

  const HistoryTab({super.key, required this.entries, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Text('Koi history nahi hai.', style: TextStyle(color: Colors.grey)));
    }

    List<Entry> sorted = List.from(entries)..sort((a, b) => b.date.compareTo(a.date));

    return Padding(
      padding: const EdgeInsets.all(15),
      child: ListView(
        children: [
          const Text('Sabhi Entries ka Record', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Naam')),
                DataColumn(label: Text('Saman')),
                DataColumn(label: Text('₹')),
                DataColumn(label: Text('Action')),
              ],
              rows: sorted
                  .map((e) => DataRow(cells: [
                        DataCell(Text(e.date)),
                        DataCell(Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(e.item)),
                        DataCell(Text('₹${e.price}', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                          onPressed: () => onDelete(e.id),
                        )),
                      ]))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class AddEntryModal extends StatefulWidget {
  final List<Entry> existingEntries;
  final Function(Entry) onSave;

  const AddEntryModal({super.key, required this.existingEntries, required this.onSave});

  @override
  State<AddEntryModal> createState() => _AddEntryModalState();
}

class _AddEntryModalState extends State<AddEntryModal> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController itemController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  String selectedDate = DateTime.now().toIso8601String().split('T')[0];

  @override
  Widget build(BuildContext context) {
    List<String> existingNames = widget.existingEntries.map((e) => e.name).toSet().toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Naya Hisab Jodein', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            if (existingNames.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                dropdownColor: Theme.of(context).colorScheme.surface,
                decoration: const InputDecoration(labelText: 'Purana Naam Chunein', border: OutlineInputBorder()),
                items: existingNames.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                onChanged: (val) {
                  if (val != null) nameController.text = val;
                },
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Member ka Naam', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: TextEditingController(text: selectedDate),
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder()),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked.toIso8601String().split('T')[0];
                  });
                }
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: itemController,
              decoration: const InputDecoration(labelText: 'Saman ka Naam (Optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Kitne Paise (₹)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
                onPressed: () {
                  if (nameController.text.trim().isEmpty || priceController.text.trim().isEmpty) return;
                  double? price = double.tryParse(priceController.text);
                  if (price == null || price <= 0) return;

                  Entry newEntry = Entry(
                    id: DateTime.now().millisecondsSinceEpoch,
                    name: nameController.text.trim(),
                    date: selectedDate,
                    item: itemController.text.trim().isEmpty ? 'Ration Saman' : itemController.text.trim(),
                    price: price,
                  );

                  widget.onSave(newEntry);
                  Navigator.pop(context);
                },
                child: const Text('Save Karein', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
