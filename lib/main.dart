import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const IsadApp());
}

class IsadApp extends StatelessWidget {
  const IsadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Isad - Ration Manager',
      debugShowCheckedModeBanner: false, // फालतू Debug टेक्स्ट हटाने के लिए
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0b0f19),
        primaryColor: const Color(0xFF38bdf8),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38bdf8),
          surface: Color(0xFF1e293b),
        ),
      ),
      home: const HomeScreen(),
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
  const HomeScreen({super.key});

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
  }

  void _showAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1e293b),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
      DashboardTab(entries: entries),
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
        backgroundColor: const Color(0xFF1e293b),
        elevation: 1,
        title: const Text('Isad - Ration Khata', style: TextStyle(color: Color(0xFF38bdf8), fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Center(
              child: Text('Total: ₹$grandTotal', style: const TextStyle(color: Color(0xFF22c55e), fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        height: 65,
        decoration: const BoxDecoration(
          color: Color(0xFF1e293b),
          border: Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Home', 0),
            FloatingActionButton(
              backgroundColor: const Color(0xFF38bdf8),
              elevation: 4,
              onPressed: _showAddModal,
              child: const Icon(Icons.add, color: Color(0xFF0b0f19), size: 30),
            ),
            _buildNavItem(Icons.table_chart, 'Sheet', 1),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? const Color(0xFF38bdf8) : const Color(0xFF94a3b8), size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: isActive ? const Color(0xFF38bdf8) : const Color(0xFF94a3b8), fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  final List<Entry> entries;

  const DashboardTab({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    Map<String, double> memberTotals = {};
    for (var e in entries) {
      memberTotals[e.name] = (memberTotals[e.name] ?? 0) + e.price;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(15, 15, 15, 5),
          child: Text('Members Total Summary', style: TextStyle(color: Color(0xFF94a3b8), fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: entries.isEmpty
              ? const Center(child: Text('Abhi koi data nahi hai.\nNiche (+) dabakar entry karein.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94a3b8))))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  children: memberTotals.entries.map((entry) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1e293b),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFf8fafc))),
                            const SizedBox(height: 4),
                            const Text('Total Kharcha / Hisab', style: TextStyle(fontSize: 13, color: Color(0xFF94a3b8))),
                          ],
                        ),
                        Text('₹${entry.value}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF38bdf8))),
                      ],
                    ),
                  )).toList(),
                ),
        ),
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
    List<Entry> sorted = List.from(entries)..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(15, 15, 15, 5),
          child: Text('Sabhi Entries ka Record', style: TextStyle(color: Color(0xFF94a3b8), fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: entries.isEmpty
              ? const Center(child: Text('Koi history available nahi hai.', style: TextStyle(color: Color(0xFF94a3b8))))
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1e293b),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFF0f172a)),
                        columns: const [
                          DataColumn(label: Text('Date', style: TextStyle(color: Color(0xFF38bdf8), fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Naam', style: TextStyle(color: Color(0xFF38bdf8), fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Saman', style: TextStyle(color: Color(0xFF38bdf8), fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('₹', style: TextStyle(color: Color(0xFF38bdf8), fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('')),
                        ],
                        rows: sorted.map((e) => DataRow(cells: [
                          DataCell(Text(e.date, style: const TextStyle(color: Color(0xFFf8fafc)))),
                          DataCell(Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFf8fafc)))),
                          DataCell(Text(e.item, style: const TextStyle(color: Color(0xFFf8fafc)))),
                          DataCell(Text('₹${e.price}', style: const TextStyle(color: Color(0xFF38bdf8), fontWeight: FontWeight.bold))),
                          DataCell(IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFFef4444), size: 18),
                            onPressed: () => onDelete(e.id),
                          )),
                        ])).toList(),
                      ),
                    ),
                  ),
                ),
        ),
      ],
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
            const Text('Naya Hisab Jodein', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFf8fafc))),
            const SizedBox(height: 15),
            if (existingNames.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF1e293b),
                style: const TextStyle(color: Color(0xFFf8fafc)),
                decoration: const InputDecoration(labelText: 'Member ka Naam (Chunein)', border: OutlineInputBorder(), labelStyle: TextStyle(color: Color(0xFF94a3b8))),
                items: existingNames.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                onChanged: (val) {
                  if (val != null) nameController.text = val;
                },
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: nameController,
              style: const TextStyle(color: Color(0xFFf8fafc)),
              decoration: const InputDecoration(labelText: 'Naya Naam Likhein', border: OutlineInputBorder(), labelStyle: TextStyle(color: Color(0xFF94a3b8))),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: TextEditingController(text: selectedDate),
              readOnly: true,
              style: const TextStyle(color: Color(0xFFf8fafc)),
              decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder(), labelStyle: TextStyle(color: Color(0xFF94a3b8))),
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
              style: const TextStyle(color: Color(0xFFf8fafc)),
              decoration: const InputDecoration(labelText: 'Saman ka Naam (Optional)', border: OutlineInputBorder(), labelStyle: TextStyle(color: Color(0xFF94a3b8))),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Color(0xFFf8fafc)),
              decoration: const InputDecoration(labelText: 'Kitne Paise (₹)', border: OutlineInputBorder(), labelStyle: TextStyle(color: Color(0xFF94a3b8))),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: Color(0xFF334155))),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Radd Karein', style: TextStyle(color: Color(0xFFf8fafc), fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38bdf8), padding: const EdgeInsets.symmetric(vertical: 14)),
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
                    child: const Text('Save Karein', style: TextStyle(color: Color(0xFF0b0f19), fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
