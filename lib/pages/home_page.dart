import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cleanhnote/provider/auth_provider.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('anda berhasil masuk'),
            SizedBox(height: 20),
            Text('Welcome, ${authProvider.currentUser.name}!'),
          ],
        ),
      ),
    );
  }
}
