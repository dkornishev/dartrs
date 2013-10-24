library dartrs;

import "dart:io";
import 'dart:utf';
import "dart:mirrors";

import "package:logging_handlers/server_logging_handlers.dart";
import 'dart:async';

/**
 * Restful Server implementation
 */
class RestfulServer {

  static final NOT_FOUND = new _Endpoint("", "", (HttpRequest request, params) {
    request.response.statusCode = HttpStatus.NOT_FOUND;
    request.response.write("No handler for requested resource found");
  });

  List<_Endpoint> _endpoints = [];
  HttpServer _server;
  
  Function preProcessor = (request){
    request.response.headers.add(HttpHeaders.CACHE_CONTROL, "no-cache, no-store, must-revalidate");
  };
  
  Function postProcessor = (request) {};
  
  Function onError = (e, request) {
    request.response.statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
    request.response.write("Unexpected boom");
  };  

  RestfulServer({var host:"127.0.0.1", int port:8080}) {
    HttpServer.bind(host, port).then(_logic);
  }

  RestfulServer.secure({var host:"127.0.0.1", int port:8080, String certificateName}) {
    HttpServer.bindSecure(host, port, certificateName: certificateName).then(_logic);
  }

  
  /**
   *   
   */
  void _logic(HttpServer server) {
    info("Server started...");  
    
    _server = server;

    this.onOptions("/", (request, params) {
      _endpoints.forEach((_Endpoint e) {
        request.response.write("${e.method} ${e.uri}\n");
      });
    });

    server.listen((HttpRequest request) {
      Stopwatch sw = new Stopwatch();
      
      sw.start();
      
      try {
        preProcessor(request);
        
        var endpoint = _endpoints.firstWhere((_Endpoint e) => e._canService(request), orElse:() => NOT_FOUND);
        
        var match = endpoint._uriMatch.firstMatch(request.uri.path);
        
        var uriParams = {};
        for(var i = 1; i <= match.groupCount; i++) {
          uriParams[endpoint._uriParamNames[i-1]]=match.group(i);
        }
        
        debug("invoking ${endpoint.uri} with params $uriParams");
        
        Future future = new Future.sync(() => null);
        if(endpoint._parseBody) {
          future = request.transform(new Utf8DecoderTransformer()).join();
        }
        
        future.then((body) {
          if(body != null) {
            endpoint.handler(request, uriParams, body);
          } else {
            endpoint.handler(request, uriParams);
          }
          
          postProcessor(request);
          
          request.response.close();
          
          sw.stop();
          
          info("Call to ${request.method} ${request.uri} ended in ${sw.elapsedMilliseconds} ms");
          
        }); 
      } catch(e, trace) {
        error("Server error $e \n $trace");
        onError(e, request);
        
        request.response.close();
      }
    });
  }
  
  void close() {
    _server.close().then((server) => info("Server is now stopped"));  
    
  }
  
  void onGet(String uri, handler(HttpRequest req, Map uriParams)) {
    _endpoints.add(new _Endpoint("GET", uri, handler));

    info("Added endpoint GET:$uri");
  }

  /**
   * Services POST calls
   * [handler] can take be either (HttpRequest, Map)
   * or (HttpRequest, Map, body).  In latter case, 
   * request body will be parsed and passed in 
   */
  void onPost(String uri, handler) {
    _endpoints.add(new _Endpoint("POST", uri, handler));

    info("Added endpoint POST:$uri");
  }
  
  /**
   * Services PUT calls
   * [handler] can take be either (HttpRequest, Map)
   * or (HttpRequest, Map, body).  In latter case, 
   * request body will be parsed and passed in 
   */
  void onPut(String uri, handler) {
    _endpoints.add(new _Endpoint("PUT", uri, handler));

    info("Added endpoint PUT:$uri");
  }
  
  /**
   * Services PATCH calls
   * [handler] can take be either (HttpRequest, Map)
   * or (HttpRequest, Map, body).  In latter case, 
   * request body will be parsed and passed in 
   */
  void onPatch(String uri, handler) {
    _endpoints.add(new _Endpoint("PATCH", uri, handler));

    info("Added endpoint Patch:$uri");
  }
  
  void onDelete(String uri, handler(HttpRequest req, Map uriParams)) {
    _endpoints.add(new _Endpoint("DELETE", uri, handler));

    info("Added endpoint DELETE:$uri");
  }

  void onHead(String uri, handler(HttpRequest req, Map uriParams)) {
    _endpoints.add(new _Endpoint("HEAD", uri, handler));

    info("Added endpoint HEAD:$uri");
  }

  void onOptions(String uri, handler(HttpRequest req, Map uriParams)) {
    _endpoints.add(new _Endpoint("OPTIONS", uri, handler));

    info("Added endpoint OPTIONS:$uri");
  }
}

/**
 * Holds information about a restful endpoint
 */
class _Endpoint {

  static final URI_FRAGMENT = new RegExp(r"{(\w+?)}");

  String method;

  String uri;

  Function handler;

  RegExp _uriMatch;

  List _uriParamNames;
  
  bool _parseBody;

  _Endpoint(this.method, this.uri, this.handler) {
    _uriParamNames = [];

    String regexp = uri.splitMapJoin(URI_FRAGMENT, onMatch: (Match m) {
      _uriParamNames.add(m.group(1));
      return r"(\w+)";
    });

    _uriMatch = new RegExp(regexp);
    
    _parseBody = reflect(handler).function.parameters.length>2;
  }

  /**
   *  Replies if this endpoint can service incoming request
   */
  bool _canService(HttpRequest req) {
    return method == req.method.toUpperCase() && _uriMatch.hasMatch(req.uri.path);
  }
}

class ContentTypes {
  static final APPLICATION_JSON =  new ContentType("application", "json", charset: "utf-8");
  static final TEXT_PLAIN =  new ContentType("text", "plain", charset: "utf-8");
}