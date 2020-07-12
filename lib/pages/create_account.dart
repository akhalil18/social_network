import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttershare/widgets/header.dart';

class CreateAccount extends StatefulWidget {
  static const routeId = '/create-account';
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _formKey = GlobalKey<FormState>();
  final _scafoldKey = GlobalKey<ScaffoldState>();

  String _username;

  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      key: _scafoldKey,
      appBar:
          header(context, title: 'Create your account', removeBackButton: true),
      body: ListView(
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(top: 25.0, left: 15.0, right: 15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Text(
                    'Create a user name',
                    style: TextStyle(fontSize: 25.0),
                  ),
                ),
                SizedBox(height: 16.0),
                Form(
                  key: _formKey,
                  autovalidate: true,
                  child: TextFormField(
                    validator: (val) {
                      if (val.trim().length < 3 || val.isEmpty) {
                        return 'Username is too short';
                      } else if (val.trim().length > 12) {
                        return 'Username is too long';
                      } else
                        return null;
                    },
                    onSaved: (val) {
                      _username = val;
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Username',
                      labelStyle: TextStyle(fontSize: 15.0),
                      hintText: 'Username must be at least 3 characters',
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                RaisedButton(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onPressed: _submit,
                  color: Theme.of(context).accentColor,
                  textColor: Colors.white,
                  child: Text(
                    'Submit',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _submit() {
    final _formstate = _formKey.currentState;

    if (_formstate.validate()) {
      _formstate.save();
      SnackBar snackBar = SnackBar(content: Text('Welcome $_username !'));
      _scafoldKey.currentState.showSnackBar(snackBar);

      Timer(Duration(seconds: 2), () {
        Navigator.pop(context, _username);
      });
    }
  }
}
