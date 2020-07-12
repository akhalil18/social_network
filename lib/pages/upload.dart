import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as Im;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/user.dart';
import '../widgets/progress.dart';
import 'home.dart';

class Upload extends StatefulWidget {
  final User currentUser;

  Upload({this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload>
    with AutomaticKeepAliveClientMixin<Upload> {
  File _pickedImage;
  bool isUploading = false;
  String postId = Uuid().v4();

  TextEditingController captionController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final screenOrientation = MediaQuery.of(context).orientation;

    return _pickedImage == null
        ? buildSplashScreen(context, screenOrientation)
        : buildUploadScreen();
  }

  Container buildSplashScreen(
      BuildContext context, Orientation screenOrientation) {
    return Container(
      color: Theme.of(context).accentColor.withOpacity(0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset(
            'assets/images/upload.svg',
            height: screenOrientation == Orientation.portrait ? 260.0 : 180,
          ),
          SizedBox(height: 20.0),
          RaisedButton(
            onPressed: () => selectImage(context),
            color: Colors.deepOrange,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
            child: Text(
              'Upload Image',
              style: TextStyle(
                color: Colors.white,
                fontSize: screenOrientation == Orientation.portrait ? 22.0 : 18,
              ),
            ),
          )
        ],
      ),
    );
  }

  selectImage(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Create Post'),
        children: <Widget>[
          SimpleDialogOption(
            onPressed: () => pickImage(ImageSource.camera),
            child: Text('Take a Photo'),
          ),
          SimpleDialogOption(
            onPressed: () => pickImage(ImageSource.gallery),
            child: Text('upload a Photo'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.red),
            ),
          )
        ],
      ),
    );
  }

  pickImage(ImageSource source) async {
    Navigator.of(context).pop();

    final _picker = ImagePicker();
    final pickedImage = await _picker.getImage(
      source: source,
      maxWidth: 960,
      maxHeight: 675,
    );
    if (pickedImage == null) {
      return;
    }
    setState(() {
      _pickedImage = File(pickedImage.path);
    });
  }

  Scaffold buildUploadScreen() {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white70,
        title: Text('Add Post', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            setState(() {
              _pickedImage = null;
            });
          },
        ),
        actions: <Widget>[
          FlatButton(
            onPressed: isUploading ? null : handleSubmit,
            child: Text(
              "Post",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          if (isUploading) linearProgress(),

          // Image
          Container(
            height: 220.0,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(_pickedImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 10.0),

          // Caption textfield
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget.currentUser.photoUrl),
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: 'Write a caption...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),

          // Location textfield
          ListTile(
            leading: Icon(
              Icons.pin_drop,
              color: Colors.orange,
              size: 35.0,
            ),
            title: Container(
              width: 250,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: 'Where was this photo taken?',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // CurrentLocation button
          Container(
            width: 200.0,
            height: 100.0,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              onPressed: getUserLocation,
              color: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              icon: Icon(Icons.my_location, color: Colors.white),
              label: Text(
                'Current location',
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }

  void handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    await compressImage();
    String mediaUrl = await uploadImage(_pickedImage);
    await createPostInFirestore(
      mediaUrl: mediaUrl,
      description: captionController.text,
      location: locationController.text,
    );

    captionController.clear();
    locationController.clear();
    setState(() {
      _pickedImage = null;
      isUploading = false;
    });
  }

  Future<void> compressImage() async {
    final temDir = await getTemporaryDirectory();
    final path = temDir.path;
    Im.Image imageFile = Im.decodeImage(_pickedImage.readAsBytesSync());

    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 85));

    setState(() {
      _pickedImage = compressedImageFile;
    });
  }

  Future<String> uploadImage(File pickedImage) async {
    StorageUploadTask uploadTask =
        storageRef.child('post_$postId.jpg').putFile(pickedImage);

    StorageTaskSnapshot storageSnapshot = await uploadTask.onComplete;
    String downloadUrl = await storageSnapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  Future<void> createPostInFirestore(
      {String mediaUrl, String location, String description}) async {
    await postRef
        .document(widget.currentUser.id)
        .collection("userPosts")
        .document(postId)
        .setData({
      "postId": postId,
      "ownerId": widget.currentUser.id,
      "username": widget.currentUser.username,
      "mediaUrl": mediaUrl,
      "description": description,
      "location": location,
      "timestamp": DateTime.now(),
      "likes": {},
    });
  }

  Future<void> getUserLocation() async {
    Position currentPosition = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks =
        await Geolocator().placemarkFromPosition(currentPosition);
    Placemark placemark = placemarks[0];

    String completeAdress =
        "${placemark.subThoroughfare} ${placemark.thoroughfare}, ${placemark.subLocality} ${placemark.locality}, ${placemark.subAdministrativeArea} ${placemark.administrativeArea}, ${placemark.postalCode} ${placemark.country}";
    print(completeAdress);

    String formattedAdress = "${placemark.locality}, ${placemark.country}";

    locationController.text = formattedAdress;
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
