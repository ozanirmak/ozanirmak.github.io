import 'package:fetch_client/fetch_client.dart';
import 'package:http/http.dart' as http;

// Tarayıcının fetch akışı: sunucu adımları rapor bitmeden gelir.
http.Client yeniIstemci() => FetchClient(mode: RequestMode.cors);
