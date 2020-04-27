import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:flutter_insta/models/user.dart';
import 'package:flutter_insta/pages/home.dart';
import 'package:flutter_insta/widgets/progress.dart';
// import 'package:firebase_admob/firebase_admob.dart';

const String testDevice ='';

class EditProfile extends StatefulWidget {
  final String currentUserId;
  EditProfile({this.currentUserId});
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool isLoading = false;
  User user;
  bool _displayNameValid = true;
  bool _bioValid = true;


  // static final MobileAdTargetingInfo targetingInfo = new MobileAdTargetingInfo(
  //   testDevices:<String>[],
  //   keywords: <String>['social', 'walls', 'wallpaper'],
  //   childDirected: true
  // );

  // BannerAd _bannerAd;
  // InterstitialAd _interstitialAd;

  // InterstitialAd createInterstitialAd(){
  //   return new InterstitialAd(
  //     adUnitId: 'ca-app-pub-7443590473977981/9420705939',
  //     targetingInfo: targetingInfo,
  //     listener: (MobileAdEvent event){
  //       print('Banner evene:$event');
  //     }
  //   );
  // }
  // BannerAd createBannerAd(){
  //   return new BannerAd(
  //     adUnitId: 'ca-app-pub-7443590473977981/9612277626', 
  //     size: AdSize.banner,
  //     targetingInfo: targetingInfo,
  //     listener: (MobileAdEvent event){
  //       print('Banner evene:$event');
  //     }
  //   );
  // }

  @override
  void initState() {
    // TODO: implement initState
    getUser();
    super.initState();
    // FirebaseAdMob.instance.initialize(appId: 'ca-app-pub-7443590473977981~4551522639');
    // _bannerAd = createBannerAd()..load()..show();
  }

  @override
  void dispose() {
    // _bannerAd?.dispose();
    // _interstitialAd.dispose();
    super.dispose();
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc = await userRef.document(widget.currentUserId).get();
    user = User.fromDocument(doc);
    displayNameController.text = user.username;
    bioController.text = user.bio;
    setState(() {
      isLoading = false;
    });
  }

  logout()async{
    await googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) => Home())); 
  }

  Column buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            "Display Name",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(hintText: "Update display name",
          errorText: _displayNameValid ? null : "Display name too short"),
        )
      ],
    );
  }

  Column buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            "Display Name",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(hintText: "Update bio",
          errorText: _bioValid ? null : "Bio too long"),
        )
      ],
    );
  }

  updateProfileData(){
    // createInterstitialAd()..load()..show();
     setState(() {
       displayNameController.text.trim().length < 3 || displayNameController.text.isEmpty ?
       _displayNameValid = false : _displayNameValid = true;

       bioController.text.trim().length < 3 || bioController.text.isEmpty ?
       _bioValid = false : _bioValid = true;

      if(_displayNameValid && _bioValid){
        userRef.document(widget.currentUserId).updateData({
          "username": displayNameController.text,
          "bio": bioController.text,
        });
      }
      SnackBar snackbar = SnackBar(
        content: Text("Profile updated!"),
      );
      _scaffoldKey.currentState.showSnackBar(snackbar);
     });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: <Widget>[
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.done,
                size: 30,
                color: Colors.green,
              )),
        ],
      ),
      body: isLoading
          ? circularProgress()
          : ListView(
              children: <Widget>[
                Container(
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(top: 16, bottom: 8),
                        child: CircleAvatar(
                          radius: 50.0,
                          backgroundImage:
                              CachedNetworkImageProvider(user.photoUrl),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: <Widget>[
                            buildDisplayNameField(),
                            buildBioField(),
                          ],
                        ),
                      ),
                      RaisedButton(
                        onPressed: updateProfileData, 
                        child: Text("Update profile",
                            style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: FlatButton.icon(
                          onPressed: logout,
                          icon: Icon(
                            Icons.cancel,
                            color: Colors.red,
                          ),
                          label: Text(
                            "logout",
                            style: TextStyle(color: Colors.red, fontSize: 20),
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
