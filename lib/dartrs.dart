library dartrs;

import 'dart:io';
import 'dart:mirrors';
import 'dart:async';
import 'dart:isolate';

import 'package:utf/utf.dart' show Utf8DecoderTransformer;
import 'package:log4dart/log4dart.dart';

part 'src/server.dart';
part 'src/rsmeta.dart';
part 'src/proxy.dart';

class ContentTypes {
  static final APPLICATION_JSON =  new ContentType("application", "json", charset: "utf-8");
  static final TEXT_PLAIN =  new ContentType("text", "plain", charset: "utf-8");
  static final TEXT_HTML =  new ContentType("text", "html", charset: "utf-8");
}

void isolateLogic(RestfulServer server) {
  port.receive((message, replyTo) {
    var incomingBody = new MessageBox();
    replyTo.send(incomingBody.sink);
    var outSink = message["bodySink"];
    IsolateSink headerSink = message["headerSink"];
    
    var response = new RestfulResponse(outSink, message["responseHeaders"]);
    var request = new RestfulRequest(incomingBody.stream)
      ..response = response
      ..headers = message["requestHeaders"]
      ..method = message["method"]
      ..uri = message["uri"];
    
    server._handleRequest(request).whenComplete(() {
      headerSink.add(request.response.headers);
      headerSink.close();
      outSink.close();
    });  
    
    
//    HttpHeaders headers = message["responseHeaders"];
//    headers.add("X-Rated", "false");
//    headers.add("XXX-Rated", "false");
//    headers.contentType = ContentTypes.APPLICATION_JSON;

//    incomingBody.stream.listen((data) {
//      print(new String.fromCharCodes(data));      
//    }).onDone(() {
//      print("DONE");
//      outSink.add("Hurrah".codeUnits);
//      outSink.close();
//      port.close();
//    });

  });
}