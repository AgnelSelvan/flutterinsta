import 'dart:async';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_insta/models/user.dart';
import 'package:flutter_insta/pages/activity_feed.dart';
import 'package:flutter_insta/pages/comments.dart';
import 'package:flutter_insta/pages/home.dart';
import 'package:flutter_insta/widgets/custom_image.dart';
import 'package:flutter_insta/widgets/progress.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;

  Post({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
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

  int getLikeCoint(likes) {
    if (likes == null) {
      return 0;
    }
    int count = 0;
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
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
        likeCount: getLikeCoint(this.likes),
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
  int likeCount;
  Map likes;
  bool isLiked;

  _PostState({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
    this.likeCount,
  });

  buildPostHeader() {
    return FutureBuilder(
      future: userRef.document(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: Text(
              user.username,
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
          subtitle: Text(location),
          trailing: IconButton(
            onPressed: () => print("deleting post"),
            icon: Icon(Icons.more_vert),
          ),
        );
      },
    );
  }

  handleLikePost(){
    bool _isLiked = likes[currentUserId] == true;
    if(_isLiked){
      postRef
        .document(ownerId)
        .collection('userPosts')
        .document(postId)
        .updateData({'likes.$currentUserId': false});
      removeLikeFromoActivityFeed();
      setState(() {
        likeCount -= 1;
        isLiked = false;
        likes[currentUserId] = false;
      });
    }
    else if(!_isLiked){
      postRef
      .document(ownerId)
      .collection('userPosts')
      .document(postId) 
      .updateData({'likes.$currentUserId': true});
      addLikeToActivityFeed();
      setState(() {
        likeCount += 1;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), (){
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  removeLikeFromoActivityFeed(){
    bool isNotPostOwner = currentUserId != ownerId;
    if(isNotPostOwner){
      ActivityFeedRef
        .document(ownerId)
        .collection("feedItems")
        .document(postId)
        .get()
        .then((doc){
          if(doc.exists){
            doc.reference.delete();
          }
        });
    }
  }

  addLikeToActivityFeed(){
    bool isNotPostOwner = currentUserId != ownerId;
    if(isNotPostOwner){

      ActivityFeedRef
        .document(ownerId)
        .collection("feedItems")
        .document(postId)
        .setData({
          "type": "like",
          "username": currentUser.username,
          "userId": currentUser.id,
          "userProfileImg": currentUser.photoUrl,
          "postId": postId,
          "mediaUrl": mediaUrl,
          "timestamp": timestamp,
        });
    }
  }
 
  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(mediaUrl),
          showHeart 
            ?  Animator(
              duration: Duration(milliseconds: 300),
              tween: Tween(begin: 0.8, end: 1.4),
              curve: Curves.elasticOut,
              cycles: 0,
              builder: (anim) => Transform.scale(
                scale: anim.value,
                child: Icon(
                  Icons.favorite,
                  size: 80,
                  color: Colors.redAccent
                ),
              ),
            )
          : Text('')

          // showHeart ? Icon(Icons.favorite, size: 80.0, color: Colors.redAccent,) : Text(""),
        ],
      ),
    );
  }

  buildPostFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 40.0, left: 20.0),
              ),
              GestureDetector(
                onTap: handleLikePost,
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 28.0,
                  color: Colors.pink,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: 20.0),
              ),
              GestureDetector(
                onTap: () => showComments(
                  context,
                  postId: postId,
                  ownerId: ownerId,
                  mediaUrl: mediaUrl,
                ),
                child: Icon(
                  Icons.chat,
                  size: 28.0,
                  color: Theme.of(context).primaryColor,
                ),
              )
            ],
          ),
          Row(
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(left: 20.0),
                child: Text(
                  "$likeCount likes",
                  style:
                      TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(left: 20.0),
                child: Text(
                  "$username",
                  style:
                      TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(description),
              )
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
      ],
    );
  }
}

showComments(BuildContext context, {String postId, String ownerId,
String mediaUrl}){
  Navigator.push(context, MaterialPageRoute(builder: (context){
    return Comments(
      postId: postId,
      postOwnerId: ownerId,
      postMediaUrl: mediaUrl
    );
  }));
}