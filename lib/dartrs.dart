library dartrs;

import 'dart:io';
import 'dart:mirrors';
import 'dart:async';

import 'package:utf/utf.dart';
import 'package:logging_handlers/server_logging_handlers.dart';

part 'src/server.dart';

Future<RestfulServer> startrs({String host: '127.0.0.1', int port: 8080}) {
  return new RestfulServer().listen(host: host, port: port);
}