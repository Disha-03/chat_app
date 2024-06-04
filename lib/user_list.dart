import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'login_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({Key? key}) : super(key: key);

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final _auth = FirebaseAuth.instance;
  User? loggedInUser;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print("${_auth.currentUser}");
        setState(() {
          loggedInUser = user;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Chat Partner'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _auth.signOut();
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => LoginScreen()));
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || loggedInUser == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!.docs;
          List<UserTile> userTiles = [];
          for (var user in users) {
            final userEmail = user['email'];
            if (userEmail != loggedInUser!.email) {
              final userTile = UserTile(
                email: userEmail,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatPartnerEmail: userEmail,
                      ),
                    ),
                  );
                },
              );
              userTiles.add(userTile);
            }
          }
          return ListView(
            children: userTiles.isEmpty
                ? [
                    const Center(
                        child: Padding(
                      padding:
                          EdgeInsets.only(top: 40, left: 20, right: 20),
                      child: Text(
                        "No Any Another chat Partner please Login another account also.",
                        textAlign: TextAlign.center,
                      ),
                    ))
                  ]
                : userTiles,
          );
        },
      ),
    );
  }
}

class UserTile extends StatelessWidget {
  final String email;
  final VoidCallback onTap;

  UserTile({Key? key, required this.email, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(email),
      onTap: onTap,
    );
  }
}
