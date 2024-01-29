// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tz1/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthPage(),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _signInAnonymously(BuildContext context) async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      print("Signed in with temporary account: ${userCredential.user!.uid}");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      print("Failed to sign in anonymously: $e");
    }
  }

  void _checkAuthentication() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      print("User is already signed in with UID: ${currentUser.uid}");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (Route<dynamic> route) => false,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            _signInAnonymously(context);
          },
          child: const Text('Войти анонимно'),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _firstName = '';
  String _lastName = '';
  String _middleName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    String uid = _auth.currentUser?.uid ?? '';
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        _firstName = userData['firstName'] ?? '';
        _lastName = userData['lastName'] ?? '';
        _middleName = userData['middleName'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    super.dispose();
  }

  Future<void> _updateUserInfo() async {
    String uid = _auth.currentUser?.uid ?? '';
    await _firestore.collection('users').doc(uid).set({
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'middleName': _middleNameController.text,
    });
    _loadUserData();
    _firstNameController.clear();
    _lastNameController.clear();
    _middleNameController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование профиля'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                  labelText: _firstName == '' ? 'Имя' : _firstName),
            ),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                  labelText: _lastName == '' ? 'Фамилия' : _lastName),
            ),
            TextField(
              controller: _middleNameController,
              decoration: InputDecoration(
                  labelText: _middleName == '' ? 'Отчество' : _middleName),
            ),
            ElevatedButton(
              onPressed: _updateUserInfo,
              child: const Text('Сохранить изменения'),
            ),
          ],
        ),
      ),
    );
  }
}
