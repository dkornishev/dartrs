library dartrs_example;

import '../lib/dartrs.dart';

void main() {

  RestfulServer.bind().then((server) {
    server
    ..isolates=22
    ..isolateInit = new MyInit();
  });
}

class MyInit implements InitLogic {
  call(RestfulServer server) {
    print("initializing server");
    server
    ..onPost("/api/isolate", (request, params, body) {
      request.response.statusCode = "777";
      request.response.headers.add("X-TEST", "WORKS");
      request.response.headers.contentType = ContentTypes.TEXT_PLAIN;
      request.response.writeln("$body ${new DateTime.now()}");
      request.response.writeln("Работает! | 作品 | práce");
    })
    ..onGet("/api/get", (request, params) {
      while(true);
      request.response.writeln("GOT");
    });
  }
}