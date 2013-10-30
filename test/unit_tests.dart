import 'dart:io';
import 'dart:async' show Future, Timer;
import 'dart:convert';

import 'package:dartrs/dartrs.dart';
import 'package:unittest/unittest.dart';
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
    
    RestfulServer.bindSecure(port: 8443, certificateName: "localhost_cert").then((server) {
      server..onGet("/secure", (request, params) => request.response.write("SECURE"));
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
      RestfulServer.bind().then((server) {
        server
          ..onGet("/echo", (request, params) => request.response.write("ECHO"))
          ..onGet("/api/{arg1}/{arg2}", (request, params) => request.response.write(params))
          ..onHead("/head", (request, params) => request.response.headers.add("X-Test", "SUCCESS"))
          ..onOptions("/options", (request, uriParams) => request.response.headers.add("X-Test-Options", "SUCCESS"))
          ..onDelete("/delete", (request, uriParams) => request.response.statusCode = HttpStatus.NO_CONTENT)
          ..onPatch("/patch", (request, uriParams, body) => request.response.statusCode = HttpStatus.NO_CONTENT)
          ..onPost("/post", (request, uriParams, body) => request.response.statusCode = HttpStatus.CREATED)
          ..onPut("/put", (request, uriParams, body) => request.response.statusCode = HttpStatus.NO_CONTENT);

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
    
    group("Pre- and Postprocessor Sync", () {
      const _groupPort = 8081;
      RestfulServer _rs;
      RestfulServer.bind(port:_groupPort).then((server) {
        _rs = server;
        server
          ..onPost("/post", (request, uriParams, body) => request.response.statusCode = HttpStatus.CREATED)
          ..preProcessor = ((HttpRequest req) => req.response.headers.add("X-Pre", true))
          ..postProcessor = ((HttpRequest req) => req.response.headers.add("X-Post", true));

        new Timer(new Duration(seconds:1), () => server.close());
      });
      
      test("Header Modification", () {
        call("POST", "/post", expectAsync1((resp) {
          expect(resp.statusCode, equals(HttpStatus.CREATED));
          expect(resp.headers.value("X-Pre"), equals("true"));
          expect(resp.headers.value("X-Post"), equals("true"));
        }), port:_groupPort);
      });
      
      test("Processor chaining", () {
        var pp = _rs.preProcessor;
        _rs.preProcessor = (req) {
          pp(req);
          req.response.headers.set("X-Pre", false);
        };
        call("POST", "/post", expectAsync1((resp) {
          expect(resp.statusCode, equals(HttpStatus.CREATED));
          expect(resp.headers.value("X-Pre"), equals("false"));
          expect(resp.headers.value("X-Post"), equals("true"));
        }), port:_groupPort);
      });
    });
    
    group("Async Handling 1", () {
      const _groupPort = 8082;
      RestfulServer.bind(port:_groupPort).then((server) {
        server
          // Sync handler
          ..onGet("/get", (request, uriParams) {
              request.response.headers.add("X-Test", "SUCCESS");
              request.response.writeln("some data");
            })
          // Async pre-processor
          ..preProcessor = ((HttpRequest req) {
              // Simulate long pre-processing with possibility of throwing an exception.
              return new Future.delayed(new Duration(milliseconds:300), () {
                req.response.headers.add("X-Pre", "true");
                if(req.uri.path.contains("failPre")) throw new StateError("Pre-processor exception.");
              });
            })
          // Sync post-processor
          ..postProcessor = ((HttpRequest req) {
              if (req.uri.path.contains("failPost")) throw new StateError("Post-processor exception.");
              req.response.writeln("some more data");
            });

        new Timer(new Duration(seconds:3), () => server.close());
      });
      
      test("Delayed pre-processing", () {
        call("GET", "/get", expectAsync1((resp) {
          expect(resp.statusCode, equals(HttpStatus.OK));
          expect(resp.headers.value("X-Pre"), equals("true"));
          expect(resp.headers.value("X-Test"), equals("SUCCESS"));
          parseBody(resp).then(expectAsync1((value) {
            expect(value, contains("some data"));
            expect(value, contains("some more data"));
          }));
        }), port:_groupPort);
      });
      
      test("Pre-processing exception", () {
        call("GET", "/get/failPre", expectAsync1((resp) {
          expect(resp.statusCode, equals(HttpStatus.INTERNAL_SERVER_ERROR));
          expect(resp.headers.value("X-Pre"), equals("true"));
          expect(resp.headers.value("X-Test"), isNull);
          parseBody(resp).then(expectAsync1((value) {
            expect(value, contains("Pre-processor exception."));
          }));
        }), port:_groupPort);
      });
      
      test("Post-processing exception", () {
        call("GET", "/get/failPost", expectAsync1((resp) {
          // HTTP status is immutable after content is written to response
          //expect(resp.statusCode, equals(HttpStatus.INTERNAL_SERVER_ERROR));
          expect(resp.headers.value("X-Pre"), equals("true"));
          expect(resp.headers.value("X-Test"), equals("SUCCESS"));
          parseBody(resp).then(expectAsync1((value) {
            expect(value, contains("Post-processor exception."));
            expect(value.contains("some more data"), isFalse);
          }));
        }), port:_groupPort);
      });
    });
    
    group("Async Handling 2", () {
      const _groupPort = 8083;
      RestfulServer.bind(port:_groupPort).then((server) {
        server
          // Async handler
          ..onGet("/get", (req, uriParams) {
              return new Future.delayed(new Duration(milliseconds:200), () {
                req.response.headers.add("X-Test", "SUCCESS");
                req.response.writeln("some data");
              });
            })
          // Sync pre-processor
          ..preProcessor = ((HttpRequest req) {
              // Simulate long pre-processing with possibility of throwing an exception.
              // Why not calculate 10000! here? Should take a while!
              var f = 1;
              for (int i = 1; i < 10001; i++) {f*=i;};
              req.response.headers.add("X-Pre", true);
              if(req.uri.path.contains("failPre")) throw new StateError("Pre-processor exception.");
            })
          // Async post-processor
          ..postProcessor = ((HttpRequest req) {
              return new Future.delayed(new Duration(milliseconds:100), () {
                if(req.uri.path.contains("failPost")) throw new StateError("Post-processor exception.");
                req.response.writeln("some more data");
              });
            });

        new Timer(new Duration(seconds:4), () => server.close());
      });
      
      test("Delayed pre-processing", () {
        call("GET", "/get", expectAsync1((resp) {
          expect(resp.statusCode, equals(HttpStatus.OK));
          expect(resp.headers.value("X-Pre"), equals("true"));
          expect(resp.headers.value("X-Test"), equals("SUCCESS"));
          parseBody(resp).then(expectAsync1((value) {
            expect(value, contains("some data"));
            expect(value, contains("some more data"));
          }));
        }), port:_groupPort);
      });
      
      test("Pre-processing exception", () {
        call("GET", "/get/failPre", expectAsync1((resp) {
          expect(resp.statusCode, equals(HttpStatus.INTERNAL_SERVER_ERROR));
          expect(resp.headers.value("X-Test"), isNull);
          parseBody(resp).then(expectAsync1((value) {
            expect(value, contains("Pre-processor exception."));
          }));
        }), port:_groupPort);
      });
      
      test("Post-processing exception", () {
        call("GET", "/get/failPost", expectAsync1((resp) {
          // HTTP status is immutable after content is written to response
          //expect(resp.statusCode, equals(HttpStatus.INTERNAL_SERVER_ERROR));
          expect(resp.headers.value("X-Pre"), equals("true"));
          expect(resp.headers.value("X-Test"), equals("SUCCESS"));
          parseBody(resp).then(expectAsync1((value) {
            expect(value, contains("Post-processor exception."));
            expect(value.contains("some more data"), isFalse);
          }));
        }), port:_groupPort);
      });
    });
  });
  
  group("Scanner", () {
    const _groupPort = 8084;
    RestfulServer.bind(port: _groupPort).then((server) {
      server
        ..contextScan();
      new Timer(new Duration(seconds:5), () => server.close());
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

  cl.get(host, port, path)
    .then((HttpClientRequest req) => req.close())
    .then((HttpClientResponse resp) {
      parseBody(resp).then(callback);
    });
}

Future<String> parseBody(response) {
  return response.transform(new Utf8Decoder()).join();
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