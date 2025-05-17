import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class PlantNetService {
  static const _apiUrl = 'https://my-api.plantnet.org/v2/identify/all?api-key=2b10mnVd9ujJUMfN0dm88OCT2';

  static Future<http.Response> identifyPlant(File imageFile, {String organ = 'leaf'}) async {
    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
    final fileStream = http.ByteStream(imageFile.openRead());
    final length = await imageFile.length();

    final request = http.MultipartRequest('POST', Uri.parse(_apiUrl))
      ..fields['organs'] = organ
      ..files.add(
        http.MultipartFile(
          'images',
          fileStream,
          length,
          filename: imageFile.path.split('/').last,
          contentType: MediaType.parse(mimeType),
        ),
      );

    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }
}
