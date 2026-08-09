import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const IsadApp());
}

class IsadApp extends StatelessWidget {
  const IsadApp({super.key});

  // तेरी Firebase Web API Key
  static const String apiKey = 'AIzaSyA1Dg_ospNbgXatGj4xnWq-1njNc5Y0dCY'; 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Isad - Ration Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0b0f19),
        primaryColor: const Color(0xFF38bdf8),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38bdf8),
          surface: Color(0xFF1e293b),
        ),
      ),
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool isLoading = true;
  String? token;
  String? uid;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('auth_token');
      uid = prefs.getString('auth_uid');
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF38bdf8))));
    }
    if (token != null && uid != null) {
      return HomeScreen(token: token!, uid: uid!);
    }
    return const AuthScreen();
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _authenticate() async {
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email aur Password dono dalein!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      return;
    }

    setState(() => isLoading = true);
    final url = isLogin 
        ? 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${IsadApp.apiKey}'
        : 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${IsadApp.apiKey}';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
          'returnSecureToken': true,
        }),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (responseData['error'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['error']['message'], style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', responseData['idToken']);
        await prefs.setString('auth_uid', responseData['localId']);
        
        if (mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen(token: responseData['idToken'], uid: responseData['localId'])));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Internet check karein!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet, size: 80, color: Color(0xFF38bdf8)),
              const SizedBox(height: 20),
              Text(isLogin ? 'Isad Khata me Login karein' : 'Naya Account Banayein', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              isLoading 
                ? const CircularProgressIndicator(color: Color(0xFF38bdf8))
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38bdf8), padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: _authenticate,
                      child: Text(isLogin ? 'Login' : 'Register', style: const TextStyle(color: Color(0xFF0b0f19), fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(isLogin ? 'Naya account banayein?' : 'Pehle se account hai? Login karein', style: const TextStyle(color: Color(0xFF38bdf8))),
              )
            ],
          ),
        ),
      ),
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

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'date': date, 'item': item, 'price': price};
  factory Entry.fromJson(Map<String, dynamic> json) => Entry(id: json['id'], name: json['name'], date: json['date'], item: json['item'], price: json['price'].toDouble());
}

class HomeScreen extends StatefulWidget {
  final String token;
  final String uid;
  const HomeScreen({super.key, required this.token, required this.uid});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Entry> entries = [];
  bool isLoading = true;
  late String dbUrl;

  @override
  void initState() {
    super.initState();
    dbUrl = 'https://irsad-b0b2d-default-rtdb.asia-southeast1.firebasedatabase.app/users/${widget.uid}/ration_entries.json?auth=${widget.token}';
    loadData();
  }

  Future<void> loadData() async {
    try {
      final response = await http.get(Uri.parse(dbUrl));
      if (response.statusCode == 200 && response.body != 'null') {
        final Map<String, dynamic> data = jsonDecode(response.body);
        List<Entry> loaded = [];
        data.forEach((key, value) {
          loaded.add(Entry.fromJson(value));
        });
        setState(() {
          entries = loaded;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> saveData() async {
    try {
      Map<String, dynamic> dataMap = {};
      for (var e in entries) {
        dataMap[e.id.toString()] = e.toJson();
      }
      await http.put(Uri.parse(dbUrl), body: jsonEncode(dataMap));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Online Save Ho Gaya! ✓', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green, duration: Duration(seconds: 1)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Internet error! Data save nahi hua.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red, duration: Duration(seconds: 2)));
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const AuthScreen()));
    }
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
          setState(() { entries.add(newEntry); });
          saveData();
        },
      ),
    );
  }

  String _formatPrice(double price) => price % 1 == 0 ? price.toInt().toString() : price.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    double grandTotal = entries.fold(0, (sum, item) => sum + item.price);

    final List<Widget> pages = [
      DashboardTab(entries: entries, formatPrice: _formatPrice, isLoading: isLoading),
      HistoryTab(
        entries: entries,
        formatPrice: _formatPrice,
        isLoading: isLoading,
        onDelete: (id) {
          setState(() { entries.removeWhere((e) => e.id == id); });
          saveData();
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e293b),
        elevation: 1,
        title: const Text('Isad', style: TextStyle(color: Color(0xFF38bdf8), fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Center(child: Text('Total: ₹${_formatPrice(grandTotal)}', style: const TextStyle(color: Color(0xFF22c55e), fontWeight: FontWeight.bold, fontSize: 15))),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
          )
        ],
      ),
      body: pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF38bdf8),
        shape: const CircleBorder(),
        elevation: 4,
        onPressed: _showAddModal,
        child: const Icon(Icons.add, color: Color(0xFF0b0f19), size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1e293b),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0),
              const SizedBox(width: 48),
              _buildNavItem(Icons.table_chart, 'Sheet', 1),
            ],
          ),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? const Color(0xFF38bdf8) : const Color(0xFF94a3b8), size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: isActive ? const Color(0xFF38bdf8) : const Color(0xFF94a3b8), fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  final List<Entry> entries;
  final String Function(double) formatPrice;
  final bool isLoading;

  const DashboardTab({super.key, required this.entries, required this.formatPrice, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    Map<String, double> memberTotals = {};
    for (var e in entries) { memberTotals[e.name] = (memberTotals[e.name] ?? 0) + e.price; }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(15, 15, 15, 5),
          child: Text('Members Total Summary', style: TextStyle(color: Color(0xFF94a3b8), fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF38bdf8)))
            : entries.isEmpty
              ? const Center(child: Text('Abhi koi data nahi hai.\nNiche (+) dabakar entry karein.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94a3b8))))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  children: memberTotals.entries.map((entry) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF1e293b), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF334155))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFf8fafc))),
                            const SizedBox(height: 4),
                            const Text('Total Kharcha', style: TextStyle(fontSize: 13, color: Color(0xFF94a3b8))),
                          ],
                        ),
                        Text('₹${formatPrice(entry.value)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF38bdf8))),
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
  final String Function(double) formatPrice;
  final bool isLoading;

  const HistoryTab({super.key, required this.entries, required this.onDelete, required this.formatPrice, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    List<Entry> sorted = List.from(entries)..sort((a, b) => b.date.compareTo(a.date));
    const TextStyle headerStyle = TextStyle(color: Color(0xFF38bdf8), fontWeight: FontWeight.bold, fontSize: 13);
    const TextStyle rowStyle = TextStyle(color: Color(0xFFf8fafc), fontSize: 13);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(15, 15, 15, 10),
          child: Text('Sabhi Entries ka Record', style: TextStyle(color: Color(0xFF94a3b8), fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF38bdf8)))
            : entries.isEmpty
              ? const Center(child: Text('Koi history available nahi hai.', style: TextStyle(color: Color(0xFF94a3b8))))
              : Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFF1e293b), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF334155))),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        decoration: const BoxDecoration(color: Color(0xFF0f172a), borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
                        child: const Row(
                          children: [
                            Expanded(flex: 3, child: Text('Date', style: headerStyle)),
                            Expanded(flex: 3, child: Text('Naam', style: headerStyle)),
                            Expanded(flex: 3, child: Text('Saman', style: headerStyle)),
                            Expanded(flex: 2, child: Text('₹', style: headerStyle)),
                            SizedBox(width: 24),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: sorted.length,
                          separatorBuilder: (context, index) => const Divider(color: Color(0xFF334155), height: 1),
                          itemBuilder: (context, index) {
                            final e = sorted[index];
                            String shortDate = e.date.length == 10 ? e.date.substring(5) : e.date; 

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(flex: 3, child: Text(shortDate, style: rowStyle)),
                                  Expanded(flex: 3, child: Text(e.name, style: rowStyle.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  Expanded(flex: 3, child: Text(e.item, style: rowStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  Expanded(flex: 2, child: Text('₹${formatPrice(e.price)}', style: rowStyle.copyWith(color: const Color(0xFF38bdf8), fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  GestureDetector(onTap: () => onDelete(e.id), child: const Icon(Icons.close, color: Color(0xFFef4444), size: 20)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
                onChanged: (val) { if (val != null) nameController.text = val; },
              ),
              const SizedBox(height: 10),
            ],
            TextField(controller: nameController, style: const TextStyle(color: Color(0xFFf8fafc)), decoration: const InputDecoration(labelText: 'Naya Naam Likhein', border: OutlineInputBorder(), labelStyle: TextStyle(color: Color(0xFF94a3b8)))),
            const SizedBox(height: 10),
            TextField(
              controller: TextEditingController(text: selectedDate), readOnly: true, style: const TextStyle(color: Color(0xFFf8fafc)), decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder(), labelStyle: TextStyle(color: Color(0xFF94a3b8))),
              onTap: () async {
                DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (picked != null) { setState(() { selectedDate = picked.toIso8601String().split('T')[0]; }); }
              },
            ),
            const SizedBox(height: 10),
            TextField(controller: itemController, style: const TextStyle(color: Color(0xFFf8fafc)), decoration: const InputDecoration(labelText: 'Saman ka Naam (Optional)', border: OutlineInputBorder(), labelStyle: TextStyle(color: Color(0xFF94a3b8)))),
            const SizedBox(height: 10),
            TextField(controller: priceController, keyboardType: TextInputType.number, style: const TextStyle(color: Color(0xFFf8fafc)), decoration: const InputDecoration(labelText: 'Kitne Paise (₹)', border: OutlineInputBorder(), labelStyle: TextStyle(color: Color(0xFF94a3b8)))),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: Color(0xFF334155))), onPressed: () => Navigator.pop(context), child: const Text('Radd Karein', style: TextStyle(color: Color(0xFFf8fafc), fontWeight: FontWeight.bold, fontSize: 15)))),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38bdf8), padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      if (nameController.text.trim().isEmpty || priceController.text.trim().isEmpty) return;
                      double? price = double.tryParse(priceController.text);
                      if (price == null || price <= 0) return;

                      Entry newEntry = Entry(id: DateTime.now().millisecondsSinceEpoch, name: nameController.text.trim(), date: selectedDate, item: itemController.text.trim().isEmpty ? 'Ration Saman' : itemController.text.trim(), price: price);
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
