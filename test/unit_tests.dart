import 'dart:io';
import 'dart:async' show Future, Timer;

import 'package:utf/utf.dart' show Utf8DecoderTransformer;
import 'package:dartrs/dartrs.dart';
import 'package:unittest/unittest.dart';
import 'package:logging/logging.dart';
import 'package:logging_handlers/server_logging_handlers.dart';
import 'package:unittest/mock.dart';

import 'annotated_methods.dart';

class MockHttpRequest extends Mock implements HttpRequest {
  MockHttpRequest(String method, String uri) {
    when(callsTo('get method')).alwaysReturn(method);
    when(callsTo('get uri')).alwaysReturn(Uri.parse(uri));
  }
}
class MockHttpResponse extends Mock implements HttpResponse {}

void main() {
  Logger.root.onRecord.listen(new PrintHandler());
  
  group("Endpoint", () {
    test("Match Simple", () {
      Endpoint e = new Endpoint("get", "/test", (_) => null);
      var req = new MockHttpRequest("GET", "http://localhost/test");
      expect(e.canService(req), isTrue);
      
      req = new MockHttpRequest("GET", "http://localhost/test/another");
      expect(e.canService(req), isTrue);
      
      e = new Endpoint("get", "/test", (_) => null);
      req = new MockHttpRequest("GET", "http://localhost/");
      expect(e.canService(req), isFalse);
    });
    
    test("Match Root", () {
      Endpoint e = new Endpoint.root("get", (_) => null);
      var req = new MockHttpRequest("GET", "http://localhost/");
      expect(e.canService(req), isTrue);
      
      req = new MockHttpRequest("GET", "http://localhost");
      expect(e.canService(req), isTrue);
      
      req = new MockHttpRequest("GET", "http://localhost/test");
      expect(e.canService(req), isFalse);
    });
  });
  
  group("TLS Server", () {
    SecureSocket.initialize(database: "test/pkcert", password: 'dartdart', useBuiltinRoots: false);
    
    new RestfulServer()
      ..onGet("/secure", (request, params) => request.response.write("SECURE"))
      ..listenSecure(port: 8443, certificateName: "localhost_cert").then((server) {
          new Timer(new Duration(seconds:1), () => server.close());
        });
    
    test("TLS GET", () {
      getUri(Uri.parse("https://127.0.0.1:8443/secure"), expectAsync1((resp) {
        expect(resp.statusCode, equals(HttpStatus.OK));
        parseBody(resp).then(expectAsync1((value) {
          expect(value, equals("SECURE"));
        }));
      }));
    });
  });

  group("Server", () {
    group("Basic Requests", () {
      new RestfulServer()
      ..onGet("/echo", (request, params) => request.response.write("ECHO"))
      ..onGet("/api/{arg1}/{arg2}", (request, params) => request.response.write(params))
      ..onHead("/head", (request, params) => request.response.headers.add("X-Test", "SUCCESS"))
      ..onOptions("/options", (request, uriParams) => request.response.headers.add("X-Test-Options", "SUCCESS"))
      ..onDelete("/delete", (request, uriParams) => request.response.statusCode = HttpStatus.NO_CONTENT)
      ..onPatch("/patch", (request, uriParams, body) => request.response.statusCode = HttpStatus.NO_CONTENT)
      ..onPost("/post", (request, uriParams, body) => request.response.statusCode = HttpStatus.CREATED)
      ..onPut("/put", (request, uriParams, body) => request.response.statusCode = HttpStatus.NO_CONTENT)
      ..listen().then((server) {
          new Timer(new Duration(seconds:1), () => server.close());
        });
      
      test("Not Found", () {
        call("GET", "/not_there", expectAsync1((resp) {
          expect(resp.statusCode, equals(HttpStatus.NOT_FOUND));
        }));
      });
  
      test("Get", () {
        call("GET", "/echo", expectAsync1((resp) {
          expect(resp.statusCode, equals(HttpStatus.OK));
          parseBody(resp).then(expectAsync1((value) {
            expect(value, equals("ECHO"));
          }));
        }));
      });
  
      test("Get with Uri params", () {
        call("GET", "/api/go/home", expectAsync1((resp) {
          expect(resp.statusCode, equals(HttpStatus.OK));
          parseBody(resp).then(expectAsync1((value) {
            expect(value, equals("{arg1: go, arg2: home}"));
          }));
        }));
      });
  
      test("Head", () {
        call("HEAD", "/head", expectAsync1((HttpClientResponse resp) {
          expect(resp.headers["X-Test"], equals(["SUCCESS"]));
        }));
      });
  
      test("Options", () {
        call("OPTIONS", "/options", expectAsync1((HttpClientResponse resp) {
          expect(resp.headers["X-Test-Options"], equals(["SUCCESS"]));
        }));
      });
  
      test("Options Default", () {
        call("OPTIONS", "/", expectAsync1((HttpClientResponse resp) {
          parseBody(resp).then(expectAsync1((value) {
            expect(resp.statusCode, equals(HttpStatus.OK));
            expect(value, contains("GET /echo"));
          }));
        }));
      });
      
      test("Delete", () {
        call("DELETE", "/delete", expectAsync1((HttpClientResponse resp) {
          expect(resp.statusCode, equals(HttpStatus.NO_CONTENT));
        }));
      });
  
      test("Patch", () {
        call("PATCH", "/patch", expectAsync1((HttpClientResponse resp) {
          expect(resp.statusCode, equals(HttpStatus.NO_CONTENT));
        }));
      });
  
      test("Put", () {
        call("PUT", "/put", expectAsync1((HttpClientResponse resp) {
          expect(resp.statusCode, equals(HttpStatus.NO_CONTENT));
        }));
      });
  
      test("Post", () {
        call("POST", "/post", expectAsync1((HttpClientResponse resp) {
          expect(resp.statusCode, equals(HttpStatus.CREATED));
        }));
      });
    });
    
    group("Pre- and Postprocessor", () {
      const _groupPort = 8081;
      new RestfulServer()
        ..onPost("/post", (request, uriParams, body) => request.response.statusCode = HttpStatus.CREATED)
        ..preProcessor = ((HttpRequest req) => req.response.headers.add("PP", true))
        ..postProcessor = ((HttpRequest req) => req.response.headers.add("PP2", true))
        ..listen(port:_groupPort).then((server) {
          new Timer(new Duration(seconds:1), () => server.close());
        });
      
      test("Header Modification", () {
        call("POST", "/post", expectAsync1((resp) {
          expect(resp.statusCode, equals(HttpStatus.CREATED));
          expect(resp.headers.value("PP"), equals("true"));
          expect(resp.headers.value("PP2"), equals("true"));
        }), port:_groupPort);
      });
    });
  });
  
  group("Scanner", () {
    const _groupPort = 8082;
    var server = new RestfulServer();
    server
    ..contextScan()
    ..listen(port: _groupPort).then((server) {
      new Timer(new Duration(seconds:1), () => server.close());
    });
    
    test("Not Found", () {
      call("GET", "/scan/not_there", expectAsync1((resp) {
        expect(resp.statusCode, equals(HttpStatus.NOT_FOUND));
      }), port: _groupPort);
    });
    
    test("GET", () {
      call("GET", "/scan/root", expectAsync1((resp) {
        expect(resp.statusCode, equals(HttpStatus.OK));
      }), port: _groupPort);
    });
    
    test("Post", () {
      call("POST", "/scan/post", expectAsync1((HttpClientResponse resp) {
        expect(resp.statusCode, equals(HttpStatus.CREATED));
      }), port: _groupPort);
    });
    
    test("Delete", () {
      call("DELETE", "/scan/delete", expectAsync1((HttpClientResponse resp) {
        expect(resp.statusCode, equals(HttpStatus.NO_CONTENT));
      }), port: _groupPort);
    });
  });
}

void get(path, callback, {host:"127.0.0.1", port:8080}) {
  HttpClient cl = new HttpClient();

  cl.get(host, port, path).then((HttpClientRequest req) {
    return req.close();
  }).then((HttpClientResponse resp) {
    resp.transform(new Utf8DecoderTransformer()).join().then(callback);
  });
}

Future<String> parseBody(response) {
  return response.transform(new Utf8DecoderTransformer()).join();
}

void call(method, path, callback, {host:"127.0.0.1", port:8080}) {
  HttpClient cl = new HttpClient();

  cl.open(method, host, port, path).then((HttpClientRequest req) {
    return req.close();
  }).then(callback);
}

void getUri(uri, callback) {
  HttpClient client = new HttpClient();
  client.badCertificateCallback = (X509Certificate cert, String host, int port) {
    return true;
  };

  client.getUrl(uri).then((req) {
    return req.close();
  }).then(callback);
}