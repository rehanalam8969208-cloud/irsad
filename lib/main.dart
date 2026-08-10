import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const IsadApp());
}

class IsadApp extends StatelessWidget {
  const IsadApp({super.key});

  static const String apiKey = 'AIzaSyA1Dg_ospNbgXatGj4xnWq-1njNc5Y0dCY'; 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Isad Hisab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF6366F1),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
          centerTitle: true,
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
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email aur Password dono dalein!'), backgroundColor: Colors.redAccent));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['error']['message']), backgroundColor: Colors.redAccent));
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', responseData['idToken']);
        await prefs.setString('auth_uid', responseData['localId']);
        
        if (mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen(token: responseData['idToken'], uid: responseData['localId'])));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Internet check karein!'), backgroundColor: Colors.redAccent));
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, size: 80, color: Color(0xFF6366F1)),
              ),
              const SizedBox(height: 25),
              Text(isLogin ? 'Isad Hisab Kitab' : 'Naya Khata Banayein', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 30),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address', 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password', 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 25),
              isLoading 
                ? const CircularProgressIndicator(color: Color(0xFF6366F1))
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _authenticate,
                      child: Text(isLogin ? 'Login Karein' : 'Register Karein', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(isLogin ? 'Naya account banayein?' : 'Pehle se account hai? Login karein', style: const TextStyle(color: Color(0xFF6366F1), fontSize: 14)),
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
    dbUrl = 'https://irsad-b0b2d-default-rtdb.asia-southeast1.firebasedatabase.app/users/${widget.uid}/hisab_entries.json?auth=${widget.token}';
    loadData();
  }

  Future<void> loadData() async {
    try {
      final response = await http.get(Uri.parse(dbUrl));
      if (response.statusCode == 200 && response.body != 'null' && response.body != '{}') {
        final Map<String, dynamic> data = jsonDecode(response.body);
        List<Entry> loaded = [];
        data.forEach((key, value) {
          loaded.add(Entry.fromJson(value));
        });
        setState(() {
          entries = loaded;
          isLoading = false;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('isad_entries', jsonEncode(entries.map((e) => e.toJson()).toList()));
      } else {
        _loadLocalBackup();
      }
    } catch (e) {
      _loadLocalBackup();
    }
  }

  Future<void> _loadLocalBackup() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('isad_entries');
    if (data != null) {
      List decoded = jsonDecode(data);
      setState(() {
        entries = decoded.map((e) => Entry.fromJson(e)).toList();
      });
    }
    setState(() => isLoading = false);
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    String encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString('isad_entries', encoded);

    try {
      Map<String, dynamic> dataMap = {};
      for (var e in entries) {
        dataMap[e.id.toString()] = e.toJson();
      }
      await http.put(Uri.parse(dbUrl), body: jsonEncode(dataMap));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Online Save Ho Gaya! ✓'), backgroundColor: Colors.green, duration: Duration(seconds: 1)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Net band hai, Phone me save hua.'), backgroundColor: Colors.orange, duration: Duration(seconds: 2)));
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
        title: const Text('Isad Hisab', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: _logout,
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Hisab', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    SizedBox(height: 4),
                    Text('Grand Total', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text('₹${_formatPrice(grandTotal)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(child: pages[_currentIndex]),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: _showAddModal,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: const Color(0xFF6366F1).withOpacity(0.2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF6366F1)), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history_rounded, color: Color(0xFF6366F1)), label: 'History'),
        ],
      ),
    );
  }
}

class MemberDetailScreen extends StatelessWidget {
  final String memberName;
  final List<Entry> memberEntries;
  final String Function(double) formatPrice;

  const MemberDetailScreen({super.key, required this.memberName, required this.memberEntries, required this.formatPrice});

  @override
  Widget build(BuildContext context) {
    double total = memberEntries.fold(0, (sum, e) => sum + e.price);
    List<Entry> sorted = List.from(memberEntries)..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(title: Text('$memberName ka Hisab')),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kul (Total) Baqi:', style: TextStyle(fontSize: 16, color: Colors.grey)),
                Text('₹${formatPrice(total)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(alignment: Alignment.centerLeft, child: Text('Len-Den (Transactions)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final e = sorted[index];
                return Card(
                  color: const Color(0xFF1E1E1E),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white12)),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(backgroundColor: const Color(0xFF6366F1).withOpacity(0.1), child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF6366F1))),
                    title: Text(e.item, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(e.date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    trailing: Text('₹${formatPrice(e.price)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                );
              },
            ),
          ),
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
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: Text('Sabhi Logon Ka Hisab', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: isLoading 
            ? const Center(child: CircularProgressIndicator())
            : entries.isEmpty
              ? const Center(child: Text('Abhi koi hisab nahi hai.\nNiche (+) dabakar entry karein.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  children: memberTotals.entries.map((entry) {
                    final memberName = entry.key;
                    final memberTotal = entry.value;
                    final listForMember = entries.where((e) => e.name == memberName).toList();

                    return Card(
                      color: const Color(0xFF1E1E1E),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white12)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => MemberDetailScreen(memberName: memberName, memberEntries: listForMember, formatPrice: formatPrice)));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(backgroundColor: const Color(0xFF6366F1).withOpacity(0.1), child: Text(memberName[0].toUpperCase(), style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold))),
                                  const SizedBox(width: 15),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(memberName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      const Text('Pura hisab dekhein ->', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ),
                              Text('₹${formatPrice(memberTotal)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: Text('Sabhi Len-Den Ki List', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: isLoading 
            ? const Center(child: CircularProgressIndicator())
            : entries.isEmpty
              ? const Center(child: Text('Koi history nahi hai.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final e = sorted[index];
                    String shortDate = e.date.length == 10 ? e.date.substring(5) : e.date; 

                    return Card(
                      color: const Color(0xFF1E1E1E),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white12)),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('₹${formatPrice(e.price)}', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        subtitle: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.item, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            Text(shortDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        trailing: GestureDetector(
                          onTap: () => onDelete(e.id),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                        ),
                      ),
                    );
                  },
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24, bottom: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Naya Hisab Jodein', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (existingNames.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF1E1E1E),
                decoration: InputDecoration(labelText: 'Purana Naam Chunein', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: existingNames.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                onChanged: (val) { if (val != null) nameController.text = val; },
              ),
              const SizedBox(height: 12),
            ],
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Naam Likhein', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: selectedDate), readOnly: true, decoration: InputDecoration(labelText: 'Tarik (Date)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), suffixIcon: const Icon(Icons.calendar_today_rounded)),
              onTap: () async {
                DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (picked != null) { setState(() { selectedDate = picked.toIso8601String().split('T')[0]; }); }
              },
            ),
            const SizedBox(height: 12),
            TextField(controller: itemController, decoration: InputDecoration(labelText: 'Saman / Vivran (Jaise: Udhar, Kirana)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            TextField(controller: priceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Kitne Paise (₹)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.currency_rupee_rounded))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Radd (Cancel)'),
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      if (nameController.text.trim().isEmpty || priceController.text.trim().isEmpty) return;
                      double? price = double.tryParse(priceController.text);
                      if (price == null || price <= 0) return;

                      Entry newEntry = Entry(id: DateTime.now().millisecondsSinceEpoch, name: nameController.text.trim(), date: selectedDate, item: itemController.text.trim().isEmpty ? 'General Hisab' : itemController.text.trim(), price: price);
                      widget.onSave(newEntry);
                      Navigator.pop(context);
                    },
                    child: const Text('Save Karein', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}          
