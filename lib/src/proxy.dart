part of dartrs;

class RestfulRequest extends HttpRequest {

  ReceivePort _inbound;

  String method;
  Uri uri;
  HttpHeaders headers;

  String parsedBody;

  RestfulResponse response;

  RestfulRequest(this._inbound);

  StreamSubscription<List<int>> listen(void onData(List<int> event), {Function onError, void onDone(), bool cancelOnError}) {
    return _inbound.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

class RestfulResponse implements HttpResponse {
  SendPort _outbound;
  HttpHeaders headers;
  int statusCode;

  RestfulResponse(this._outbound, this.headers);

  void write(String message) {
    _outbound.add(message.codeUnits);
  }

  void writeln(String message) {
    _outbound.add(message.codeUnits);
  }

  void add(message) {
    _outbound.add(message);
  }

  void addError(errorEvent) {
    _outbound.addError(errorEvent);
  }

  void close() {
    _outbound.close();
  }
}