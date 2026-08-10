// stub for non-web platforms
class JsContext {
  dynamic callMethod(String method, [List? args]) => null;
  bool hasProperty(String property) => false;
}

final context = JsContext();
