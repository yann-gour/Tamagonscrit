import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final bytes = File('assets/monome_zg.png').readAsBytesSync();
  final image = img.decodePng(bytes);
  if (image != null) {
    print('Width: ' + image.width.toString() + ', Height: ' + image.height.toString());
  } else {
    print('Failed to decode image');
  }
}
