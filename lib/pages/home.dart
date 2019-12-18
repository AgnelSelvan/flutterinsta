import 'package:cloud_firestore/cloud_firestore.dart';
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

final StorageReference storageRef = FirebaseStorage.instance.ref();
final GoogleSignIn googleSignIn = GoogleSignIn();
final userRef = Firestore.instance.collection("users");
final postRef = Firestore.instance.collection("posts");
final commentsRef = Firestore.instance.collection("comments");
final ActivityFeedRef = Firestore.instance.collection("feed");
final followersRef = Firestore.instance.collection('followers');
final followingRef = Firestore.instance.collection('following');
final DateTime timestamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
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

  handleSignIn(GoogleSignInAccount account) {
    if (account != null) {
      // print("User signed in: $account");
      createUserInFirestore();
      setState(() {
        isAuth = true;
      });
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  createUserInFirestore() async {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await userRef.document(user.id).get();

    if(!doc.exists){
      final username = await Navigator.push(context, MaterialPageRoute(builder: (context) => CreateAccount()));

      userRef.document(user.id).setData({
        "id": user.id,
        "username": username,
        "photoUrl": user.photoUrl,
        "email": user.email,
        "displayName": user.displayName,
        "bio": "",
        "timestamp": timestamp
      });

      doc = await userRef.document(user.id).get();

    }

     currentUser = User.fromDocument(doc);
     print(currentUser);
     print(currentUser.displayName);
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
      body: PageView(
        children: <Widget>[
          // Timeline(),
          RaisedButton(
            child: Text('Logout'),
            onPressed: logout,
          ),
          ActivityFeed(),
          Upload(currentUser: currentUser),
          Search(),
          Profile(profileId: currentUser?.id)
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageIndex,
        onTap: onTap,
        activeColor: Theme.of(context).primaryColor,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.whatshot)),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active)),
          BottomNavigationBarItem(
              icon: Icon(
            Icons.photo_camera,
            size: 35.0,
          )),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle)),
        ],
      ),
    );
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).accentColor,
            ])),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'Flutter Insta',
              style: TextStyle(
                fontFamily: 'signatra',
                fontSize: 50.0,
                color: Colors.white,
              ),
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
