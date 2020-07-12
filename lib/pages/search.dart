import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/user.dart';
import '../widgets/progress.dart';
import 'home.dart';
import 'profile.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> with AutomaticKeepAliveClientMixin {
  Future<QuerySnapshot> searchResult;

  TextEditingController searcController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
      appBar: buildSearchBar(),
      body: searchResult == null
          ? buildNoUsersBody(context)
          : buildSearchResult(),
    );
  }

  AppBar buildSearchBar() {
    return AppBar(
      backgroundColor: Colors.white,
      title: TextField(
        controller: searcController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search for a user...',
          filled: true,
          prefixIcon: Icon(
            Icons.account_box,
            size: 28.0,
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              searcController.clear();
            },
          ),
        ),
        onSubmitted: handleSearch,
      ),
    );
  }

  void handleSearch(String value) {
    Future<QuerySnapshot> users = userRef
        .where("displayName", isGreaterThanOrEqualTo: value)
        .getDocuments();
    setState(() {
      searchResult = users;
    });
  }

  Container buildNoUsersBody(BuildContext context) {
    final screenOrientation = MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/search.svg',
              height: screenOrientation == Orientation.portrait ? 300 : 180,
            ),
            Text(
              'Find users',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: screenOrientation == Orientation.portrait ? 50.0 : 30,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildSearchResult() {
    return FutureBuilder<QuerySnapshot>(
      future: searchResult,
      builder: (ctx, snapShot) {
        if (!snapShot.hasData) {
          return circularProgress();
        }
        return ListView.separated(
          separatorBuilder: (context, i) => Divider(
            height: 2.0,
            color: Colors.white54,
          ),
          itemCount: snapShot.data.documents.length,
          itemBuilder: (context, i) {
            final doc = snapShot.data.documents[i];
            final user = User.fromDocument(doc);
            return UserResult(user);
          },
        );
      },
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

class UserResult extends StatelessWidget {
  final User user;
  UserResult(this.user);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.6),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Profile(profileId: user.id),
          ),
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.grey,
          backgroundImage: CachedNetworkImageProvider(user.photoUrl),
        ),
        title: Text(
          user.displayName,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          user.username,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
