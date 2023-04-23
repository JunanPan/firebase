import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'itemdetailspage.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final FirebaseAuth _auth = FirebaseAuth.instance;

class ItemCard extends StatelessWidget {
  final String uid;
  final String community;
  final String itemName;
  final double price;
  final String itemAddress;
  final String description;
  final String itemPic;
  final String itemType;
  final Timestamp timestamp;

  ItemCard({
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailsPage(
              uid: uid,
              community: community,
              itemName: itemName,
              price: price,
              itemAddress: itemAddress,
              description: description,
              itemPic: itemPic,
              itemType: itemType,
              timestamp: timestamp.toDate().toString(),
            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                itemName,
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Community: $community'),
              Text('Type: $itemType'),
              Text('Address: $itemAddress'),
              Text('Posted at: ${timestamp.toDate()}'),
              SizedBox(height: 8),
              Text('Price: \$$price'),
              SizedBox(height: 8),
              Text('Description: $description'),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                child: Image.memory(
                  base64Decode(itemPic),
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Enter item name or description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: SearchItemsStream(searchQuery: _searchQuery),
          ),
        ],
      ),
    );
  }
}

class SearchItemsStream extends StatelessWidget {
  final String searchQuery;

  SearchItemsStream({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection('items').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        final items = snapshot.data!.docs;
        List<ItemCard> itemCards = [];

        for (var item in items) {
          if (searchQuery.isEmpty) {
            itemCards.add(ItemCard(
              uid: item['uid'] as String,
              community: item['community'] as String,
              itemName: item['item_name'] as String,
              price: (item['price'] is int) ? item['price'].toDouble() : item['price'] as double,

              itemAddress: item['item_address'] as String,
              description: item['description'] as String,
              itemPic: item['item_pic'] as String,
              itemType: item['item_type'] as String,
              timestamp: item['timestamp'] as Timestamp,
            ));
          } else {
            List<String> searchTerms = searchQuery.toLowerCase().split(RegExp(r'\s+'));
            bool match = searchTerms.every((term) =>
            item['item_name'].toString().toLowerCase().contains(term) ||
                item['description'].toString().toLowerCase().contains(term) ||
                item['item_address'].toString().toLowerCase().contains(term) ||
                item['item_type'].toString().toLowerCase().contains(term));
            if (match) {
              itemCards.add(ItemCard(
                uid: item['uid'] as String,
                community: item['community'] as String,
                itemName: item['item_name'] as String,
                price: (item['price'] is int) ? item['price'].toDouble() : item['price'] as double,
                itemAddress: item['item_address'] as String,
                description: item['description'] as String,
                itemPic: item['item_pic'] as String,
                itemType: item['item_type'] as String,
                timestamp: item['timestamp'] as Timestamp,
              ));
            }
          }
        }
        return ListView(children: itemCards);
      },
    );
  }
}

