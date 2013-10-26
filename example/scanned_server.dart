import 'package:dartrs/dartrs.dart';
import "package:logging/logging.dart";
import 'package:logging_handlers/server_logging_handlers.dart';

@GET
@Path("/scan/root")
void root(request, params) {
  request.response.headers.contentType = ContentTypes.TEXT_PLAIN;
  request.response.write("ЭВРИКА");  
}

@POST
@Path("/scan/post")
void echoPost(request, params, body) {
  request.response.write("$body");  
}

void main() {
  Logger.root.onRecord.listen(new PrintHandler());

  RestfulServer.bind().then((server) {
    server
      ..contextScan();
  });
}
