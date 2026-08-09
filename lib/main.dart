import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const IsadApp());
}

class IsadApp extends StatefulWidget {
  const IsadApp({super.key});

  static const String apiKey = 'AIzaSyA1Dg_ospNbgXatGj4xnWq-1njNc5Y0dCY'; 

  @override
  State<IsadApp> createState() => _IsadAppState();

  static _IsadAppState of(BuildContext context) => context.findAncestorStateOfType<_IsadAppState>()!;
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (token != null && uid != null) {
      return HomeScreen(token: token!, uid: uid!);
    }
    return const LoginScreen();
  }
}

// 1. Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoading = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _login() async {
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Email and Password!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => isLoading = true);
    final url = 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${IsadApp.apiKey}';

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['error']['message']), backgroundColor: Colors.red));
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', responseData['idToken']);
        await prefs.setString('auth_uid', responseData['localId']);
        
        if (mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen(token: responseData['idToken'], uid: responseData['localId'])));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check your internet connection!'), backgroundColor: Colors.red));
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
              const Text('Login to Isad Khata', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38bdf8), padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: _login,
                      child: const Text('Login', style: TextStyle(color: Color(0xFF0b0f19), fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
                child: const Text('Create a new account? Register', style: TextStyle(color: Color(0xFF38bdf8))),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// 2. Signup Screen (Alag Page)
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool isLoading = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _register() async {
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Email and Password!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => isLoading = true);
    final url = 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${IsadApp.apiKey}';

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['error']['message']), backgroundColor: Colors.red));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created successfully! Please login.'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check your internet connection!'), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add, size: 80, color: Color(0xFF38bdf8)),
              const SizedBox(height: 20),
              const Text('Create New Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38bdf8), padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: _register,
                      child: const Text('Register', style: TextStyle(color: Color(0xFF0b0f19), fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Synced to Cloud! ✓', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green, duration: Duration(seconds: 1)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cloud sync failed! Saved locally.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.orange, duration: Duration(seconds: 2)));
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
        elevation: 1,
        title: const Text('Isad Manager', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Center(child: Text('Total: ₹${_formatPrice(grandTotal)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15))),
          const SizedBox(width: 10),
          // Profile & Settings Icon on AppBar
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(uid: widget.uid))),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: const CircleBorder(),
        elevation: 4,
        onPressed: _showAddModal,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
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
          Icon(icon, color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey, size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

// 3. Profile & Settings Screen (Logout inside settings, Day/Night toggle)
class ProfileScreen extends StatelessWidget {
  final String uid;
  const ProfileScreen({super.key, required this.uid});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Details Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF38bdf8),
                  child: Icon(Icons.person, size: 35, color: Color(0xFF0b0f19)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('User Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text('ID: ${uid.substring(0, 10)}...', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const Text('Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          // Day/Night Theme Setting
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Switch between light and dark theme'),
            secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
            value: isDarkMode,
            onChanged: (val) {
              IsadApp.of(context).toggleTheme(val);
            },
          ),
          const Divider(),
          // Logout Option in Settings
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            subtitle: const Text('₹${e.price}', style: const TextStyle(color: Color(0xFF38bdf8), fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
          child: Text('Members Total Summary', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: isLoading 
            ? const Center(child: CircularProgressIndicator())
            : entries.isEmpty
              ? const Center(child: Text('No data available.\nTap (+) below to add an entry.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  children: memberTotals.entries.map((entry) {
                    final memberName = entry.key;
                    final memberTotal = entry.value;
                    final listForMember = entries.where((e) => e.name == memberName).toList();

                    return GestureDetector(
                      onTap: () {
                        // Click on member name opens individual details page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MemberDetailScreen(memberName: memberName, memberEntries: listForMember)),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                                Text(memberName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                const Text('Tap to view details', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            Text('₹${formatPrice(memberTotal)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                          ],
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
    const TextStyle headerStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
    const TextStyle rowStyle = TextStyle(fontSize: 13);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(15, 15, 15, 10),
          child: Text('All Entries Record', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: isLoading 
            ? const Center(child: CircularProgressIndicator())
            : entries.isEmpty
              ? const Center(child: Text('No history available.', style: TextStyle(color: Colors.grey)))
              : Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withOpacity(0.2))),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0f172a) : Colors.grey.shade200, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                        child: const Row(
                          children: [
                            Expanded(flex: 3, child: Text('Date', style: headerStyle)),
                            Expanded(flex: 3, child: Text('Name', style: headerStyle)),
                            Expanded(flex: 3, child: Text('Item', style: headerStyle)),
                            Expanded(flex: 2, child: Text('₹', style: headerStyle)),
                            SizedBox(width: 24),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: sorted.length,
                          separatorBuilder: (context, index) => Divider(color: Colors.grey.withOpacity(0.2), height: 1),
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
                                  Expanded(flex: 2, child: Text('₹${formatPrice(e.price)}', style: rowStyle.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  GestureDetector(onTap: () => onDelete(e.id), child: const Icon(Icons.close, color: Colors.red, size: 20)),
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
            const Text('Add New Entry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            if (existingNames.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                dropdownColor: Theme.of(context).colorScheme.surface,
                decoration: const InputDecoration(labelText: 'Select Existing Member', border: OutlineInputBorder()),
                items: existingNames.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                onChanged: (val) { if (val != null) nameController.text = val; },
              ),
              const SizedBox(height: 10),
            ],
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Member Name', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(
              controller: TextEditingController(text: selectedDate), readOnly: true, decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder()),
              onTap: () async {
                DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (picked != null) { setState(() { selectedDate = picked.toIso8601String().split('T')[0]; }); }
              },
            ),
            const SizedBox(height: 10),
            TextField(controller: itemController, decoration: const InputDecoration(labelText: 'Item Name (Optional)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)), onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      if (nameController.text.trim().isEmpty || priceController.text.trim().isEmpty) return;
                      double? price = double.tryParse(priceController.text);
                      if (price == null || price <= 0) return;

                      Entry newEntry = Entry(id: DateTime.now().millisecondsSinceEpoch, name: nameController.text.trim(), date: selectedDate, item: itemController.text.trim().isEmpty ? 'Ration Item' : itemController.text.trim(), price: price);
                      widget.onSave(newEntry);
                      Navigator.pop(context);
                    },
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
