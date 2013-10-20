Dart Restful Webserver 
======================

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

To see server messages you need to init logging_handlers
```dart
  Logger.root.onRecord.listen(new PrintHandler());
```