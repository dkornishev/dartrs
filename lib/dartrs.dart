library dartrs;

import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'dart:isolate';
import 'dart:mirrors';
import 'dart:convert';
import 'package:log4dart/log4dart.dart';

part 'src/cross_isolate.dart';
part 'src/server.dart';
part 'src/rsmeta.dart';

class ContentTypes {
  static final APPLICATION_JSON =  new ContentType("application", "json", charset: "utf-8");
  static final TEXT_PLAIN =  new ContentType("text", "plain", charset: "utf-8");
  static final TEXT_HTML =  new ContentType("text", "html", charset: "utf-8");
}

void _isolateLogic(initMessage) {
  var server = new RestfulServer();
  var init = initMessage["init"];
  init.call(server);

  var command = new ReceivePort();
  SendPort sp = initMessage["initPort"];
  sp.send(command.sendPort);

  command.listen((process) {
    var reply = process["reply"];
    IsolateRequest request = process["request"];

    var inbound = new ReceivePort();
    reply.send(inbound.sendPort);

    request.inbound = inbound.takeWhile(_untilDone);

    server._handle(request).whenComplete(() {
      reply.send(request.response);
    });
  });
}

void _wsLogic(initMessage) {
  var server = new RestfulServer();
  var init = initMessage["init"];
  init(server);

  var inPort = new ReceivePort();
  SendPort outPort = initMessage["outPort"];
  outPort.send(inPort.sendPort);

  var path = initMessage["path"];
  var handler = server._wsHandlerFor(path);
  inPort.listen((data) {
    if(data is _DoneEvent) {
      inPort.close();
    } else {
      var resp = handler(data);
      outPort.send(resp);
    }
  });
}

class _DoneEvent {}

bool _untilDone(event) {
  return !(event is _DoneEvent);
}

final _log = LoggerFactory.getLoggerFor(RestfulServer);