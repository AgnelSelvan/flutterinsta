import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_insta/models/user.dart';
import 'package:flutter_insta/pages/home.dart';
import 'package:flutter_insta/pages/search.dart';
import 'package:flutter_insta/widgets/post.dart';
import 'package:flutter_insta/widgets/progress.dart';
import 'package:flutter_svg/flutter_svg.dart';
import './../widgets/header.dart';

final userRef = Firestore.instance.collection('users');

class Timeline extends StatefulWidget {
  final User currentUser;
  Timeline({this.currentUser});
  @override
  _TimelineState createState() => _TimelineState();
}


class _TimelineState extends State<Timeline> {
  List<Post> posts;
  List followingList;
  // List<dynamic> users;

  @override
  void initState() {
    // getUserById();
    // getUsers();
    // createUser();
    // updateUser();
    // deleteUser();
    super.initState();
    getTimeline();
    getFollowing();
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
      .document(currentUser.id)
      .collection('userFollowing')
      .getDocuments();
    
    setState(() {
      followingList = snapshot.documents.map((doc) => doc.documentID).toList(); 
    });
  }

  getTimeline()async{
    QuerySnapshot snapshot = await timelineRef
      .document(currentUser.id)
      .collection('timelinePosts')
      .orderBy('timestamp', descending: true) 
      .getDocuments();
    
    // QuerySnapshot snapshot = await postRef
    //   .document()
    //   .collection('userPosts')
    //   .orderBy('timestamp', descending: true)
    //   .getDocuments();

    
    List<Post> posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    print(posts.length);
    setState(() {
      this.posts = posts;
    });
  }

  // createUser(){
  //   userRef.document('akjhfdskjldsf').setData({
  //     "username": "Nesan",
  //     "isAdmin": true,
  //     "postsCount": 6
  //   });
  // }

  // updateUser() async {
  //   final doc = await userRef.document('akjhfdskjldsf').get();
  //   if(doc.exists){
  //     doc.reference.updateData({"username": "John"});
  //   }
  // }

  // deleteUser() async {
  //   final doc = await userRef.document('akjhfdskjldsf').get();
  //   if(doc.exists){
  //     doc.reference.delete();
  //   }
  // }

  // getUsers() async {
  //   final QuerySnapshot snapshot = await userRef
  //     .getDocuments();

  //     setState(() {
  //       users = snapshot.documents;
  //     });

      // snapshot.documents.forEach((DocumentSnapshot doc){
      //   print(doc.data);
      // });
  // }

  // getUserById() async{
  //   String id = "Ai3z803hsq0FcbdyfMaJ";
  //   final DocumentSnapshot doc = await userRef.document(id).get();
  //   print(doc.data)    ;
  //   print(doc.documentID);
  // }
  buildTimeline(){
    if(posts == null){
      return circularProgress();
    }
    else if(posts.isEmpty){
      return Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SvgPicture.asset('assets/images/no_timeline.svg', height: 200,),
                SizedBox(
                height: 50,
              ),
              Text("Follow to get timeline",
                textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w400,
                    fontSize: 30,
                )
              ),
              ],
            ),
          ],
        ),
      );
    }
    else{
      return ListView(children: posts,);
    }
  }
  buildUserToFollow(){
    return StreamBuilder(
      stream: userRef.orderBy('timestamp', descending: true).limit(20).snapshots(),
      builder: (context, snapshot){
        if(!snapshot.hasData){
          return circularProgress();
        }
        List<UserResult> userResults = [];
        snapshot.data.documents.forEach((doc){
          User user = User.fromDocument(doc);
          final bool isAuthUser = currentUser == user.id;
          final bool isFollowingUser = followingList.contains(user.id);
          if(isAuthUser){
            return ;
          }
          else if(isFollowingUser){
            return;
          }
          else{
            UserResult userResult = UserResult(user);
            userResults.add(userResult);
          }
        });
          return Container(
            child: Column(children: <Widget>[
              Container(
                padding: EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.person_add,
                      color: Theme.of(context).primaryColor,
                      size: 30,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Text(
                      'User to Follow',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 30
                      ),
                    )
                  ],
                ),
              ),
              Column(children: userResults,)

            ],),
          );
      },
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, isAppTitle: true),
      // body: StreamBuilder<QuerySnapshot>(
      //   stream: userRef.snapshots(),
      //   builder: (context, snapshot){
      //     if(!snapshot.hasData){
      //       return circularProgress();
      //     }
      //     final List<Text> children = snapshot.data.documents.map((doc)=> Text(doc['username'])).toList();
      //     return Container(
      //       child: ListView(
      //         children: children,
      //       ),
      //     );
      //   },
      // ),
      body: RefreshIndicator(
        onRefresh: () => getTimeline(),
        child: buildTimeline(),
      ),
    );
  }
}
