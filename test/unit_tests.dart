import 'package:unittest/unittest.dart';
import '../restful/restful_server.dart';
import 'dart:async';
import 'dart:io';
import 'dart:utf';
import "package:logging/logging.dart";
import 'package:logging_handlers/server_logging_handlers.dart';


void main() {
  Logger.root.onRecord.listen(new PrintHandler());
 
  group("Positive Tests", () {
    var server;
    
    //***
    setUp(() {
      server = new RestfulServer();
      server
      ..onGet("/echo", (request, params) => request.response.write("ECHO"))
      ..onHead("/head", (request, params) => request.response.headers.add("X-Test", "SUCCESS"));


    });

    //***
    tearDown(() => server.close());
    
    //***
    test("Echo", () {
      get("/echo", expectAsync1((value) {
        expect(value, equals("ECHO"));  
      }));
    });
    
    test("Head", () {
      head("/head", expectAsync1((HttpClientResponse resp) {
        expect(resp.headers["X-Test"], equals(["SUCCESS"]));  
      }));
    });
  });
}

void get(uri, callback) {
  HttpClient cl = new HttpClient();

  cl.get("127.0.0.1", 8080, uri).then((HttpClientRequest req) {
    return req.close();
  }).then((HttpClientResponse resp) {
    resp.transform(new Utf8DecoderTransformer()).join().then(callback);
  });
}

void head(uri, callback) {
  HttpClient cl = new HttpClient();

  cl.open("HEAD","127.0.0.1", 8080, uri).then((HttpClientRequest req) {
    return req.close();
  }).then(callback);
}