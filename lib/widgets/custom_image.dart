import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

CachedNetworkImage cachedNetworkImage(BuildContext context, String mediaUrl) {
  return CachedNetworkImage(
    imageUrl: mediaUrl,
    fit: BoxFit.cover,
    placeholder: (context, url) => Center(child: CircularProgressIndicator()),
    errorWidget: (context, url, error) => Icon(Icons.error),
  );
}
