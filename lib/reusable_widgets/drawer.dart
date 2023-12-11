import 'package:finalapp/reusable_widgets/my_list_title.dart';
import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  final void Function()? onProfileTap;
  final void Function()? onSignOut;
  final void Function()? onSummaryTap;
  const MyDrawer(
      {super.key,
      required this.onProfileTap,
      required this.onSignOut,
      required this.onSummaryTap});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFdcecca),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              //header
              const DrawerHeader(
                  child: Icon(
                Icons.person,
                color: Colors.black,
                size: 64,
              )),
              //home list title
              MyListTitle(
                icon: Icons.home,
                text: 'Home',
                onTap: () => Navigator.pop(context),
              ),
              //profile list title
              MyListTitle(
                  icon: Icons.person, text: 'Profile', onTap: onProfileTap),

              MyListTitle(
                  icon: Icons.summarize_rounded,
                  text: 'Summary',
                  onTap: onSummaryTap),
            ],
          ),
          //logout list title
          Padding(
            padding: const EdgeInsets.only(bottom: 25.0),
            child: MyListTitle(
                icon: Icons.logout, text: 'Logout', onTap: onSignOut),
          ),
        ],
      ),
    );
  }
}
