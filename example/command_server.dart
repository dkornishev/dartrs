library dartrs_example;

import "dart:mirrors";
import "dart:json" as json;
import '../lib/dartrs.dart';
import "package:logging/logging.dart";
import 'package:logging_handlers/server_logging_handlers.dart';


/**
* Sample Restful server to demonstrate how a command-pattern implementation
* could be simply written
*
* This is pretty dangerous, as this lets anybody execute arbitrary functions
* on the server's vm
*/
void main() {
  Logger.root.onRecord.listen(new PrintHandler());

  var server;
  server = new RestfulServer();
  server
  ..onPost("/cmd/{command}", (request, uriParams, body) {
    var parsed = json.parse(body);
    var result = currentMirrorSystem().findLibrary(new Symbol("dartrs_example")).first.invoke(new Symbol(uriParams["command"]), [parsed]);
    request.response.write(result.reflectee);
  });
}

avg(Map body) {
  var sum =  body["numbers"].reduce((value, element) => value + element);
  return sum / body["numbers"].length;
}