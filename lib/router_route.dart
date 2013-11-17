part of router;

class RouterRoute {
  /// Controller name
  final String controller;
  
  /// Action name
  final String action;
  
  /// Number of named params in this route
  final List<String> paramsNames;
  
  final Map<String, RouterRouteLang> routes = {};
  
  RouterRoute(this.controller, this.action, this.paramsNames);
  
  int get paramsCount => paramsNames.length;
  
  RouterRouteLang operator [](String lang) => routes[lang];
  operator []=(String lang, RouterRouteLang route) => routes[lang]=route;
}

/// A representation of a route for a specific lang
class RouterRouteLang {
  /// The regExp
  final RegExp regExp;
  
  /// The route, with %s instead of params
  final String strf;
  
  RouterRouteLang(this.regExp, String strf):
      this.strf = strf == '/' ? '/' : strf.replaceFirst(new RegExp(r'\/+$'),'');
}