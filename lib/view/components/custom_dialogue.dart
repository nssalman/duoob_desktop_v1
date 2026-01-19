import 'package:duoob_desktop_app_v1/utils/constants.dart';
import 'package:flutter/material.dart';
class CustomDialog extends StatelessWidget {

  final Function() yes;
  final Function() no;
  final String title, subtitle, yesTitle , noTitle;

  CustomDialog({
    required this.yes,
    required this.no,
    required this.title,
    required this.subtitle,
    required this.noTitle,
    required this.yesTitle
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10)
        ),
        padding: const EdgeInsets.symmetric(vertical: 5,horizontal: 5),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding:  EdgeInsets.only(top: 10),
                    child: Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16,
                          color: Constants.primaryColor,
                          fontWeight: FontWeight.bold
                          ),
                    ),
                  ),

                  Padding(
                    padding:  EdgeInsets.only(top: 10),
                    child: Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,

                      style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Color.fromRGBO(34, 34, 34, 1),
                          ),
                    ),
                  ),


                  SizedBox(height: 5),

                  buttonRow(context),

                  SizedBox(height: 2),

                ],
              ),
            ),

            Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close,color: Color.fromRGBO(175, 175, 175, 1),),
                  onPressed: (){
                    Navigator.pop(context,false);
                  },
                ))
          ],
        ),
      ),
    );
  }

  Widget buttonRow(BuildContext context){

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomButton2(
          title: noTitle,
          borderColor: Constants.primaryColor,
          backgroundColor: Colors.white,
          titleColor: Colors.black,
          onPressed: (){
            no();
          },
        ),

        SizedBox(width: 10),

        CustomButton2(
          title: yesTitle,
          borderColor: Constants.primaryColor,
          backgroundColor: Constants.primaryColor,
          titleColor: Colors.white,
          onPressed: (){
            yes();
          },
        )
      ],
    );
  }
}

class CustomButton2 extends StatelessWidget {

  final Function() onPressed ;
  final String title ;
  final Color backgroundColor;
  final Color borderColor;
  final Color titleColor;
  final double? fontSize;
  final double? borderRadius;
  final double? width;

  // ignore: use_key_in_widget_constructors
  const CustomButton2({
    required this.backgroundColor,
    required this.borderColor,
    required this.title,
    required this.titleColor,
    required this.onPressed,
    this.fontSize,
    this.borderRadius,
    this.width
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (){
        onPressed();
      },
      child: Container(
        height: 30,
        width: 100,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius != null ? borderRadius! : 5),
            border: Border.all(color: borderColor),
            color: backgroundColor
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: fontSize != null ? fontSize! : 14,
              color: titleColor,
            ),
          ),
        ),
      ),
    );  }
}
