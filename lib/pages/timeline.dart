import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/pages/search.dart';

import '../models/user.dart';
import '../widgets/header.dart';
import '../widgets/post.dart';
import '../widgets/progress.dart';
import 'home.dart';

final userRef = Firestore.instance.collection('users');

class Timeline extends StatefulWidget {
  final User currentUser;
  Timeline({this.currentUser});

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post> posts;
  List<String> followingList = [];

  @override
  void initState() {
    super.initState();
    getTimeline();
    getFollowingUsers();
  }

  Future<void> getTimeline() async {
    QuerySnapshot snapshot = await timelineRef
        .document(widget.currentUser.id)
        .collection('timelinePosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();

    List<Post> posts =
        snapshot.documents.map((d) => Post.fromDocumnet(d)).toList();

    setState(() {
      this.posts = posts;
    });
  }

  Future<void> getFollowingUsers() async {
    QuerySnapshot snapshot = await followingRef
        .document(currentUser.id)
        .collection('userFollowing')
        .getDocuments();

    setState(() {});
    followingList = snapshot.documents.map((d) => d.documentID).toList();
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, isAppTitle: true),
      body: RefreshIndicator(
        onRefresh: getTimeline,
        child: buildTimeline(),
      ),
    );
  }

  Widget buildTimeline() {
    if (posts == null) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return buildUserToFollow();
    } else {
      return ListView(children: posts);
    }
  }

  buildUserToFollow() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          userRef.orderBy('timestamp', descending: true).limit(30).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }

        List<UserResult> userResults = [];

        snapshot.data.documents.forEach((doc) {
          User user = User.fromDocument(doc);
          final isAuthUser = currentUser.id == user.id;
          final isFollowingUser = followingList.contains(user.id);

          // remove auth user from recommende list
          if (isAuthUser) {
            return;
          } else if (isFollowingUser) {
            return;
          } else {
            userResults.add(
              UserResult(user),
            );
          }
        });

        return Container(
          color: Theme.of(context).accentColor.withOpacity(0.2),
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.person_add,
                      color: Theme.of(context).primaryColor,
                      size: 25.0,
                    ),
                    SizedBox(width: 8.0),
                    Text(
                      'Users To Follow',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 25.0,
                      ),
                    )
                  ],
                ),
              ),
              Column(children: userResults),
            ],
          ),
        );
      },
    );
  }
}
