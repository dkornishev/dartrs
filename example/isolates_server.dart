library dartrs_example;

import '../lib/dartrs.dart';
import 'dart:async';
import 'dart:io';

void main() {

  RestfulServer.bind(init:new MyInit(), concurrency: 8).then((server) {
   
  });

  new Timer(new Duration(milliseconds: 200), () {
    WebSocket.connect("ws://127.0.0.1:8080/ws").then((socket) {
      socket.add("привет");
      socket.listen((data) {
        print(data);
      });
    });
  });

  new Timer(new Duration(milliseconds: 200), () {
    WebSocket.connect("ws://127.0.0.1:8080/ws/sound").then((socket) {
      socket.add("привет звук");
    });
  });

}

class MyInit {
  call(RestfulServer server) {
    print("initializing server");
    server
    ..onWs("/ws", (data) {
      print("WS: $data");
      return "ACK $data";
    })
    ..onWs("/ws/sound", (data) {
      print("WS sound: $data");
    })
    ..onPost("/api/isolate", (request, params, body) {
      request.response.statusCode = "777";
      request.response.headers.add("X-TEST", "WORKS");
      request.response.headers.contentType = ContentTypes.TEXT_PLAIN;
      request.response.writeln("$body ${new DateTime.now()}");
      request.response.writeln("Работает! | 作品 | práce");
    })
    ..onGet("/api/get", (request, params) {
      request.listen((data) {
        while(true);
      });
      while(true);
      request.response.writeln("GOT");
    });
  }
}