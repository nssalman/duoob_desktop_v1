import 'package:duoob_desktop_app_v1/services/user_repository.dart';
import 'package:duoob_desktop_app_v1/view/components/custom_dialogue.dart';
import 'package:duoob_desktop_app_v1/view/root_wrapper.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  final UserRepository userRepository = UserRepository();

  @override
  Widget build(BuildContext context) {
    return Container(
      child:  Center(
        child: ElevatedButton(onPressed: (){
           showDialog(
                    context: context,
                    //barrierDismissible: false,
                    builder: (_) {
                      return CustomDialog(
                        title: 'Log Out',
                        subtitle: 'Do you want to log out? ',
                        yesTitle: 'Yes',
                        noTitle: 'Cancel',
                        yes: () {
                          logout();
                          //Navigator.pop(context, false);
                        },
                        no: () {
                          Navigator.pop(context, false);
                        },
                      );
                    });
        }, child: Text('Logout')),
      ),
    );
  }

  logout() async {
    userRepository.clear();
    userRepository.setUserLoggedIn(false);
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (BuildContext context) =>  RootWrapper()),
        (Route<dynamic> route) => false);
  }
}