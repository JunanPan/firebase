
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chatdetailsscreen.dart';
import 'package:rxdart/rxdart.dart';

final _firestore = FirebaseFirestore.instance;
User? loggedInUser;

class ChatListScreen extends StatefulWidget {
  static const String id = 'chat_list_screen';

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: loggedInUser != null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ChatListStream(),
          ],
        )
            : Center(
          child: CircularProgressIndicator(
            backgroundColor: Colors.lightBlueAccent,
          ),
        ),
      ),
    );
  }
}

class ChatListStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chatStream = _firestore
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs);

    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: chatStream,
      initialData: [],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }

        final messages = snapshot.data ?? [];
        Set<String> itemNames = Set<String>();
        Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> lastMessages = {};

        for (final message in messages) {
          if ((message['sender'] == loggedInUser!.uid || message['receiver'] == loggedInUser!.uid) &&
              !itemNames.contains(message['item'])) {
            itemNames.add(message['item']);
            lastMessages[message['item']] = message;
          }
        }

        if (itemNames.isEmpty) {
          return Expanded(
            child: Center(
              child: Text("No chats available"),
            ),
          );
        }

        return Column(
          children: itemNames.map((itemName) {
            final message = lastMessages[itemName];
            return ChatListItem(
              key: ValueKey(itemName),
              itemName: itemName,
              receiverUid: loggedInUser!.uid == message!['sender'] ? message['receiver'] : message['sender'],
              text: message['text'],
            );
          }).toList(),
        );
      },
    );
  }
}



class ChatListItem extends StatelessWidget {
  final String itemName;
  final String receiverUid;
  final String text;
  const ChatListItem({
    Key? key,
    required this.itemName,
    required this.receiverUid,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatDetailsScreen(
                  accepterUid: receiverUid, itemName: itemName,
                ),
          ),
        );
      },
      child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _firestore.collection('users').doc(receiverUid).get(),
        builder: (BuildContext context,
            AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
            return ListTile(
              title: Text("Loading..."),
              subtitle: Text("Loading..."),
            );
          } else {
            return ListTile(
              title: Text("Chat for $itemName"),
              subtitle: Text("Last message: $text"),
            );

          }
        },
      ),
    );
  }
}