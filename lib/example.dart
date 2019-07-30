///
/// Copyright (C) 2019 Andrious Solutions
///
/// This program is free software; you can redistribute it and/or
/// modify it under the terms of the GNU General Public License
/// as published by the Free Software Foundation; either version 3
/// of the License, or any later version.
///
/// You may obtain a copy of the License at
///
///  http://www.apache.org/licenses/LICENSE-2.0
///
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
///
///          Created  30 Jul 2019
///
///
import 'dart:async';
import 'dart:convert' show json;

import "package:http/http.dart" as http;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:auth/Auth.dart';


void main() {
  runApp(
    new MaterialApp(
      title: 'Google Sign In',
      home: new SignInDemo(),
    ),
  );
}



class SignInDemo extends StatefulWidget {
  @override
  State createState() => new SignInDemoState();
}



class SignInDemoState extends State<SignInDemo> {
  GoogleSignInAccount _currentUser;
  String _contactText;



  @override
  void initState() {
    super.initState();

    Auth.signInSilently(
      scopes: <String>[
        'email',
        'https://www.googleapis.com/auth/contacts.readonly',
      ],
      listen:(account){
        setState(() {
          _currentUser = account;
        });
        if (_currentUser != null) {
          _handleGetContact();
        }
      },
    );
  }



  @override
  void dispose(){
    Auth.dispose();
    super.dispose();
  }



  Future<Null> _handleGetContact() async {
    setState(() {
      _contactText = "Loading contact info...";
    });
    final http.Response response = await http.get(
      'https://people.googleapis.com/v1/people/me/connections'
          '?requestMask.includeField=person.names',
      headers: await _currentUser.authHeaders,
    );
    if (response.statusCode != 200) {
      setState(() {
        _contactText = "People API gave a ${response.statusCode} "
            "response. Check logs for details.";
      });
      print('People API ${response.statusCode} response: ${response.body}');
      return;
    }
    final Map<String, dynamic> data = json.decode(response.body);
    final String namedContact = _pickFirstNamedContact(data);
    setState(() {
      if (namedContact != null) {
        _contactText = "I see you know $namedContact!";
      } else {
        _contactText = "No contacts to display.";
      }
    });
  }



  String _pickFirstNamedContact(Map<String, dynamic> data) {
    final List<dynamic> connections = data['connections'];
    final Map<String, dynamic> contact = connections?.firstWhere(
          (dynamic contact) => contact['names'] != null,
      orElse: () => null,
    );
    if (contact != null) {
      final Map<String, dynamic> name = contact['names'].firstWhere(
            (dynamic name) => name['displayName'] != null,
        orElse: () => null,
      );
      if (name != null) {
        return name['displayName'];
      }
    }
    return null;
  }



  Future<Null> _handleSignIn() async {
    await Auth.signIn();
// await _googleSignIn.signIn();
  }



  Future<Null> _handleSignOut() async {
    Auth.disconnect(); // _googleSignIn.disconnect();
  }



  Widget _buildBody() {
    if (_currentUser != null) {
      return new Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          new ListTile(
            leading: new GoogleUserCircleAvatar(
              identity: _currentUser,
            ),
            title: new Text(_currentUser.displayName),
            subtitle: new Text(_currentUser.email),
          ),
          const Text("Signed in successfully."),
          new Text(_contactText),
          new RaisedButton(
            child: const Text('SIGN OUT'),
            onPressed: _handleSignOut,
          ),
          new RaisedButton(
            child: const Text('REFRESH'),
            onPressed: _handleGetContact,
          ),
          new RaisedButton(
            child: const Text('SIGN IN'),
            onPressed: _handleSignIn,
          ),
        ],
      );
    } else {
      return new Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          const Text("You are not currently signed in."),
          new RaisedButton(
            child: const Text('SIGN IN'),
            onPressed: _handleSignIn,
          ),
        ],
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: const Text('Google Sign In'),
        ),
        body: new ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: _buildBody(),
        ));
  }
}

