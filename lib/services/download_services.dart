import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

Future<String?> downloadWithWebViewCookies({
  required String url,
  required String fileName,
  required Uri cookieUrl, // base domain of the WebView (e.g. https://rakp.rpsmart.com)
}) async {
  try {
    // Step 1: Get cookies from WebView
    final cookieManager = CookieManager.instance();
    final cookies = await cookieManager.getCookies(url: WebUri.uri(cookieUrl));

    // Step 2: Convert cookies to header format
    final cookieHeader = cookies.map((c) => "${c.name}=${c.value}").join("; ");

    // Step 3: Download using Dio with the cookies
    final dir = await getApplicationDocumentsDirectory();
    final savePath = '${dir.path}/${url.split('/').last}';

    final dio = Dio();
    final response = await dio.download(
      url,
      savePath,
      options: Options(
        headers: {
          'Cookie': cookieHeader,
        },
        responseType: ResponseType.bytes,
        followRedirects: true,
        validateStatus: (status) => status! < 500,
      ),
    );

    print("Download complete: $savePath");
    // openDownloadedFile(savePath);
    return savePath;
  } catch (e) {
    print("Download failed: $e");
  }

  
}
 Future<void> openDownloadedFile(String filePath) async {
    final result = await OpenFile.open(filePath);
    debugPrint('Open result: ${result.message}');
  }
