import 'dart:io';
import 'dart:async' show Future, Timer;
import 'package:utf/utf.dart' show Utf8DecoderTransformer;
import 'package:dartrs/dartrs.dart';
import 'package:unittest/unittest.dart';
import "package:logging/logging.dart";
import 'package:logging_handlers/server_logging_handlers.dart';


void main() {
  Logger.root.onRecord.listen(new PrintHandler());

  group("TLS Server", () {
    SecureSocket.initialize(database: "pkcert", password: 'dartdart', useBuiltinRoots: false);

    var server;
    server = new RestfulServer.secure(port: 8443, certificateName: "localhost_cert");
    server..onGet("/secure", (request, params) => request.response.write("SECURE"));

    test("TLS GET", () {
      getUri(Uri.parse("https://127.0.0.1:8443/secure"), expectAsync1((resp) {
        expect(resp.statusCode, equals(HttpStatus.OK));
        parseBody(resp).then(expectAsync1((value) {
          expect(value, equals("SECURE"));
        }));
      }));
    });

    new Timer(new Duration(seconds:1), () => server.close());
  });

  group("", () {
    var server;
    server = new RestfulServer();
    server..onGet("/echo", (request, params) => request.response.write("ECHO"))..onGet("/api/{arg1}/{arg2}", (request, params) => request.response.write(params))..onHead("/head", (request, params) => request.response.headers.add("X-Test", "SUCCESS"))..onOptions("/options", (request, uriParams) => request.response.headers.add("X-Test-Options", "SUCCESS"))..onDelete("/delete", (request, uriParams) => request.response.statusCode = HttpStatus.NO_CONTENT)..onPatch("/patch", (request, uriParams, body) => request.response.statusCode = HttpStatus.NO_CONTENT)..onPost("/post", (request, uriParams, body) => request.response.statusCode = HttpStatus.CREATED)..onPut("/put", (request, uriParams, body) => request.response.statusCode = HttpStatus.NO_CONTENT);

//***
    setUp(() {
    });

//***
//tearDown(() => server.close());

//***
    test("Not Found", () {
      call("GET", "/not_there", expectAsync1((resp) {
        expect(resp.statusCode, equals(HttpStatus.NOT_FOUND));
      }));
    });

    test("GET", () {
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

    test("Opions", () {
      call("OPTIONS", "/options", expectAsync1((HttpClientResponse resp) {
        expect(resp.headers["X-Test-Options"], equals(["SUCCESS"]));
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


    new Timer(new Duration(seconds:1), () => server.close());
  });
}

void get(path, callback) {
  HttpClient cl = new HttpClient();

  cl.get("127.0.0.1", 8080, path).then((HttpClientRequest req) {
    return req.close();
  }).then((HttpClientResponse resp) {
    resp.transform(new Utf8DecoderTransformer()).join().then(callback);
  });
}

Future<String> parseBody(response) {
  return response.transform(new Utf8DecoderTransformer()).join();
}

void call(method, path, callback, {port:8080}) {
  HttpClient cl = new HttpClient();

  cl.open(method, "127.0.0.1", port, path).then((HttpClientRequest req) {
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