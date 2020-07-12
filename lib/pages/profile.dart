import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../models/user.dart';
import '../widgets/header.dart';
import '../widgets/post.dart';
import '../widgets/post_tile.dart';
import '../widgets/progress.dart';
import 'edit_profile.dart';
import 'home.dart';

enum PostView { grid, list }

class Profile extends StatefulWidget {
  final String profileId;

  Profile({this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currentUserId = currentUser?.id;
  bool isLoading = false;
  int postCount = 0;
  int followingCount = 0;
  int followersCount = 0;
  List<Post> posts = [];
  PostView _postView = PostView.grid;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();

    getProfilePost();
    getFollowers();
    getFollowing();
    checkFollowingStatue();
  }

  void getFollowers() async {
    QuerySnapshot snapshot = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .getDocuments();

    setState(() {
      followersCount = snapshot.documents.length;
    });
  }

  void getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .document(widget.profileId)
        .collection('userFollowing')
        .getDocuments();

    setState(() {
      followingCount = snapshot.documents.length;
    });
  }

  void checkFollowingStatue() async {
    DocumentSnapshot doc = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  void getProfilePost() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();

    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((d) => Post.fromDocumnet(d)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenOrientation = MediaQuery.of(context).orientation;

    return Scaffold(
      appBar: header(context, title: 'Profile'),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          Divider(),
          buildTogglePostOrientation(),
          Divider(height: 0.0),
          buildProfilePost(screenOrientation),
        ],
      ),
    );
  }

  FutureBuilder buildProfileHeader() {
    return FutureBuilder(
        future: userRef.document(widget.profileId).get(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          final user = User.fromDocument(snapshot.data);
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 40.0,
                      backgroundColor: Colors.grey,
                      backgroundImage:
                          CachedNetworkImageProvider(user.photoUrl),
                    ),
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              buildCountColumn('posts', postCount),
                              buildCountColumn('followers', followersCount),
                              buildCountColumn('following', followingCount),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              // viewing your own profile , show edit profile button
                              (currentUserId == widget.profileId)
                                  ? buildButton(
                                      text: 'Edit Profile',
                                      function: editProfile)
                                  : (isFollowing)
                                      ? buildButton(
                                          text: 'Unfollow',
                                          function: handleUnflollowUser)
                                      : buildButton(
                                          text: 'Follow',
                                          function: handleflollowUser),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 12.0),
                  child: Text(
                    user.username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 4.0),
                  child: Text(
                    user.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 2.0),
                  child: Text(
                    user.bio,
                  ),
                ),
              ],
            ),
          );
        });
  }

  Column buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Container buildButton({String text, Function function}) {
    return Container(
      margin: EdgeInsets.only(top: 4.0),
      width: 220.0,
      height: 27.0,
      child: RaisedButton(
        textColor: isFollowing ? Colors.black : Colors.white,
        color: isFollowing ? Colors.white : Colors.blue,
        onPressed: function,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        child: Text(
          text,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => EditProfile(
          currentUserId: currentUserId,
        ),
      ),
    );
  }

  buildProfilePost(Orientation screenOrientation) {
    if (isLoading) {
      return circularProgress();
    } else if (posts.isEmpty) {
      // if there is no posts yet
      return Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SvgPicture.asset(
              'assets/images/no_content.svg',
              height: screenOrientation == Orientation.portrait ? 200.0 : 150,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'No posts',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: screenOrientation == Orientation.portrait ? 22.0 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    } else if (_postView == PostView.grid) {
      List<GridTile> postTile = [];
      posts.forEach(
        (post) => postTile.add(GridTile(child: PostTile(post))),
      );
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 5.0,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: postTile,
      );
    } else if (_postView == PostView.list) {
      return Column(children: posts);
    }
  }

  Row buildTogglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.grid_on),
          color: _postView == PostView.grid
              ? Theme.of(context).primaryColor
              : Colors.grey,
          onPressed: () => setState(() {
            _postView = PostView.grid;
          }),
        ),
        IconButton(
          icon: Icon(Icons.view_list),
          color: _postView == PostView.list
              ? Theme.of(context).primaryColor
              : Colors.grey,
          onPressed: () => setState(() {
            _postView = PostView.list;
          }),
        ),
      ],
    );
  }

  void handleUnflollowUser() {
    setState(() {
      isFollowing = false;
    });

    // remove me from the other user following list
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // remove user from my following list
    followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // delete activity feed notification
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
        .delete();
  }

  void handleflollowUser() {
    setState(() {
      isFollowing = true;
    });

    // Add me to other user following list
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .setData({});

    // Add user to my following list
    followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .setData({});

    // Add activity feed notification

    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
        .setData({
      "type": "follow",
      "ownerId": widget.profileId,
      "username": currentUser.username,
      "userId": currentUserId,
      "userProfileImage": currentUser.photoUrl,
      "timestamp": DateTime.now(),
    });
  }
}
