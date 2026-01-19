import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:duoob_desktop_app_v1/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';


enum apiMethod { get, post, delete, update, multipart }

class ApiServices {
  static final client = http.Client();
  static Future execute(
      {required apiMethod method,
      required String url,
      var data,
      String? accessToken,
      List<File>? files,
      bool isCoreApi = false,
      bool isHeaderEmpty = false,
      bool isJson = false,
      bool isQueryParamsPost = false,
      bool isMultipartFromPath = false,
      String fileName = ''}) async {
    developer.log(url.toString());
    try {
      var response;
      switch (method) {
        case apiMethod.get:
           developer.log(
              '${isCoreApi ? Constants.coreBaseUrl : Constants.baseUrl}$url',
              name: 'Request');
          response = await client.get(
              data != null
                  ? Uri.https(Constants.domain, url, data)
                  : Uri.parse(
                      '${isCoreApi ? Constants.coreBaseUrl : Constants.baseUrl}$url',
                    ),
              headers: accessToken != null
                  ? {
                      'Accept': 'application/json',
                      'Authorization': 'Bearer $accessToken',
                    }
                  : {});
          break;
        case apiMethod.multipart:
          var request = http.MultipartRequest(
              'POST', Uri.parse('${Constants.baseUrl}$url'));

          for (File file in files!) {
            var fileStream = http.ByteStream(file.openRead());
            developer.log(
              '$fileStream',
            );
            var length = await file.length();
            if (isMultipartFromPath) {
              String dir = dirname(file.path);
              String newPath = join(dir, fileName);
              File finalFile = await File(file.path).copy(newPath);
              developer.log(finalFile.path, name: 'Final Filepath');
              var multipartFile = http.MultipartFile(
                'files', // The name field expected by the server
                fileStream,
                length,
                filename: basename(finalFile.path),
              );
              request.files.add(multipartFile);
            } else {
              var multipartFile = http.MultipartFile(
                'Uploads', // The name field expected by the server
                fileStream,
                length,
                filename: basename(file.path),
              );

              request.files.add(multipartFile);
            }
          }
          if (data != null) {
            request.fields.addAll(data);
          }
          // request.fields.addAll(data);
          // developer.log(data.toString(),name: 'File');

          // Optionally, add headers
          request.headers.addAll({
            // Replace with your token if needed
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'multipart/form-data',
          });
          response = await request.send();

          break;
        case apiMethod.post:
          response = await client.post(
              isQueryParamsPost
                  ? Uri.https(Constants.domain, url, data)
                  : Uri.parse('${Constants.baseUrl}$url'),
              body: isQueryParamsPost
                  ? {}
                  : isJson
                      ? json.encode(data)
                      : data,
              headers: accessToken != null
                  ? isQueryParamsPost?{
                      'Authorization': 'Bearer $accessToken',
                  } :{
                      'Authorization': 'Bearer $accessToken',
                      'Content-Type': 'application/json',
                      'Accept': 'application/json',
                    }
                  : isHeaderEmpty
                      ? {
                          'Accept': 'application/json',
                          'Content-Type': 'application/json'
                        }
                      : {
                          'Content-Type': 'application/x-www-form-urlencoded',
                          'Authorization': '~@#\$%^&()_+|}{P:"?><-=/-+.'
                        });

          break;
        case apiMethod.delete:
          break;
        case apiMethod.update:
          break;
      }
      developer.log(response.statusCode.toString(),
          name: 'Response status code');
      // developer.log(response.body.toString(), name: 'Response');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (method == apiMethod.multipart) {
          var responseData = await response.stream.bytesToString();
          var jsonRes = jsonDecode(responseData);
          return jsonRes;
        } else {
          var jsonResponse = jsonDecode(response.body);
          return jsonResponse;
        }
      } else {
        if (response.body != null) {
          var jsonResponse = jsonDecode(response.body);
          return jsonResponse;
        }
      }
    } catch (e) {
      // getxSnackbar(message: e.toString(), isError: true);
      // return {'StatusCode': 0, 'Data': e.toString()};
      developer.log(e.toString(), name: 'Exception from provider');
    }
  }
}
