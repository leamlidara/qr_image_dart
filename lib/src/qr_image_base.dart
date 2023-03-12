// ignore_for_file: implementation_imports

import 'dart:math';

import 'package:image/image.dart';
import 'package:qr/qr.dart';
import 'package:image/src/util/_circle_test.dart';
import 'package:image/src/util/math_util.dart';

class QRImage {
  /// Logo to draw inside QR image
  Image? logo;

  /// Make logo round
  final bool logoRound;

  /// QR image size
  int size;

  /// Block color
  ColorUint8? elementColor;

  /// Background color
  ColorUint8? backgroundColor;

  /// Radius per block
  int radius;

  /// QR data
  final String data;

  /// Error correct level
  final int errorCorrectLevel;

  /// Number of type generation (1 to 40 or 0 for auto)
  final int typeNumber;

  /// Generate QRcode image
  ///
  /// - ``data`` QR image data.
  /// - ``logo`` Logo to draw inside QR image
  /// - ``logoRound`` Make logo round.
  /// - ``size`` QR image size
  /// - ``radius`` Radius per block
  /// - ``elementColor`` Block color
  /// - ``backgroundColor`` Background color
  /// - ``errorCorrectLevel`` Error correct level
  /// - ``typeNumber`` Number of type generation (1 to 40 or 0 for auto)
  QRImage(
    this.data, {
    this.logo,
    this.logoRound = true,
    this.size = 120,
    this.radius = 0,
    this.elementColor,
    this.backgroundColor,
    this.errorCorrectLevel = QrErrorCorrectLevel.L,
    this.typeNumber = 0,
  });

  Image generate() {
    QrImage qrImage;
    if (typeNumber == 0) {
      var qrCode0 = QrCode.fromData(
        data: data,
        errorCorrectLevel: errorCorrectLevel,
      );
      qrImage = QrImage(qrCode0);
    } else {
      var qrCode = QrCode(typeNumber, errorCorrectLevel);
      qrCode.addData(data);
      qrImage = QrImage(qrCode);
    }

    elementColor ??= ColorUint8.rgb(0, 0, 0);
    backgroundColor ??= ColorUint8.rgb(255, 255, 255);

    Image img = (radius == 0 ? _drawQRCodeDefault(qrImage) : _drawQRCodeRound(qrImage));

    if (logo != null) {
      int logoSize;
      if (qrImage.typeNumber <= 2) {
        logoSize = qrImage.typeNumber + 7;
      } else if (qrImage.typeNumber <= 4) {
        logoSize = qrImage.typeNumber + 8;
      } else {
        logoSize = qrImage.typeNumber + 9;
      }

      img = _drawLogoToQr(img, logoSize * (size / qrImage.moduleCount).floor());
    }

    return img;
  }

  Image _drawLogoToQr(Image img, int logoSize) {
    int w = logo!.width;
    int h = logo!.height;
    if (w > logoSize) {
      w = logoSize;
      h = logoSize;
    }

    logo = copyResize(logo!, width: w, height: h);
    if (logoRound) {
      logo = copyCropCircle(logo!);
    }

    int x = (size / 2).floor() - (w / 2).floor();
    int y = (size / 2).floor() - (h / 2).floor();
    for (var a = 0; a < w; a++) {
      for (var b = 0; b < h; b++) {
        Color p = logo!.getPixelLinear(a, b);
        img = drawPixel(img, x + a, y + b, p);
      }
    }

    return img;
  }

  Image _drawQRCodeDefault(QrImage qr) {
    var blockSize = (size / qr.moduleCount).floor() + 2;
    var imageSize = (blockSize * qr.moduleCount) + (blockSize * 2);

    var img = Image(width: imageSize, height: imageSize);
    fill(img, color: (backgroundColor ?? ColorUint8.rgb(255, 255, 255)));

    for (var x = 0; x < qr.moduleCount; x++) {
      for (var y = 0; y < qr.moduleCount; y++) {
        if (qr.isDark(x, y) == false) continue;
        int xx = (x * blockSize) + blockSize;
        int yy = (y * blockSize) + blockSize;
        fillRect(img, x1: xx, y1: yy, x2: xx + blockSize, y2: yy + blockSize, color: elementColor!);
      }
    }

    return copyResize(img, width: size, height: size);
  }

  Image _drawQRCodeRound(QrImage qr) {
    var blockSize = (size / qr.moduleCount).floor() + 2;
    var imageSize = (blockSize * qr.moduleCount) + (blockSize * 2);

    var img = Image(width: imageSize, height: imageSize);
    fill(img, color: (backgroundColor ?? ColorUint8.rgb(255, 255, 255)));

    // Fill element
    for (var x = 0; x < qr.moduleCount; x++) {
      for (var y = 0; y < qr.moduleCount; y++) {
        int xx = (x * blockSize) + blockSize;
        int yy = (y * blockSize) + blockSize;

        _IsDark dark = _IsDark._(qr, x, y);

        if (qr.isDark(x, y)) {
          _fillRoundedRect(
            img,
            x1: xx,
            y1: yy,
            x2: xx + blockSize,
            y2: yy + blockSize,
            color: elementColor!,
            radiusTopLeft: (!dark.top && !dark.left ? radius : 0),
            radiusTopRight: (!dark.top && !dark.right ? radius : 0),
            radiusBottomLeft: (!dark.bottom && !dark.left ? radius : 0),
            radiusBottomRight: (!dark.bottom && !dark.right ? radius : 0),
          );
          continue;
        }

        //Re-sharp inner curve
        bool needTopLeft = (dark.left && dark.top && dark.topLeft);
        bool needTopRight = (dark.right && dark.top && dark.topRight);
        bool needBottomLeft = (dark.left && dark.bottom && dark.bottomLeft);
        bool needBottomRight = (dark.right && dark.bottom && dark.bottomRight);
        if (!needBottomRight && !needBottomLeft && !needTopLeft && !needTopRight) continue;

        _fillRoundedRect(
          img,
          x1: xx + 1,
          y1: yy + 1,
          x2: xx + blockSize,
          y2: yy + blockSize,
          color: elementColor!,
          radiusTopLeft: (needTopLeft ? 0 : radius),
          radiusTopRight: (needTopRight ? 0 : radius),
          radiusBottomLeft: (needBottomLeft ? 0 : radius),
          radiusBottomRight: (needBottomRight ? 0 : radius),
        );

        _fillRoundedCurveBackground(
          img,
          x1: xx + 1,
          y1: yy + 1,
          x2: xx + blockSize,
          y2: yy + blockSize,
          color: backgroundColor!,
          radiusTopLeft: (needTopLeft ? radius : 0),
          radiusTopRight: (needTopRight ? radius : 0),
          radiusBottomLeft: (needBottomLeft ? radius : 0),
          radiusBottomRight: (needBottomRight ? radius : 0),
        );
      }
    }

    return copyResize(img, width: size, height: size);
  }

  Image _fillRoundedRect(Image src,
      {required int x1,
      required int y1,
      required int x2,
      required int y2,
      required Color color,
      num radiusTopLeft = 0,
      num radiusTopRight = 0,
      num radiusBottomLeft = 0,
      num radiusBottomRight = 0,
      Image? mask,
      Channel maskChannel = Channel.luminance}) {
    if (color.a == 0) return src;

    final xx0 = min(x1, x2).clamp(0, src.width - 1);
    final yy0 = min(y1, y2).clamp(0, src.height - 1);
    final xx1 = max(x1, x2).clamp(0, src.width - 1);
    final yy1 = max(y1, y2).clamp(0, src.height - 1);
    final ww = (xx1 - xx0) + 1;
    final hh = (yy1 - yy0) + 1;

    radiusTopLeft = radiusTopLeft.round();
    radiusTopRight = radiusTopRight.round();
    radiusBottomRight = radiusBottomRight.round();
    radiusBottomLeft = radiusBottomLeft.round();

    final c1x = xx0 + radiusTopLeft;
    final c1y = yy0 + radiusTopLeft;
    final c2x = xx1 - radiusTopRight + 1;
    final c2y = yy0 + radiusTopRight;
    final c3x = xx1 - radiusBottomRight + 1;
    final c3y = yy1 - radiusBottomRight + 1;
    final c4x = xx0 + radiusBottomLeft;
    final c4y = yy1 - radiusBottomLeft + 1;

    final iter = src.getRange(xx0, yy0, ww, hh);
    while (iter.moveNext()) {
      final p = iter.current;
      final px = p.x;
      final py = p.y;

      num a = 1;
      if (px < c1x && py < c1y) {
        //Top Left
        a = circleTest(p, c1x.toInt(), c1y.toInt(), radiusTopLeft * radiusTopLeft);
      } else if (px > c2x && py < c2y) {
        //Top Right
        a = circleTest(p, c2x.toInt(), c2y.toInt(), radiusTopRight * radiusTopRight);
      } else if (px > c3x && py > c3y) {
        //Bottom Right
        a = circleTest(p, c3x.toInt(), c3y.toInt(), radiusBottomRight * radiusBottomRight);
      } else if (px < c4x && py > c4y) {
        a = circleTest(p, c4x.toInt(), c4y.toInt(), radiusBottomLeft * radiusBottomLeft);
      }

      if (a == 0) continue;

      a *= color.aNormalized;

      final m = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel) ?? 1;
      p
        ..r = mix(p.r, color.r, a * m)
        ..g = mix(p.g, color.g, a * m)
        ..b = mix(p.b, color.b, a * m)
        ..a = p.a * (1 - (color.a * m));
    }

    return src;
  }

  Image _fillRoundedCurveBackground(Image src,
      {required int x1,
      required int y1,
      required int x2,
      required int y2,
      required Color color,
      num radiusTopLeft = 0,
      num radiusTopRight = 0,
      num radiusBottomLeft = 0,
      num radiusBottomRight = 0,
      Image? mask,
      Channel maskChannel = Channel.luminance}) {
    if (color.a == 0) return src;

    final xx0 = min(x1, x2).clamp(0, src.width - 1);
    final yy0 = min(y1, y2).clamp(0, src.height - 1);
    final xx1 = max(x1, x2).clamp(0, src.width - 1);
    final yy1 = max(y1, y2).clamp(0, src.height - 1);
    final ww = (xx1 - xx0) + 1;
    final hh = (yy1 - yy0) + 1;

    radiusTopLeft = radiusTopLeft.round();
    radiusTopRight = radiusTopRight.round();
    radiusBottomRight = radiusBottomRight.round();
    radiusBottomLeft = radiusBottomLeft.round();

    final c1x = xx0 + radiusTopLeft;
    final c1y = yy0 + radiusTopLeft;
    final c2x = xx1 - radiusTopRight + 1;
    final c2y = yy0 + radiusTopRight;
    final c3x = xx1 - radiusBottomRight + 1;
    final c3y = yy1 - radiusBottomRight + 1;
    final c4x = xx0 + radiusBottomLeft;
    final c4y = yy1 - radiusBottomLeft + 1;

    final iter = src.getRange(xx0, yy0, ww, hh);
    while (iter.moveNext()) {
      final p = iter.current;
      final px = p.x;
      final py = p.y;

      num a = 1;
      if (px < c1x && py < c1y) {
        //Top Left
        a = circleTest(p, c1x.toInt(), c1y.toInt(), radiusTopLeft * radiusTopLeft);
      } else if (px > c2x && py < c2y) {
        //Top Right
        a = circleTest(p, c2x.toInt(), c2y.toInt(), radiusTopRight * radiusTopRight);
      } else if (px > c3x && py > c3y) {
        //Bottom Right
        a = circleTest(p, c3x.toInt(), c3y.toInt(), radiusBottomRight * radiusBottomRight);
      } else if (px < c4x && py > c4y) {
        a = circleTest(p, c4x.toInt(), c4y.toInt(), radiusBottomLeft * radiusBottomLeft);
      }
      if (a == 0) continue;

      a *= color.aNormalized;

      final m = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel) ?? 1;
      p
        ..r = mix(p.r, color.r, a * m)
        ..g = mix(p.g, color.g, a * m)
        ..b = mix(p.b, color.b, a * m)
        ..a = p.a * (1 - (color.a * m));
    }

    return src;
  }
}

class _IsDark {
  late bool top;
  late bool bottom;
  late bool left;
  late bool right;
  late bool topLeft;
  late bool topRight;
  late bool bottomLeft;
  late bool bottomRight;
  _IsDark._(QrImage qr, int x, int y) {
    int totalModuleCount = qr.moduleCount - 1;
    top = (y == 0 ? false : qr.isDark(x, y - 1));
    bottom = (y == totalModuleCount ? false : qr.isDark(x, y + 1));
    left = (x == 0 ? false : qr.isDark(x - 1, y));
    right = (x == totalModuleCount ? false : qr.isDark(x + 1, y));

    topLeft = (y == 0 || x == 0 ? false : qr.isDark(x - 1, y - 1));
    topRight = (y == 0 || x == totalModuleCount ? false : qr.isDark(x + 1, y - 1));
    bottomLeft = (y == totalModuleCount || x == 0 ? false : qr.isDark(x - 1, y + 1));
    bottomRight = (y == totalModuleCount || x == totalModuleCount ? false : qr.isDark(x + 1, y + 1));
  }
}
