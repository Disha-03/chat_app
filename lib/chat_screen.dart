import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatPartnerEmail;

  ChatScreen({required this.chatPartnerEmail});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  User? loggedInUser;
  final messageTextController = TextEditingController();
  String messageText = "";

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
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
        title: Text('Chat with ${widget.chatPartnerEmail}'),
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
      body: Column(
        children: <Widget>[
          Expanded(
            child: MessagesStream(
              loggedInUser: loggedInUser?.email ?? '',
              chatPartnerEmail: widget.chatPartnerEmail,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: messageTextController,
                    onChanged: (value) {
                      messageText = value;
                    },
                    decoration: const InputDecoration(
                      hintText: 'Enter your message...',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (messageText.isNotEmpty) {
                      messageTextController.clear();
                      FirebaseFirestore.instance.collection('messages').add({
                        'text': messageText,
                        'sender': loggedInUser!.email,
                        'receiver': widget.chatPartnerEmail,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                    }
                  },
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  final String loggedInUser;
  final String chatPartnerEmail;

  MessagesStream({required this.loggedInUser, required this.chatPartnerEmail});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .where('sender', isEqualTo: loggedInUser)
          .where('receiver', isEqualTo: chatPartnerEmail)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final senderMessages = snapshot.data!.docs;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('messages')
              .where('sender', isEqualTo: loggedInUser)
              .where('receiver', isEqualTo: chatPartnerEmail)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final senderMessages = snapshot.data!.docs;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('sender', isEqualTo: chatPartnerEmail)
                  .where('receiver', isEqualTo: loggedInUser)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final receiverMessages = snapshot.data!.docs;

                List<MessageBubble> messageBubbles = [];

                // Combine sender and receiver messages
                final allMessages = [...senderMessages, ...receiverMessages];

                // Filter out messages without a timestamp
                final messagesWithTimestamp = allMessages
                    .where((message) => message['timestamp'] != null);

                // Convert messages with timestamp to list and then sort
                final sortedMessages = messagesWithTimestamp.toList()
                  ..sort((a, b) => (b['timestamp'] as Timestamp)
                      .compareTo(a['timestamp'] as Timestamp));

                for (var message in sortedMessages) {
                  final messageText = message['text'];
                  final messageSender = message['sender'];
                  final messageReceiver = message['receiver'];
                  log("message   ${message['text']}");
                  log("message   ${message['sender']}");
                  log("message   ${message['receiver']}");
                  final messageBubble = MessageBubble(
                    sender: messageSender,
                    text: messageText,
                    isMe: loggedInUser == messageSender,
                    receiver: messageReceiver,
                  );
                  messageBubbles.add(messageBubble);
                }

                return ListView(
                  reverse: true,
                  children: messageBubbles,
                );
              },
            );
          },
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String sender;
  final String receiver;
  final String text;
  final bool isMe;

  MessageBubble({
    required this.sender,
    required this.receiver,
    required this.text,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final isLastMessage = sender == receiver;
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isMe ? Colors.lightBlueAccent : Colors.white;
    final textColor = isMe ? Colors.white : Colors.black54;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: <Widget>[
          if (!isLastMessage)
            Text(
              receiver,
              style: const TextStyle(fontSize: 12.0, color: Colors.black54),
            ),
          Material(
            borderRadius: isMe
                ? const BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                  )
                : const BorderRadius.only(
                    topRight: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                  ),
            elevation: 5.0,
            color: bubbleColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15.0,
                  color: textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
