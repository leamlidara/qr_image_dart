Make generating QR code images with logos easier by using popular [image](https://github.com/brendan-duncan/image) processing library and [QR code](https://github.com/kevmoo/qr.dart) library.

## Getting started

To get started, import the dependency in your code:

```dart
import 'package:qr_image/qr_image.dart';
```

To generate your QR code, you should do:

```dart
var img1 = QRImage(
    "https://google.com/",
    backgroundColor: ColorUint8.rgb(255, 255, 255),
    size: 300,
  ).generate();
```

See the `example` directory for further details.

## Sample

![Sample 1](https://github.com/leamlidara/qr_image_dart/blob/main/image/pic1.png?raw=true)

![Sample 2](https://github.com/leamlidara/qr_image_dart/blob/main/image/pic2.png?raw=true)

![Sample 3](https://github.com/leamlidara/qr_image_dart/blob/main/image/pic3.png?raw=true)
