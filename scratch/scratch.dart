import "dart:isolate";
import "dart:async";
import "dart:io";

void main() {
  HttpServer.bind("127.0.0.1", 8080).then((server) {
    server.listen((HttpRequest request) {
      if(WebSocketTransformer.isUpgradeRequest(request)) {
        print("Ура!  $request");
        WebSocketTransformer.upgrade(request).then((sws) {
          
          SendPort sp;
          ReceivePort rp = new ReceivePort();
          Isolate.spawn(wsRunner, rp.sendPort).then((iss) {
            rp.listen((data) {
              if(data is SendPort) {
                sp = data;  
                sws.listen((data) {
                  sp.send(data);
                });
              } else {
                sws.add(data);
              }
            });
          });
        });
      }
    });
  }).whenComplete(() {
    WebSocket.connect("ws://127.0.0.1:8080/ws").then((WebSocket ws) {
      ws.listen((data) {
        print(data);
      });
      ws.add("ЗДАРОВА1");
      ws.add("ЗДАРОВА2");
      ws.add("ЗДАРОВА3");
      ws.add("ЗДАРОВА4");
      ws.add("ЗДАРОВА5");
      ws.add("DONE");
    });
  });
}

void wsRunner(SendPort sp) {
  ReceivePort rp = new ReceivePort();
  
  sp.send(rp.sendPort);
  
  rp.listen((data) {
    print(data);
    sp.send("ACK $data");
  });
}