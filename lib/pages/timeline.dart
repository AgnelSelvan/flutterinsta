import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_insta/widgets/progress.dart';
import './../widgets/header.dart';

final userRef = Firestore.instance.collection('users');

class Timeline extends StatefulWidget {
  @override
  _TimelineState createState() => _TimelineState();
}


class _TimelineState extends State<Timeline> {

  // List<dynamic> users;

  @override
  void initState() {
    // getUserById();
    // getUsers();
    // createUser();
    // updateUser();
    // deleteUser();
    super.initState();
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

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, isAppTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: userRef.snapshots(),
        builder: (context, snapshot){
          if(!snapshot.hasData){
            return circularProgress();
          }
          final List<Text> children = snapshot.data.documents.map((doc)=> Text(doc['username'])).toList();
          return Container(
            child: ListView(
              children: children,
            ),
          );
        },
      ),
    );
  }
}
