import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'map_page.dart';
import 'dart:typed_data';

class AddItemPage extends StatefulWidget {
  @override
  _AddItemPageState createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  User? loggedInUser;
  String? itemAddress;
  String _base64Image = '';
  bool _imageSelected = false;

  String itemName = '';
  String description = '';
  String price = '';
  String itemType = '';
  String community = '';
  List<String> itemTypes = [
    'Electronics',
    'Furniture',
    'Clothing',
    'Books',
    'Shoes',
    'Sports',
    'Pet Supplies',
    'Food',
    'Other'
  ];

  List<String> communities = ['Community A', 'Community B', 'Community C'];
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    loggedInUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _pickImage() async {
    try {
      // 从相册中选择图片
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        // 将图片文件读入内存
        final Uint8List bytes = await pickedFile.readAsBytes();

        // 压缩图片
        final compressedBytes = await FlutterImageCompress.compressWithList(
          bytes,
          minHeight: 600,
          minWidth: 600,
          quality: 70,
        )!; // 使用 ! 操作符确保返回的是非空 Uint8List

        // 将字节数据转换为 Base64 编码
        final String base64Image = base64Encode(compressedBytes);
        // 更新状态以在 UI 中显示已选图片
        setState(() {
          _base64Image = base64Image;
          _imageSelected = true;
        });
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print(e);
    }
  }



  Future<void> _addItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        await _firestore.collection('items').add({
          'uid': loggedInUser!.uid,
          'community': community,
          'item_name': itemName,
          'price': double.parse(price),
          'item_address': itemAddress,
          'description': description,
          'item_type': itemType,
          'item_pic': _base64Image,
          'timestamp': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item added successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Item'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Item Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an item name';
                  }
                  return null;
                },
                onSaved: (value) {
                  itemName = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                onSaved: (value) {
                  description = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  return null;
                },
                onSaved: (value) {
                  price = value!;
                },
              ),
              GestureDetector(
                onTap: () async {
                  String? selectedAddress = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MapPage()),
                  );

                  if (selectedAddress != null) {
                    setState(() {
                      itemAddress = selectedAddress;
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Item Location'),
                    controller: TextEditingController(text: itemAddress),
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select an item location';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              ListTile(
                title: !_imageSelected
                    ? Text('No image selected.')
                    : Image.memory(
                  base64Decode(_base64Image),
                  height: 150,
                ),
                trailing: ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('Select Image'),
                ),
              ),

              DropdownButtonFormField(
                decoration: InputDecoration(labelText: 'Item Type'),
                value: itemType.isEmpty ? null : itemType,
                items: itemTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    itemType = newValue as String;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an item type';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField(
                decoration: InputDecoration(labelText: 'Community'),
                value: community.isEmpty ? null : community,
                items: communities.map((comm) {
                  return DropdownMenuItem(
                    value: comm,
                    child: Text(comm),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    community = newValue as String;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a community';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addItem,
                child: Text('Add Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }}