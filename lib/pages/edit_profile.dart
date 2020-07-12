import 'package:cached_network_image/cached_network_image.dart';
import "package:flutter/material.dart";

import '../models/user.dart';
import '../widgets/progress.dart';
import 'home.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;
  EditProfile({@required this.currentUserId});
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  TextEditingController _displayNameController = TextEditingController();
  TextEditingController _bioController = TextEditingController();
  bool _isLoading = false;
  User _currentUser;
  bool _displayNameValid = true;
  bool _bioValid = true;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    getUser();
  }

  void getUser() async {
    setState(() {
      _isLoading = true;
    });

    final userSnapshot = await userRef.document(widget.currentUserId).get();
    _currentUser = User.fromDocument(userSnapshot);
    _displayNameController.text = _currentUser.displayName;
    _bioController.text = _currentUser.bio;

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Edit Profile",
          style: TextStyle(color: Colors.black),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.done,
              color: Colors.green,
              size: 30,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: _isLoading
          ? circularProgress()
          : ListView(
              children: <Widget>[
                Container(
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: CircleAvatar(
                          radius: 50.0,
                          backgroundColor: Colors.grey,
                          backgroundImage:
                              CachedNetworkImageProvider(_currentUser.photoUrl),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: <Widget>[
                            buildDisplayNameField(),
                            buildBioField(),
                          ],
                        ),
                      ),
                      RaisedButton(
                        onPressed: updateProfileData,
                        child: Text(
                          "Update Profile",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: FlatButton.icon(
                          onPressed: logout,
                          icon: Icon(
                            Icons.exit_to_app,
                            color: Colors.red,
                          ),
                          label: Text(
                            'Logout',
                            style: TextStyle(color: Colors.red, fontSize: 20.0),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Column buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Text(
            'Display Name',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: _displayNameController,
          decoration: InputDecoration(
            hintText: 'Update Display Name',
            errorText: _displayNameValid ? null : 'Display Name too short',
          ),
        ),
      ],
    );
  }

  Column buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Text(
            'Bio',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: _bioController,
          decoration: InputDecoration(
            hintText: 'Update Bio',
            errorText: _bioValid ? null : 'Bio is too long',
          ),
        ),
      ],
    );
  }

  void updateProfileData() {
    if (_displayNameController.text.trim().length < 3 ||
        _displayNameController.text.isEmpty) {
      setState(() {
        _displayNameValid = false;
      });
    } else {
      setState(() {
        _displayNameValid = true;
      });
    }

    if (_bioController.text.trim().length > 100 ||
        _bioController.text.isEmpty) {
      setState(() {
        _bioValid = false;
      });
    } else {
      _bioValid = true;
    }

    if (_displayNameValid && _bioValid) {
      userRef.document(widget.currentUserId).updateData({
        "displayName": _displayNameController.text,
        "bio": _bioController.text
      });
    }
    final snackbar = SnackBar(content: Text('Profile Updated'));
    _scaffoldKey.currentState.showSnackBar(snackbar);
  }

  Future<void> logout() async {
    await googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => Home()));
  }
}
