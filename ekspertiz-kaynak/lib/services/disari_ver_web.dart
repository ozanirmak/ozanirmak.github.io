import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

Future<void> dosyaVer(BuildContext context, Uint8List bayt, String ad, String tur) async {
  final blob = web.Blob([bayt.toJS].toJS, web.BlobPropertyBag(type: tur));
  final url = web.URL.createObjectURL(blob);
  final a = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = ad;
  web.document.body!.append(a);
  a.click();
  a.remove();
  web.URL.revokeObjectURL(url);
}
