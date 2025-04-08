import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FirebaseAuth.instance.currentUser == null ? AuthScreen() : TaskScreen(),
    );
  }
}

// ---------------------- AUTH SCREEN ----------------------
class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLogin = true;

  Future<void> _authenticate() async {
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TaskScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Register')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            ElevatedButton(
              onPressed: _authenticate,
              child: Text(isLogin ? 'Login' : 'Register'),
            ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin ? 'Need an account? Register' : 'Already have an account? Login'),
            )
          ],
        ),
      ),
    );
  }
}
// ---------------------- TASK SCREEN ----------------------
class TaskScreen extends StatefulWidget {
  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final taskController = TextEditingController();
  final timeframeController = TextEditingController();
  final dayController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser!;

  Future<void> _addTask() async {
    if (taskController.text.isEmpty || dayController.text.isEmpty || timeframeController.text.isEmpty) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(dayController.text);

    await docRef.set({}, SetOptions(merge: true));

    await docRef.collection('slots').doc(timeframeController.text).set({
      'tasks': FieldValue.arrayUnion([
        {'name': taskController.text, 'completed': false}
      ])
    }, SetOptions(merge: true));

    taskController.clear();
  }
  Future<void> _toggleTask(String day, String slot, int index, bool newValue, List<dynamic> currentTasks) async {
    currentTasks[index]['completed'] = newValue;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(day)
        .collection('slots')
        .doc(slot)
        .set({'tasks': currentTasks});
  }

  Future<void> _deleteTask(String day, String slot, int index, List<dynamic> currentTasks) async {
    currentTasks.removeAt(index);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(day)
        .collection('slots')
        .doc(slot)
        .set({'tasks': currentTasks});
  }