part of dartrs;

const GET     = const _GET();
const POST    = const _POST();
const PUT     = const _PUT();
const DELETE  = const _DELETE();
const PATCH   = const _PATCH();
const HEAD    = const _HEAD();
const OPTIONS = const _OPTIONS();

class _HttpMethod {
  const _HttpMethod();
}

class _GET extends _HttpMethod {
  final String name = "GET";
  
  const _GET();
}

class _POST extends _HttpMethod {
  final String name = "POST";
  
  const _POST();
}


class _PUT extends _HttpMethod {
  final String name = "PUT";
  
  const _PUT();
}

class _DELETE extends _HttpMethod {
  final String name = "DELETE";
  
  const _DELETE();
}

class _PATCH extends _HttpMethod {
  final String name = "PATCH";
  
  const _PATCH();
}

class _HEAD extends _HttpMethod {
  final String name = "HEAD";
  
  const _HEAD();
}

class _OPTIONS extends _HttpMethod {
  final String name = "OPTIONS";
  
  const _OPTIONS();
}


class Path {
  final String path;
  
  const Path(this.path);
}