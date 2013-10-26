library dartrs;

import 'dart:io';
import 'dart:mirrors';
import 'dart:async';

import 'package:utf/utf.dart' show Utf8DecoderTransformer;
import 'package:logging_handlers/server_logging_handlers.dart';

part 'src/server.dart';
part 'src/rsmeta.dart';

/**
 * Starts a [RestfulServer] and returns a future.
 */
Future<RestfulServer> startrs({String host: '127.0.0.1', int port: 8080}) {
  return RestfulServer.bind(host: host, port: port);
}

class ContentTypes {
  static final APPLICATION_JSON =  new ContentType("application", "json", charset: "utf-8");
  static final TEXT_PLAIN =  new ContentType("text", "plain", charset: "utf-8");
}
