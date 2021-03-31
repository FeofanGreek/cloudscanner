import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:image/image.dart' as img;
import 'package:image/image.dart' as imgCamera;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


String place = '';
String resultUpload = 'Сделайте фотографию';

void main() {
  runApp(cloudScaner());
}

class cloudScaner extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate
      ],
      supportedLocales: [
        const Locale('en'),
        const Locale('ru')
      ],
      home: cloudScanerPage(),
      //home: playerS(),
    );
  }
}

class cloudScanerPage extends StatefulWidget {


  @override
  _cloudScanerPageState createState() => _cloudScanerPageState();
}

class _cloudScanerPageState extends State<cloudScanerPage> {
  File _image;
  final picker = ImagePicker();
  final pickerCamera = ImagePicker();

  @override
  void initState() {
    initializeDateFormatting();
    super.initState();
  }


  Future getImageCamera() async {
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat('dd-MM-yyyy-hh-mm');
    String Udate = formatter.format(now);
    String placeServer = place.trim();
    DateFormat formatterDir = DateFormat('dd-MM-yyyy');
    String dir = formatterDir.format(now);


    placeServer = placeServer.replaceAll(' ','_');
    placeServer = placeServer.replaceAll('.','_');
    placeServer = placeServer.replaceAll('(','-');
    placeServer = placeServer.replaceAll(')','-');
    placeServer = placeServer.replaceAll(',','_');
    setState(() {
      _image = null;
      resultUpload = 'Подготавливаем изображение';
    });

    final pickedFile2 = await pickerCamera.getImage(source: ImageSource.camera);

    if (pickedFile2 != null) {

        _image = File(pickedFile2.path);


      imgCamera.Image image_temp2 = imgCamera.decodeImage(_image.readAsBytesSync());
      imgCamera.Image resized_img2 = imgCamera.copyResize(image_temp2, width: 600);
      final Directory directory = await getApplicationDocumentsDirectory();
      setState(() {
        _image = File('${directory.path}/${Udate}_${placeServer}.jpg')..writeAsBytesSync(img.encodeJpg(image_temp2));
      });

      var base64Image = base64Encode(_image.readAsBytesSync());
      http.post(Uri.parse('https://koldashev.ru/cloudscanner/photo.php'), body: {
        "image": base64Image,
        "name": '${Udate}_${placeServer}.jpg',
        "dir": '$dir',
      }).then((result) {
        setState(() {
          _image = null;
        });
        resultUpload = result.body;
        print(result.body);
      }).catchError((error) {
        print(error);
      });

    } else {

      print('Изображение не выбрано.');
    }

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          brightness: Brightness.dark,
          leading: GestureDetector( onTap: ()=> exit(0), child:Icon(Icons.exit_to_app),),
          title: Text('Фотофиксация облаков'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 20,),
            //вводим откуда она
            Container(
              height: 55,
              width: MediaQuery.of(context).size.width - 40,
              alignment: Alignment.bottomCenter,
              margin: EdgeInsets.fromLTRB(20,0,20,10),
              child:TextFormField(
                    textAlign: TextAlign.left,
                    enabled: true,
                    style: TextStyle(fontSize: 19.0, color: Colors.black,),
                    decoration: InputDecoration(
                    hintStyle: TextStyle(fontSize: 19.0, color: Colors.grey,),
                    hintText: "Место съемки",
                    //fillColor: Colors.black,
                    //filled: true,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(0.0),
                      borderSide: BorderSide(
                        width: 0,
                        color: Colors.black,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(0.0),
                      borderSide: BorderSide(
                        color: Colors.black,
                        //width: 1.0,
                      ),
                    ),
                  ),
                  onChanged: (value){
                  place = value;
                  },
                  autovalidateMode: AutovalidateMode.disabled,
                ),
            ),
            SizedBox(height: 20,),
          //отображаем фотку
_image == null ? Container( child: Text(resultUpload)) : Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                    image: FileImage(_image),
                                    fit:BoxFit.fitHeight, alignment: Alignment(0.0, 0.0)
                                ),
                              ),
                              child: Center(
                                child:Container(
                                    width: 30.0,
                                    height: 30.0,
                                    margin: EdgeInsets.fromLTRB(10,0,0,0),
                                    child:CircularProgressIndicator(strokeWidth: 4.0,
                                      valueColor : AlwaysStoppedAnimation(Color(0xFF7C52E4)),)
                                ),
                              )
                            ),

            SizedBox(height: 20,),
            //кнопка сфоткать
            Container(
              height: 55,
              width: MediaQuery.of(context).size.width - 40,
              alignment: Alignment.bottomCenter,
              margin: EdgeInsets.fromLTRB(20,0,20,10),
              child: TextButton(
                onPressed:(){
                  getImageCamera();
                } ,
                child: Text('Фото и передача', style: TextStyle(fontSize: 14.0, color: Colors.white,),textAlign: TextAlign.center,),
                style: ElevatedButton.styleFrom(
                  primary: Colors.lightBlue,
                  minimumSize: Size(MediaQuery.of(context).size.width - 40, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
