import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../widgets/header.dart';
import '../widgets/post.dart';
import '../widgets/progress.dart';
import 'home.dart';

class PostScreen extends StatelessWidget {
  final String postId;
  final String userId;
  PostScreen({this.postId, this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Post>(
      future: featchPost(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        final post = snapshot.data;
        return Scaffold(
          appBar: header(context, title: post.description),
          body: ListView(
            children: <Widget>[
              Container(child: post),
            ],
          ),
        );
      },
    );
  }

  Future<Post> featchPost() async {
    DocumentSnapshot snapshot = await postRef
        .document(userId)
        .collection('userPosts')
        .document(postId)
        .get();
    Post post = Post.fromDocumnet(snapshot);
    return post;
  }
}
