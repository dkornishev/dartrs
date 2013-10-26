part of dartrs;

/**
 * Restful Server implementation
 */
class RestfulServer {

  static final NOT_FOUND = new Endpoint("NOT_FOUND", "", (HttpRequest request, params) {
    request.response.statusCode = HttpStatus.NOT_FOUND;
    request.response.write("No handler for requested resource found");
  });

  /**
   * Static method to create new restful servers
   * This is more consistent stylistically with the sdk
   */
  static Future<RestfulServer> bind({String host:"127.0.0.1", int port:8080}) {
    var server = new RestfulServer();
    return server.listen(host: host, port: port);
  }
  
  /**
   * Static method to create new tls restful servers
   * This is more consistent stylistically with the sdk
   */
  static Future<RestfulServer> bindSecure({String host:"127.0.0.1", int port:8443, String certificateName}) {
    var server = new RestfulServer();
    return server.listenSecure(host: host, port: port, certificateName: certificateName);
  }
  
  List<Endpoint> _endpoints = [];
  HttpServer _server;
  
  /**
   * The global pre-processor.
   * 
   * Currently this method has to execute synchronously and should not
   * return a future.
   */
  Function preProcessor = (request) {
    request.response.headers.add(HttpHeaders.CACHE_CONTROL, "no-cache, no-store, must-revalidate");
  };
  
  /**
   * The global post-processor. Note that you should not try to modify
   * immutable headers here, which is the case if any output has already
   * been written to the response.
   * 
   * Currently this method has to execute synchronously and should not
   * return a future.
   */
  Function postProcessor = (request) {};
  
  /**
   * The global error handler.
   */
  Function onError = (e, request) {
    request.response.statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
    request.response.writeln(e.toString());
  };  

  /**
   * Creates a new [RestfulServer]. Start the server afterwards with
   * `listen()` or `listenSecure()`.
   * Also registers the default OPTIONS endpoint.
   */
  RestfulServer() {
    var endpoint = new Endpoint.root("OPTIONS", (request, params) {
      _endpoints.forEach((Endpoint e) {
        request.response.writeln("$e");
      });
    });
    
    _endpoints.add(endpoint);
  }
  
  /**
   * Starts this server on the given host and port.
   */
  Future<RestfulServer> listen({String host:"127.0.0.1", int port:8080}) {
    return HttpServer.bind(host, port).then((server) {
      info("Server listening on $host:$port...");  
      _logic(server);
      return this;
    });
  }
  
  /**
   * Starts this server on the given host and port (in secure mode).
   */
  Future<RestfulServer> listenSecure({String host:"127.0.0.1", int port:8443, String certificateName}) {
    return HttpServer.bindSecure(host, port, certificateName: certificateName).then((server) {
      info("Server listening on $host:$port (secured)...");  
      _logic(server);
      return this;
    });
  }
  
  /**
   * Performs a context scan and creates endpoints from annotated methods found
   */
  void contextScan() {
    var mirrors = currentMirrorSystem();
    mirrors.libraries.forEach((_, LibraryMirror lib) {
      lib.functions.values.forEach((MethodMirror method) {
        
        var verb = null;
        var path = null;
        method.metadata.forEach((InstanceMirror im) {
          
          if(im.reflectee is _HttpMethod) {
            verb = im.reflectee.name;
          }
          
          if(im.reflectee is Path) {
            path = im.reflectee.path;
          }
        });
        
        if(verb != null && path !=null) {
          if(method.parameters.length == 2) {
            _endpoints.add(new Endpoint(verb, path, (request, uriParams)=>lib.invoke(method.simpleName, [request, uriParams]))); 
            info("Added endpoint $verb:$path");
          } else if(method.parameters.length == 3) {
            _endpoints.add(new Endpoint(verb, path, (request, uriParams, body)=>lib.invoke(method.simpleName, [request, uriParams, body]))); 
            info("Added endpoint $verb:$path");
          } else {
            error("Not adding annotated method ${method.simpleName} as it has wrong number of arguments (Must be 2 or 3)");  
          }
        }
      });
    });
  }
  
  /**
   *   
  */
  void _logic(HttpServer server) {
    _server = server;

    server.listen((HttpRequest request) {
      Stopwatch sw = new Stopwatch()..start();
      
      // Wrap to avoid mixing of sync and async errors..
      new Future.sync(() {
        // Pre-process

        preProcessor(request); // Could throw
        
        // Find and endpoint
        var endpoint = _endpoints.firstWhere((Endpoint e) => e.canService(request), orElse:() => NOT_FOUND);
        info("Match: ${request.method}:${request.uri} to ${endpoint}");
        
        // Then post-process
        return endpoint.service(request).then((_) => postProcessor(request));
      })
      // If an error occurred, handle it.
      .catchError((e, stack) {
        error("Server error: $e \n $stack");
        onError(e, request);
        })
      // At the end, always close the request's response and log the request time.
      .whenComplete(() {
        request.response.close();
        sw.stop();
        info("Call to ${request.method} ${request.uri} ended in ${sw.elapsedMilliseconds} ms");
        });
    });
  }
  
  /**
   * Shuts down this server.
   */
  Future close() {
    return _server.close().then((server) => info("Server is now stopped"));  
  }
  
  /**
   * Services GET calls
   * [handler] should take (HttpRequest, Map)
   */
  void onGet(String uri, handler(HttpRequest req, Map uriParams)) {
    _endpoints.add(new Endpoint("GET", uri, handler));

    info("Added endpoint GET:$uri");
  }

  /**
   * Services POST calls
   * [handler] can take be either (HttpRequest, Map)
   * or (HttpRequest, Map, body).  In latter case, 
   * request body will be parsed and passed in 
   */
  void onPost(String uri, handler) {
    _endpoints.add(new Endpoint("POST", uri, handler));

    info("Added endpoint POST:$uri");
  }
  
  /**
   * Services PUT calls
   * [handler] can take be either (HttpRequest, Map)
   * or (HttpRequest, Map, body).  In latter case, 
   * request body will be parsed and passed in 
   */
  void onPut(String uri, handler) {
    _endpoints.add(new Endpoint("PUT", uri, handler));

    info("Added endpoint PUT:$uri");
  }
  
  /**
   * Services PATCH calls
   * [handler] can take be either (HttpRequest, Map)
   * or (HttpRequest, Map, body).  In latter case, 
   * request body will be parsed and passed in 
   */
  void onPatch(String uri, handler) {
    _endpoints.add(new Endpoint("PATCH", uri, handler));

    info("Added endpoint Patch:$uri");
  }
  
  void onDelete(String uri, handler(HttpRequest req, Map uriParams)) {
    _endpoints.add(new Endpoint("DELETE", uri, handler));

    info("Added endpoint DELETE:$uri");
  }

  void onHead(String uri, handler(HttpRequest req, Map uriParams)) {
    _endpoints.add(new Endpoint("HEAD", uri, handler));

    info("Added endpoint HEAD:$uri");
  }

  void onOptions(String uri, handler(HttpRequest req, Map uriParams)) {
    _endpoints.add(new Endpoint("OPTIONS", uri, handler));

    info("Added endpoint OPTIONS:$uri");
  }
}

/**
 * Holds information about a restful endpoint
 */
class Endpoint {

  static final URI_PARAM = new RegExp(r"{(\w+?)}");

  final String _method, _path;

  Function _handler;

  RegExp _uriMatch;
  List _uriParamNames = [];
  
  bool _parseBody;

  /**
   * Creates a new endpoint.
   */
  Endpoint(String method, this._path, this._handler): this._method = method.toUpperCase() {
    _uriParamNames = [];
    
    String regexp = _path.replaceAllMapped(URI_PARAM, (Match m) {
      _uriParamNames.add(m.group(1));
      return r"(\w+)";
    });
    
    _uriMatch = new RegExp(regexp);
    _parseBody = _hasMoreThan2Parameters(_handler);
  }
  
  /**
   * Creates an endpoint for the root path.
   * Matches one `/` or an empty path.
   */
  Endpoint.root(String method, this._handler):
    this._method = method.toUpperCase(),
    this._path = "/",
    this._uriMatch = new RegExp(r'(^$|^(/)$)') {
    _parseBody = _hasMoreThan2Parameters(_handler);
  }
  
  bool _hasMoreThan2Parameters(handler) {
    return (reflect(handler) as ClosureMirror).function.parameters.length>2;
  }

  /**
   *  Replies if this endpoint can service incoming request
   */
  bool canService(HttpRequest req) {
    return _method == req.method.toUpperCase() && _uriMatch.hasMatch(req.uri.path);
  }
  
  Future service(HttpRequest req) {
    // Wrap in Future.sync() to avoid mixing of sync and async errors.
    return new Future.sync(() {
      // Extract URI params
      var uriParams = {};
      if (_uriParamNames.isNotEmpty) {
        var match = _uriMatch.firstMatch(req.uri.path);
        for(var i = 0; i < match.groupCount; i++) {
          String group = match.group(i+1);
          uriParams[_uriParamNames[i]] = group;
        }
      }
      
      debug("Got params: $uriParams");
      
      // Handle request
      Future future = _parseBody ? req.transform(new Utf8DecoderTransformer()).join() : new Future.sync(() => null);
    
      return future.then((body) {
        if(body != null) {
          _handler(req, uriParams, body); // Could throw
        } else {
          _handler(req, uriParams); // Could throw
        }      
      });
    });
  }
  
  String toString() => '$_method $_path';
}

class ContentTypes {
  static final APPLICATION_JSON =  new ContentType("application", "json", charset: "utf-8");
  static final TEXT_PLAIN =  new ContentType("text", "plain", charset: "utf-8");
}