import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/user.dart';
import '../pages/comments.dart';
import '../pages/home.dart';
import '../pages/profile.dart';
import 'custom_image.dart';
import 'progress.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final Map likes;

  Post({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
  });

  factory Post.fromDocumnet(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      username: doc['username'],
      location: doc['location'],
      description: doc['description'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
    );
  }

  int getLikesCount(likes) {
    // if no likes return 0
    if (likes == null) {
      return 0;
    }

    int count = 0;
    // if the key  value ezual to tue, add like
    likes.values.forEach((value) {
      if (value == true) {
        count++;
      }
    });

    return count;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerId: this.ownerId,
        username: this.username,
        location: this.location,
        description: this.description,
        mediaUrl: this.mediaUrl,
        likes: this.likes,
        likesCount: getLikesCount(this.likes),
      );
}

class _PostState extends State<Post> {
  final String currentUserId = currentUser?.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  bool showHeart = false;
  Map likes;
  int likesCount;
  bool isLiked;

  _PostState({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
    this.likesCount,
  });

  @override
  void initState() {
    isLiked = likes[currentUserId] == true;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
      ],
    );
  }

  buildPostHeader() {
    return FutureBuilder(
      future: userRef.document(ownerId).get(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }

        final user = User.fromDocument(snapshot.data);
        bool isPostOwner = currentUserId == ownerId;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Profile(profileId: user.id),
              ),
            ),
            child: Text(
              user.username,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(location),
          trailing: isPostOwner
              ? IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () => handleDeletepost(context),
                )
              : null,
        );
      },
    );
  }

  handleDeletepost(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Remove this post?'),
        children: <Widget>[
          SimpleDialogOption(
            onPressed: () {
              Navigator.of(context).pop();
              deletePost();
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          )
        ],
      ),
    );
  }

  void deletePost() {
    // Delete post
    postRef.document(ownerId).collection('userPosts').document(postId).delete();

    // Delete post uploaded image
    storageRef.child("post_$postId.jpg").delete();

    //Delete activity feed notification
    activityFeedRef
        .document(ownerId)
        .collection('feedItems')
        .where('postId', isEqualTo: postId)
        .getDocuments()
        .then(
          (snapshot) => snapshot.documents.forEach((doc) {
            if (doc.exists) {
              doc.reference.delete();
            }
          }),
        );

    // delete all comments
    commentRef.document(postId).collection('comments').getDocuments().then(
          (snapshot) => snapshot.documents.forEach((doc) {
            if (doc.exists) {
              doc.reference.delete();
            }
          }),
        );
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1.5,
            child: Container(
              child: cachedNetworkImage(context, mediaUrl),
            ),
          ),
          if (showHeart)
            Animator(
              duration: Duration(milliseconds: 300),
              tween: Tween(begin: 0.8, end: 1.4),
              cycles: 0,
              curve: Curves.easeInOut,
              builder: (_, state, widget) => Transform.scale(
                scale: state.value,
                child: Icon(
                  Icons.favorite,
                  size: 80.0,
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }

  buildPostFooter() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, left: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              GestureDetector(
                onTap: handleLikePost,
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: Colors.pink,
                  size: 28.0,
                ),
              ),
              SizedBox(width: 20),
              GestureDetector(
                onTap: () => showComments(
                  context,
                  ownerId: ownerId,
                  mediaUrl: mediaUrl,
                  postId: postId,
                ),
                child: Icon(
                  Icons.chat,
                  color: Colors.blue[900],
                  size: 28.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Row(
            children: <Widget>[
              Container(
                child: Text(
                  '$likesCount likes',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Row(
            children: <Widget>[
              Container(
                child: Text(
                  '$username',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(child: Text(description)),
            ],
          ),
          Divider(),
        ],
      ),
    );
  }

  void handleLikePost() {
    bool _isLiked = likes[currentUserId] == true;

    if (_isLiked) {
      postRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': false});

      removeLikeFromActivityFeed();

      setState(() {
        likesCount--;
        isLiked = false;
        likes[currentUserId] = false;
      });
    } else if (!isLiked) {
      postRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': true});

      addLikeToActivityFeed();

      setState(() {
        likesCount++;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Future.delayed(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  void showComments(BuildContext context,
      {String postId, String ownerId, String mediaUrl}) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Comments(
                postId: postId,
                postOwnerId: ownerId,
                postMediaUrl: mediaUrl,
              )),
    );
  }

  void addLikeToActivityFeed() {
    bool isMyPost = currentUserId == ownerId;
    if (!isMyPost) {
      activityFeedRef
          .document(ownerId)
          .collection('feedItems')
          .document(postId)
          .setData({
        "type": "like",
        "username": currentUser.username,
        "userId": currentUser.id,
        "UserProfileImage": currentUser.photoUrl,
        "postId": postId,
        "mediaUrl": mediaUrl,
        "timestamp": DateTime.now(),
      });
    }
  }

  void removeLikeFromActivityFeed() {
    bool isMyPost = currentUserId == ownerId;
    if (!isMyPost) {
      activityFeedRef
          .document(ownerId)
          .collection('feedItems')
          .document(postId)
          .get()
          .then((value) {
        if (value.exists) {
          value.reference.delete();
        }
      });
    }
  }
}
