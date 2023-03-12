import 'package:image/image.dart';
import 'package:qr_image/qr_image.dart';
import "dart:io";

void main() {
  var img1 = QRImage(
    "https://google.com/",
    backgroundColor: ColorUint8.rgb(255, 255, 255),
    size: 300,
  ).generate();
  File("image/pic1.png").writeAsBytesSync(encodePng(img1));

  var img2 = QRImage(
    "https://google.com/",
    backgroundColor: ColorUint8.rgb(255, 255, 255),
    size: 300,
    radius: 10,
    logo: decodePng(File("image/logo.png").readAsBytesSync()),
    logoRound: true,
  ).generate();
  File("image/pic2.png").writeAsBytesSync(encodePng(img2));

  var img3 = QRImage(
    "https://google.com/",
    backgroundColor: ColorUint8.rgb(255, 255, 255),
    size: 300,
    radius: 10,
    logo: decodePng(File("image/logo.png").readAsBytesSync()),
    logoRound: true,
    typeNumber: 5,
  ).generate();
  File("image/pic3.png").writeAsBytesSync(encodePng(img3));
}
