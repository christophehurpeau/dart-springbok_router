part of router;

// The route for a request
class Route{
  /// The all part of the route. Same as request.uri.path, but cleanified
  final String all;
  
  /// Controller name
  final String controller;
  
  /// Action name
  final String action;
  
  /// Extension of the request
  final String extension;
  
  /// Named params
  final Map<String, String> namedParams;
  
  /// Others simple params
  final List<String> otherParams;
  
  Route(this.all, this.controller, this.action, this.namedParams, this.otherParams, this.extension);
}
