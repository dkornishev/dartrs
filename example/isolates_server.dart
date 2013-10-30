library dartrs_example;

import '../lib/dartrs.dart';

void main() {

  RestfulServer.bind().then((server) {
    server
    ..isolates=8
    ..isolateInit = new MyInit();
  });
}

class MyInit implements InitLogic {
  call(RestfulServer server) {
    print("initializing");
    server
    ..onPost("/api/isolate", (request, params, body) {
      print(body);
      request.response.statusCode = "777";
      request.response.headers.add("X-TEST", "WORKS");
      request.response.headers.contentType = ContentTypes.TEXT_PLAIN;
      request.response.write("$body ${new DateTime.now()}");
      request.response.writeln("Работает!");
    });
  }
}