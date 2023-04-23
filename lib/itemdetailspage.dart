import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chatdetailsscreen.dart';

import 'package:firebase_auth/firebase_auth.dart';

class ItemDetailsPage extends StatefulWidget {
  final String uid;
  final String community;
  final String itemName;
  final double price;
  final String itemAddress;
  final String description;
  final String itemPic;
  final String itemType;
  final String timestamp;

  ItemDetailsPage({
    required this.uid,
    required this.community,
    required this.itemName,
    required this.price,
    required this.itemAddress,
    required this.description,
    required this.itemPic,
    required this.itemType,
    required this.timestamp,
  });

  @override
  _ItemDetailsPageState createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Item Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              widget.itemName,
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Community: ${widget.community}'),
            Text('Type: ${widget.itemType}'),
            Text('Address: ${widget.itemAddress}'),
            Text('Posted at: ${widget.timestamp}'),
            SizedBox(height: 8),
            Text('Price: \$${widget.price}'),
            SizedBox(height: 8),
            Text('Description: ${widget.description}'),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              child: Image.memory(
                base64Decode(widget.itemPic),
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // go to chatdetailspage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailsScreen(
                      accepterUid: widget.uid,
                      itemName: widget.itemName,
                    ),
                  ),
                );
              },
              child: Text('Chat with Seller'),
            ),
          ],
        ),
      ),
    );
  }
}
