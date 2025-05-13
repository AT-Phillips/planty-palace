import 'package:flutter/material.dart';

class MyPlantsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Plants'),
      ),
      body: Center(
        child: Text(
          'Welcome to Planty Palace 🌱',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
