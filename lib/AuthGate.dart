import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';
import 'home_page.dart'; // หรือหน้าแรกที่คุณต้องการ

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _mustLogin = true;

  @override
  void initState() {
    super.initState();
    _checkStartup();
  }

  Future<void> _checkStartup() async {
    final prefs = await SharedPreferences.getInstance();

    // ถ้าเคย login อย่างน้อย 1 ครั้งแล้ว จะไม่บังคับให้ logout ตอนเปิดแอป
    final loggedOnce = prefs.getBool("hasLoggedInOnce") ?? false;

    final user = FirebaseAuth.instance.currentUser;

    // ถ้า user != null และเคย login ครั้งก่อน → ให้ข้ามไปเลย
    if (user != null && loggedOnce) {
      _mustLogin = false;
    } else {
      FirebaseAuth.instance.signOut(); // บังคับออก
      _mustLogin = true;
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return _mustLogin ? const LoginPage() : const HomePage();
  }
}
