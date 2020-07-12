import 'package:flutter/material.dart';

import '../pages/post_screen.dart';
import 'custom_image.dart';
import 'post.dart';

class PostTile extends StatelessWidget {
  final Post post;
  PostTile(this.post);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PostScreen(postId: post.postId, userId: post.ownerId),
        ),
      ),
      child: cachedNetworkImage(context, post.mediaUrl),
    );
  }
}
