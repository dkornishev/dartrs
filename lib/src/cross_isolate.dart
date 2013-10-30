part of dartrs;

class IsolateRequest implements HttpRequest {

  Stream inbound;

  String method;
  Uri uri;
  HttpHeaders headers;

  String parsedBody;

  IsolateResponse response;

  IsolateRequest();

  StreamTransformer transformer;

  IsolateRequest.fromHttpRequest(HttpRequest request) {
    method = request.method;
    uri = request.uri;
    headers = request.headers;
  }

  Stream transform(StreamTransformer<T, dynamic> streamTransformer) {
    return streamTransformer.bind(inbound);
  }

  StreamSubscription<List<int>> listen(void onData(List<int> event), {Function onError, void onDone(), bool cancelOnError}) {
    return inbound.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

class IsolateResponse implements HttpResponse {
  SendPort _outbound;
  HttpHeaders headers;
  int statusCode;

  IsolateResponse();

  IsolateResponse.fromHttpResponse(HttpResponse response, SendPort outbound) {
    this.headers = response.headers;
    this.statusCode = response.statusCode;
    this._outbound = outbound;
  }

  void write(message) {
    _outbound.send(UTF8.encode(message.toString()));
  }

  void writeln(message) {
    _outbound.send(UTF8.encode(message.toString() + "\n"));
  }

  void add(message) {
    _outbound.send(message);
  }

  void addError(errorEvent) {
    _outbound.send(errorEvent);
  }

  Future close() {
    _outbound.send(new _DoneEvent());
    return new Future.value(this);
  }
}