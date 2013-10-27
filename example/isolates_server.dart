import 'package:dartrs/dartrs.dart';
import "package:logging/logging.dart";
import 'package:logging_handlers/server_logging_handlers.dart';

void main() {
  Logger.root.onRecord.listen(new PrintHandler());

  RestfulServer.bind().then((server) {
    server
      ..numberIsolates=8
      ..isolateInit = concurrent;
  });
}

void concurrent() {
  Logger.root.onRecord.listen(new PrintHandler());

  var server = new RestfulServer()
    ..onPost("/api/isolate", (request, params, body) {
      request.response.headers.add("X-TEST", "WORKS");
      request.response.headers.contentType = ContentTypes.APPLICATION_JSON;
      request.response.write("EURIKA");    
    });
  
  isolateLogic(server);
}