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
-----------
Good folks at google decided to go with NSS see (https://developer.mozilla.org/en-US/docs/NSS/Tools) 
and documentation on SecureSocket.initialize(..)
Luckily, default tests have a functioning key pair, which have been appropriated for testing needs (test/pkcert)
```dart
SecureSocket.initialize(database: "pkcert", password: 'dartdart', useBuiltinRoots: false);
var server = new RestfulServer.secure(port: 8443, certificateName: "localhost_cert");
```

Logging
-------
To see server messages you need to init logging_handlers
```dart
Logger.root.onRecord.listen(new PrintHandler());
```
