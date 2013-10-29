import 'package:dartrs/dartrs.dart';


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
  RestfulServer.bind().then((server) {
    server
      ..contextScan();
  });
}
