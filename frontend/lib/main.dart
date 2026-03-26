import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const CafeteriaApp());

class CafeteriaApp extends StatelessWidget {
  const CafeteriaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.orange),
        home: const HomeScreen(),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> cart = [];
  String aiResponse = 'Ask me for a budget meal!';
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _queryController = TextEditingController();

  static const String _backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://your-cloud-run-url.a.run.app',
  );

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> askAI() async {
    try {
      final response = await http.post(
      Uri.parse('$_backendBaseUrl/ai-chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': _queryController.text,
        'budget': _budgetController.text,
        'businessId': 'Cafe-Express-01'
      }),
    );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() => aiResponse = jsonDecode(response.body)['answer'] as String);
      } else {
        setState(() => aiResponse = 'Unable to get AI suggestion right now.');
      }
    } catch (_) {
      setState(() => aiResponse = 'Network error while contacting AI service.');
    }
  }

  Future<void> checkout() async {
    try {
      final response = await http.post(
      Uri.parse('$_backendBaseUrl/create-checkout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'cartItems': cart,
        'businessId': 'Cafe-Express-01',
        'customerEmail': 'customer@example.com'
      }),
    );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final url = jsonDecode(response.body)['url'] as String;
        final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
        if (!launched) _showMessage('Could not open checkout URL.');
      } else {
        _showMessage('Checkout failed. Please try again.');
      }
    } catch (_) {
      _showMessage('Network error while creating checkout.');
    }
  }

  void addCappuccino() {
    setState(() {
      cart.add({'name': 'Cappuccino', 'price': 4.50, 'quantity': 1});
    });
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cafeteria Brand Name')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.grey[200],
            child: Column(
              children: [
                TextField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Your Budget (\$)'),
                ),
                TextField(
                  controller: _queryController,
                  decoration: const InputDecoration(
                    labelText: 'What do you feel like eating?',
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: askAI,
                  child: const Text('Ask AI Assistant'),
                ),
                const SizedBox(height: 8),
                Text(
                  aiResponse,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('Cappuccino - \$4.50'),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: addCappuccino,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Items in cart: ${cart.length}'),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              onPressed: cart.isEmpty ? null : checkout,
              child: const Text('Checkout with Stripe (Tax & Delivery)'),
            ),
          )
        ],
      ),
    );
  }
}
