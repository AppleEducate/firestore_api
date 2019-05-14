library firestore_api.impl.io;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../api.dart';
import 'common/http.dart';

final ContentType _jsonContentType =
    new ContentType("application", "json", charset: "utf-8");

HttpClient _createHttpClient() {
  var client = new HttpClient();
  client.userAgent = "Tesla.dart";
  return client;
}

class TeslaClientImpl extends TeslaHttpClient {
  TeslaClientImpl(String email, String password, TeslaAccessToken token,
      TeslaApiEndpoints endpoints,
      {HttpClient client})
      : this.client = client == null ? _createHttpClient() : client,
        super(email, password, token, endpoints);

  final HttpClient client;

  @override
  Future<dynamic> sendHttpRequest(String url,
      {bool needsToken: true,
      String extract,
      Map<String, dynamic> body}) async {
    var uri = endpoints.ownersApiUrl.resolve(url);

    if (endpoints.enableProxyMode) {
      uri = uri.replace(queryParameters: {"__tesla": "api"});
    }

    var request =
        body == null ? await client.getUrl(uri) : await client.postUrl(uri);
    request.headers.set("User-Agent", "Tesla.dart");
    if (needsToken) {
      if (!isCurrentTokenValid(true)) {
        await login();
      }
      request.headers.add("Authorization", "Bearer ${token.accessToken}");
    }
    if (body != null) {
      request.headers.contentType = _jsonContentType;
      request.write(const JsonEncoder().convert(body));
    }
    var response = await request.close();
    var content = await response.transform(const Utf8Decoder()).join();
    if (response.statusCode != 200) {
      throw new Exception(
          "Failed to perform action. (Status Code: ${response.statusCode})\n${content}");
    }
    var result = const JsonDecoder().convert(content);

    if (result is Map) {
      if (extract != null) {
        return result[extract];
      }
    }

    return result;
  }

  @override
  Future close() async {
    await client.close();
  }
}