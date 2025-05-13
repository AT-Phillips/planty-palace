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
          'Here you can see and manage your plants!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
