import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_insta/models/user.dart';
import 'package:flutter_insta/pages/profile.dart';
import 'package:flutter_insta/pages/timeline.dart';
import 'package:flutter_insta/widgets/header.dart';
import 'package:flutter_insta/widgets/progress.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}


class _SearchState extends State<Search> {
  Future<QuerySnapshot> searchResultsFuture;
  TextEditingController searchController = TextEditingController();

  handleSearch(String query){
    Future<QuerySnapshot> users = userRef
      .where("displayName", isGreaterThanOrEqualTo: query)
      .getDocuments();
    
    setState(() {
      searchResultsFuture = users;
    });
    
  }

  AppBar buildSearchField() {
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: "Search for users",
          filled: true,
          prefixIcon: Icon(
            Icons.account_box,
            size: 28.0,
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: () => searchController.clear(),
          ),
        ),
        onFieldSubmitted: handleSearch,
      ),
    );
  }

  Container buildNoContent() {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/search.svg',
              height: orientation == Orientation.portrait ? 300 : 150,
            ),
            Text(
              "Find Users", 
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 50,
            ))
          ],
        ),
      ),
    );
  }

  buildSearchResults(){
    return FutureBuilder(
      future: searchResultsFuture,
      builder: (context, snapshot){
        if(!snapshot.hasData){
          return circularProgress();
        }
        List<UserResult> searchResults = [];
        snapshot.data.documents.forEach((doc){
          User user = User.fromDocument(doc);
          UserResult searchResult = UserResult(user);
          searchResults.add(searchResult);
        });
        return ListView(
          children: searchResults,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSearchField(),
      body: searchResultsFuture == null ? buildNoContent() : buildSearchResults(),
      // body: Text("Seach"),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;

  UserResult(this.user);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              ),
              title: Text(
                user.displayName,
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold
                ),
              ),
              subtitle: Text(
                user.username,
                style: TextStyle(
                  color: Colors.black54
                ),
              ),
            ),
          ),
          Divider(color: Colors.grey,height: 2.0,)
        ],
      ),
    );
    // return Container(child: Text("Hii"),);
  }
}

showProfile(BuildContext context, {String profileId}){
  Navigator.push(context, MaterialPageRoute(builder: (context) => Profile(profileId: profileId,)));
}