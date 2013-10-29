import 'dart:io';
import 'dart:async' show Future;
import 'package:dartrs/dartrs.dart';


Stopwatch sw;

/**
 * Sample Restful server to demonstrate the use of sync and async handlers.
 * 
 * Any handler can return a Future if necessary.
 */
void main() {
  RestfulServer.bind().then((RestfulServer server) {
    server
      ..preProcessor = asyncPreProcessor
      ..postProcessor = syncPostProcessor
      ..onGet("/hello/{userName}", asyncHandler);
  });
}

/**
 * An async pre-processor could fetch data from a database or remote URL.
 */
Future asyncPreProcessor(HttpRequest req) {
  sw = new Stopwatch();
  sw.start();
  return new Future.delayed(new Duration(seconds:1), () {
    req.response.statusCode = HttpStatus.OK;
    req.response.headers.contentType = ContentTypes.TEXT_HTML;
    req.response.headers.add("X-Test", "SUCCESS");
  });
}

/**
 * An example handler.
 */
Future asyncHandler(req, uriParams) {
  return new Future.delayed(new Duration(milliseconds:100), () {
    req.response.writeln("<p>Hello ${uriParams["userName"]}!</p>");
  });
}

/**
 * For simple tasks, a synchronous processor is sufficient.
 */
void syncPostProcessor(req) {
  sw.stop();
  req.response.writeln('<p><i>Page was generated in ${sw.elapsedMilliseconds} ms.</i></p>');
}