Dart Restful Webserver 
======================

[![Build Status](https://drone.io/github.com/dkornishev/dartrs/status.png)](https://drone.io/github.com/dkornishev/dartrs/latest)

A server to make development of restful webservices easy and fun

Getting Started
---------------

```dart
var server = new RestfulServer();
server
  ..onGet("/echo", (request, params) => request.response.write("ECHO"))
  ..listen();
```

or

```dart
startrs().then((server) => server.onGet("/echo", (request, params) => request.response.write("ECHO")));
```

POST/PUT/PATCH will handle parsing the body if provided callback has three parameters
```dart
  ..onPost("/post", (request, uriParams, body) => request.response.statusCode=HttpStatus.CREATED)   
```
Pre processing handler can be registed which will be invoked on every request
```dart
var old = server.preProcessor;
  
server.preProcessor = (request) {
    request.response.headers.contentType = ContentTypes.APPLICATION_JSON;
    old(request);
  };
```

HTTPS (SSL/TLS)
---------------
Good folks at google decided to go with NSS see (https://developer.mozilla.org/en-US/docs/NSS/Tools) 
and documentation on SecureSocket.initialize(..)
Luckily, default tests have a functioning key pair, which have been appropriated for testing needs (test/pkcert)
```dart
SecureSocket.initialize(database: "pkcert", password: 'dartdart', useBuiltinRoots: false);
new RestfulServer()
  ..onGet("/secure", (request, params) => request.response.write("SECURE"))
  ..listenSecure(port: 8443, certificateName: "localhost_cert").then((server) {
    print("I am sooo secure now");        
  });
```

Annotations and Context Scan
-------------------
Jaxrs-style annotations and bootstrap via a library scanner:
```dart
@Path("/hello")
@GET
void echo(request, params) {
  request.response.write("hi");
}

var server = new RestfulServer();
server
  ..contextScan()
  ..listen(port: _groupPort).then((server) {
      print("Endpoints are loaded from annotated methods.  Hoorah metadata.");
  });

```

Default Endpoints
-----------------
By default the server will list all registered endpoints if you issue:
```
OPTIONS /
```


Logging
-------
To see server messages you need to init logging_handlers
```dart
Logger.root.onRecord.listen(new PrintHandler());
```
