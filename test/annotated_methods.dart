import 'dart:io';
import "package:dartrs/dartrs.dart";

@GET
@Path("/scan/root")
void service(request, params) {
  request.response.write("ЭВРИКА");  
}

@POST
@Path("/scan/post")
void post(request, params, body) {
  request.response.statusCode = HttpStatus.CREATED;
  request.response.write("$body");  
}

@DELETE
@Path("/scan/delete")
void delete(request, params) {
  request.response.statusCode = HttpStatus.NO_CONTENT;
  request.response.write("DELETED");  
}