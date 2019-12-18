import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_insta/models/user.dart';
import 'package:flutter_insta/pages/edit_profile.dart';
import 'package:flutter_insta/widgets/header.dart';
import 'package:flutter_insta/widgets/post.dart';
import 'package:flutter_insta/widgets/post_tile.dart';
import 'package:flutter_insta/widgets/progress.dart';
import 'package:flutter_svg/svg.dart';
import './home.dart';

class Profile extends StatefulWidget {
  final String profileId;
  Profile({this.profileId});
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currentUserId = currentUser?.id;
  bool isLoading = false;
  bool isFollowing = false;
  int postCount = 0;
  int followersCount = 0;
  int followingCount = 0;
  String postOrientation = "grid";
  List<Post> posts = [];

  @override
  void initState() { 
    super.initState();
    getProfilePosts();
    checkIfFollowing();
    getFollowers();
    getFollowing();
  }

  checkIfFollowing() async {
    DocumentSnapshot doc = await followersRef
      .document(widget.profileId)
      .collection('userFollowers')
      .document(currentUserId)
      .get();
    
    setState(() {
      isFollowing = doc.exists;
    });
  }

  getFollowers() async {
    QuerySnapshot snapshot = await followersRef
      .document(widget.profileId)
      .collection('userFollowers')
      .getDocuments();

    setState(() {
      print(snapshot.documents.length);
      followersCount = snapshot.documents.length;
      print(followersCount);
    });
  }
  getFollowing() async{
     QuerySnapshot snapshot =  await followingRef
      .document(widget.profileId)
      .collection("userFollowing")
      .getDocuments();
    
    setState(() {
      followingCount = snapshot.documents.length;
    });
  }

  getProfilePosts() async {
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
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        )
      ],
    );
  }

  editProfile(){
    Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfile(currentUserId: currentUserId)));

  }

  Container buildButton({String text, Function function}){
    return Container(
      padding: EdgeInsets.only(top: 2),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: 200,
          height: 27,
          child: Text(
            text,
            style: TextStyle(
              color: isFollowing ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFollowing ? Colors.white : Theme.of(context).primaryColor,
            border: Border.all(
              color:  Theme.of(context).primaryColor
            ),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }

  buildProfileButton() {
    bool isProfileOwner = currentUserId == widget.profileId;
    if(isProfileOwner){
      return buildButton(text: "Edit Profile", function: editProfile);
    }
    else if(isFollowing){
      return buildButton(text: "Unfollow", function: handleUnfollowUser);
    }
    else if(!isFollowing){
      return buildButton(text: "Follow", function: handleFollowUser);
    }
  }
  handleUnfollowUser(){
    setState(() {
      isFollowing = false;
    });
    followersRef
      .document(widget.profileId)
      .collection('userFollowers')
      .document(currentUserId)
      .get().then((doc) {
        if(doc.exists){
          doc.reference.delete();
        }
      });
    followingRef
      .document(currentUserId)
      .collection("userFollowing")
      .document(widget.profileId)
      .get().then((doc) {
        if(doc.exists){
          doc.reference.delete();
        }
      });
    ActivityFeedRef
      .document(widget.profileId)
      .collection('feedItems')
      .document(currentUserId)
      .get().then((doc) {
        if(doc.exists){
          doc.reference.delete();
        }
      }) ;
  }
  handleFollowUser(){
    setState(() {
      isFollowing = true;
    });
    followersRef
      .document(widget.profileId)
      .collection('userFollowers')
      .document(currentUserId)
      .setData({});
    followingRef
      .document(currentUserId)
      .collection("userFollowing")
      .document(widget.profileId)
      .setData({});
    ActivityFeedRef
      .document(widget.profileId)
      .collection('feedItems')
      .document(currentUserId)
      .setData({
        "type": "follow",
        "ownerId": widget.profileId,
        "username": currentUser.username,
        "userId": currentUserId,
        "userProfileImg": currentUser.photoUrl,
        "timestamp": timestamp,
      });
    
  }

  buildProfileHeader() {
    return FutureBuilder(
        future: userRef.document(widget.profileId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          User user = User.fromDocument(snapshot.data);
          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey,
                      backgroundImage:
                          CachedNetworkImageProvider(user.photoUrl),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              buildCountColumn("Posts", postCount),
                              buildCountColumn("followers", followersCount),
                              buildCountColumn("following", followingCount)
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              buildProfileButton(),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 12),  
                  child: Text(
                    user.username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16
                    ),
                  ),
                )   ,
               Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 5),
                  child: Text(
                    user.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14

                    ),
                  ),
                ),             
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 2),
                  child: Text(user.bio),
                )
              ],
            ),
          );
        });
  }
  buildProfilePosts(){
    if(isLoading){
      return circularProgress();
    }
    else if(posts.isEmpty){
      return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset('assets/images/no_content.svg', height: 150,),
          Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text(
                "No Posts",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 35.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
          )
        ],
      ),
    );
    }
    else if(postOrientation == "grid"){

      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(GridTile(child: PostTile(post),));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    }
    else if(postOrientation == "list"){ 
      return Column(children: posts);
    }
  }
  
  setOrientation(String postOrientation){
    setState(() {
      this.postOrientation = postOrientation;
    });
  }

  buildTooglePostOrientation(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          onPressed: () => setOrientation("grid"),
          icon: Icon(Icons.grid_on),
          color: postOrientation == "grid" ? Theme.of(context).primaryColor : Colors.grey,
        ),
        IconButton(
          onPressed: () => setOrientation("list"),
          icon: Icon(Icons.list),
          color: postOrientation == "list" ? Theme.of(context).primaryColor : Colors.grey,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Profile"),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          Divider(),
          buildTooglePostOrientation(),
          Divider(
            height: 0.0,
          ),
          buildProfilePosts(),
        ],
      ),
    );
    ;
  }
}
