import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

Future<void> dosyaVer(BuildContext context, Uint8List bayt, String ad, String tur) async {
  await SharePlus.instance.share(ShareParams(files: [XFile.fromData(bayt, mimeType: tur, name: ad)], fileNameOverrides: [ad]));
}
