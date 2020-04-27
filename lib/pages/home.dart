import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_insta/models/user.dart';
import 'package:flutter_insta/pages/activity_feed.dart';
import 'package:flutter_insta/pages/create_account.dart';
import 'package:flutter_insta/pages/profile.dart';
import 'package:flutter_insta/pages/search.dart';
import 'package:flutter_insta/pages/timeline.dart';
import 'package:flutter_insta/pages/upload.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

final StorageReference storageRef = FirebaseStorage.instance.ref();
final GoogleSignIn googleSignIn = GoogleSignIn();
final userRef = Firestore.instance.collection("users");
final postRef = Firestore.instance.collection("posts");
final commentsRef = Firestore.instance.collection("comments");
final ActivityFeedRef = Firestore.instance.collection("feed");
final followersRef = Firestore.instance.collection('followers');
final followingRef = Firestore.instance.collection('following');
final timelineRef = Firestore.instance.collection('timeline');
final DateTime timestamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool isAuth = false;
  PageController pageController;
  int pageIndex = 0;


  @override
  void initState() {
    super.initState();

    pageController = PageController();

    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    }, onError: (err) {
      print("Error signing in: $err");
    });



    // googleSignIn.signInSilently()
    // .then((account) {
    //   handleSignIn(account);
    // }).catchError((err){
    //   print("Error signing in: $err");
    // });
  }

  handleSignIn(GoogleSignInAccount account) async {
    if (account != null) {
      // print("User signed in: $account");
      await createUserInFirestore();
      setState(() {
        isAuth = true;
      });
      configurePushNotification();
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }
  
  configurePushNotification(){
    final GoogleSignInAccount user = googleSignIn.currentUser;
    if(Platform.isIOS) getIOSPermission();
    _firebaseMessaging.getToken().then((token){
      print("Firebase messagintoken:$token \n");
      userRef
        .document(user.id)
        .updateData({"androidNotificationToken": token});
    });
    _firebaseMessaging.configure(
      // onResume: (Map <String, dynamic> message)async{
      //   // print("on message: $message");
      //   // final String recipientId = message['data']['recipient'];
      //   // final String body = message['notification']['body'];
      //   // if(recipientId == user.id){
      //   //   print("Notification Shown!");
      //   //   SnackBar snackbar = SnackBar(content: Text(body, overflow: TextOverflow.ellipsis,),);
      //   //   _scaffoldKey.currentState.showSnackBar(snackbar);
      //   // }
      //   print("on resume $message");
        
      // },
      // onLaunch:(Map <String, dynamic> message)async{
      //   // print("on message: $message");
      //   // final String recipientId = message['data']['recipient'];
      //   // final String body = message['notification']['body'];
      //   // if(recipientId == user.id){
      //   //   print("Notification Shown!");
      //   //   SnackBar snackbar = SnackBar(content: Text(body, overflow: TextOverflow.ellipsis,),);
      //   //   _scaffoldKey.currentState.showSnackBar(snackbar);
      //   // }
      //   // print("Notificatio not shown");
      //   print("on launch $message");

      // },
      onMessage: (Map <String, dynamic> message)async{
        print("on message: $message");
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];
        if(recipientId == user.id){
          print("Notification Shown!");
          SnackBar snackbar = SnackBar(content: Text(body, overflow: TextOverflow.ellipsis,),);
          _scaffoldKey.currentState.showSnackBar(snackbar);
        }
        print("Notificatio not shown");
      }
    );
  }

  getIOSPermission(){
    _firebaseMessaging.requestNotificationPermissions(
      IosNotificationSettings(alert: true, badge: true, sound: true)
    );
    _firebaseMessaging.onIosSettingsRegistered.listen((settings){
      print("Setting registered: $settings");
    });
  }

  createUserInFirestore() async {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await userRef.document(user.id).get();

    if(!doc.exists){
      // final username = await Navigator.push(context, MaterialPageRoute(builder: (context) => CreateAccount()));

      userRef.document(user.id).setData({
        "id": user.id,
        "username": user.displayName,
        "photoUrl": user.photoUrl,
        "email": user.email,
        "displayName": user.displayName,
        "bio": "",
        "timestamp": timestamp
      });
      
      await followersRef
      .document(user.id)
      .collection('userFollowers')
      .document(user.id)
      .setData({});

      doc = await userRef.document(user.id).get();

    }

     currentUser = User.fromDocument(doc);
    //  print(currentUser);
    //  print(currentUser.displayName);
  }
  
  @override
  void dispose(){
    pageController.dispose();
    super.dispose();
  }

  login() async {
    await googleSignIn.signIn();
  }

  logout() {
    googleSignIn.signOut();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(pageIndex,
        duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Widget buildAuthScreen() {
    return Scaffold(
      extendBody: true,
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          Timeline(currentUser: currentUser),
          ActivityFeed(),
          Upload(currentUser: currentUser),
          Search(),
          Profile(profileId: currentUser?.id)
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      floatingActionButton: FloatingActionButton(
        
        onPressed: (){
          setState(() {
            pageIndex = 2;
          });
          pageController.animateToPage(pageIndex,
                duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
        child: Icon(Icons.camera_enhance),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 6,
        child: Container(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  MaterialButton(
                    minWidth: 40,
                    onPressed: () {
                      setState(() {
                        pageIndex = 0;
                      });
                      pageController.animateToPage(pageIndex,
                        duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.whatshot,
                          size: 28,
                          color: pageIndex == 0 ? Theme.of(context).primaryColor : Colors.grey,
                        ),
                        Text(
                          'Timeline',
                          style: TextStyle(
                            color: pageIndex == 0 ? Theme.of(context).primaryColor : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  MaterialButton(
                    minWidth: 40,
                    onPressed: () {
                      setState(() {
                        pageIndex = 1;
                      });
                      pageController.animateToPage(pageIndex,
                        duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.notifications_active,
                          size: 28,
                          color: pageIndex == 1 ? Theme.of(context).primaryColor : Colors.grey,
                        ),
                        Text(
                          'Notification',
                          style: TextStyle(
                            color: pageIndex == 1 ? Theme.of(context).primaryColor : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Right Tab bar icons

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  MaterialButton(
                    minWidth: 40,
                    onPressed: () {
                      setState(() {
                        pageIndex = 3;
                      });
                      pageController.animateToPage(pageIndex,
                        duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.search,
                          size: 28,
                          color: pageIndex == 3 ? Theme.of(context).primaryColor : Colors.grey,
                        ),
                        Text(
                          'Search',
                          style: TextStyle(
                            color: pageIndex == 3 ? Theme.of(context).primaryColor : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  MaterialButton(
                    minWidth: 40,
                    onPressed: () {
                      setState(() {
                        pageIndex = 4;
                      });
                      pageController.animateToPage(pageIndex,
                        duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.account_circle,
                          size: 28,
                          color: pageIndex == 4 ? Theme.of(context).primaryColor : Colors.grey,
                        ),
                        Text(
                          'Profile',
                          style: TextStyle(
                            color: pageIndex == 4 ? Theme.of(context).primaryColor : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )

            ],
          ),
        ),
      ),

    );
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        // decoration: BoxDecoration(
        //     gradient: LinearGradient(
        //         begin: Alignment.topRight,
        //         end: Alignment.bottomLeft,
        //         colors: [
        //       Theme.of(context).primaryColor,
        //       Theme.of(context).accentColor,
        //     ])),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Text(
            //   'Social Park',
            //   style: TextStyle(
            //     fontSize: 50.0,
            //     fontWeight: FontWeight.w500,
            //     color: Colors.deepPurpleAccent,
            //   ),
            // ),
            TypewriterAnimatedTextKit(
                  text: ['Social Park'],
                  textStyle: TextStyle(
                    fontSize: 45.0,
                    fontWeight: FontWeight.w900,
                    color:  Theme.of(context).primaryColor
                  ),
            ),
            SizedBox(
              height: 100,
            ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: 260,
                height: 60,
                decoration: BoxDecoration(
                    image: DecorationImage(
                  image: AssetImage(
                    'assets/images/google_signin_button.png',
                  ),
                  fit: BoxFit.cover,
                )),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
