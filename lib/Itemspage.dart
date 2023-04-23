import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'itemdetailspage.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'dart:typed_data';


Future<String> getDistanceToItem(String itemAddress) async {
  try {
    Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);

    final apiKey = 'AIzaSyB43pS0d30i-AkO4jZs7qUsMi0fupfzOAw';
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${currentPosition.latitude},${currentPosition.longitude}&destination=$itemAddress&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'OK') {
        return 'Distance: ${jsonResponse['routes'][0]['legs'][0]['distance']['text']}';
      } else {
        print('Error in API response: ${jsonResponse['status']}');
        return 'Address: $itemAddress';
      }
    } else {
      print('Error in API request: ${response.statusCode}');
      return 'Address: $itemAddress';
    }
  } catch (e) {
    print('Error getting location: $e');
    return 'Address: $itemAddress';
  }
}

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final FirebaseAuth _auth = FirebaseAuth.instance;

ItemCard createItemCard(QueryDocumentSnapshot<Object?> item) {
  return ItemCard(
    uid: item['uid'] as String,
    community: item['community'] as String,
    itemName: item['item_name'] as String,
    price: (item['price'] as num).toDouble(),
    itemAddress: item['item_address'] as String,
    description: item['description'] as String,
    itemPic: item['item_pic'] as String,
    itemType: item['item_type'] as String,
    timestamp: item['timestamp'] as Timestamp,
  );
}

class ItemsPage extends StatefulWidget {
  @override
  _ItemsPageState createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Items'),
        leading: SizedBox(),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _firestore.collection('users').doc(_auth.currentUser!.uid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          List<String> interests = List<String>.from(snapshot.data!['interests']);

          return ItemsStream(interests: interests);
        },
      ),
    );
  }
}

class ItemsStream extends StatelessWidget {
  final List<String> interests;

  ItemsStream({required this.interests});

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
          itemCards.add(createItemCard(item));
        }
        return ListView(children: itemCards);
      },
    );
  }
}



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
    // 解码 Base64 编码的图片
    final Uint8List decodedImage = base64Decode(itemPic);

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
              FutureBuilder<String>(
                future: getDistanceToItem(itemAddress),
                builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text('Calculating distance...');
                  } else {
                    return Text(snapshot.data ?? 'Address: $itemAddress');
                  }
                },
              ),

              Text('Posted at: ${timestamp.toDate()}'),
              SizedBox(height: 8),
              Text('Price: $price'),
              SizedBox(height: 8),
              Text('Description: $description'),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                child: Image.memory(
                  decodedImage,
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