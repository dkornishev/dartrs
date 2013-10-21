import 'package:unittest/unittest.dart';
import '../lib/dartrs.dart';
import 'dart:async';
import 'dart:io';
import 'dart:utf';
import "package:logging/logging.dart";
import 'package:logging_handlers/server_logging_handlers.dart';


void main() {
  Logger.root.onRecord.listen(new PrintHandler());
 
  group("", () {
    var server;
    server = new RestfulServer();
    server
      ..onGet("/echo", (request, params) => request.response.write("ECHO"))
      ..onGet("/api/{arg1}/{arg2}", (request, params) => request.response.write(params))
      ..onHead("/head", (request, params) => request.response.headers.add("X-Test", "SUCCESS"))
      ..onOptions("/options", (request, uriParams) => request.response.headers.add("X-Test-Options", "SUCCESS"))
      ..onDelete("/delete", (request, uriParams) => request.response.statusCode=HttpStatus.NO_CONTENT)        
      ..onPatch("/patch", (request, uriParams, body) => request.response.statusCode=HttpStatus.NO_CONTENT)        
      ..onPost("/post", (request, uriParams, body) => request.response.statusCode=HttpStatus.CREATED)        
      ..onPut("/put", (request, uriParams, body) => request.response.statusCode=HttpStatus.NO_CONTENT);
      
    //***
    setUp(() {});

    //***
    //tearDown(() => server.close());
    
    //***
    test("Not Found", () {
      call("GET","/not_there", (resp) {
        expect(resp.statusCode, equals(HttpStatus.NOT_FOUND));
      });
    });
    
    test("GET", () {
      call("GET","/echo", (resp) {
        expect(resp.statusCode, equals(HttpStatus.OK));
        parseBody(resp).then(expectAsync1((value) {
          expect(value, equals("ECHO"));  
        }));        
      });
    });
    
    test("Get with Uri params", () {
      call("GET","/api/go/home", (resp) {
        expect(resp.statusCode, equals(HttpStatus.OK));
        parseBody(resp).then(expectAsync1((value) {
          expect(value, equals("{arg1: go, arg2: home}"));  
        }));        
      });
    });
    
    test("Head", () {
      call("HEAD","/head", expectAsync1((HttpClientResponse resp) {
        expect(resp.headers["X-Test"], equals(["SUCCESS"]));  
      }));
    });
    
    test("Opions", () {
      call("OPTIONS","/options", expectAsync1((HttpClientResponse resp) {
        expect(resp.headers["X-Test-Options"], equals(["SUCCESS"]));  
      }));
    });

    test("Delete", () {
      call("DELETE","/delete", expectAsync1((HttpClientResponse resp) {
        expect(resp.statusCode, equals(HttpStatus.NO_CONTENT));  
      }));
    });
    
    test("Patch", () {
      call("PATCH","/patch", expectAsync1((HttpClientResponse resp) {
        expect(resp.statusCode, equals(HttpStatus.NO_CONTENT));  
      }));
    });

    test("Post", () {
      call("PUT","/put", expectAsync1((HttpClientResponse resp) {
        expect(resp.statusCode, equals(HttpStatus.NO_CONTENT));  
      }));
    });

    test("Post", () {
      call("POST","/post", expectAsync1((HttpClientResponse resp) {
        expect(resp.statusCode, equals(HttpStatus.CREATED));  
      }));
    });

    
    new Timer(new Duration(seconds:1), () => server.close());
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

Future<String> parseBody(response) {
  return response.transform(new Utf8DecoderTransformer()).join();
}

void call(method, uri, callback) {
  HttpClient cl = new HttpClient();

  cl.open(method, "127.0.0.1", 8080, uri).then((HttpClientRequest req) {
    return req.close();
  }).then(callback);
}