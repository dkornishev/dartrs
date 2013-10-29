library dartrs;

import 'dart:io';
import 'dart:mirrors';
import 'dart:async';

import 'package:utf/utf.dart' show Utf8DecoderTransformer;
import 'package:log4dart/log4dart.dart';

part 'src/server.dart';
part 'src/rsmeta.dart';

class ContentTypes {
  static final APPLICATION_JSON =  new ContentType("application", "json", charset: "utf-8");
  static final TEXT_PLAIN =  new ContentType("text", "plain", charset: "utf-8");
  static final TEXT_HTML =  new ContentType("text", "html", charset: "utf-8");
}