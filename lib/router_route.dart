part of router;

class _RouterRouteCommon {

  /// Named params in this route
  final List<String> namedParams;

  /// Routes for each available langs
  final Map<String, RouterRouteLang> routes = {};
  
  _RouterRouteCommon(this.namedParams);
  
  int get namedParamsCount => namedParams.length;
  
  RouterRouteLang operator [](String lang) => routes[lang];
  operator []=(String lang, RouterRouteLang route) => routes[lang]=route;
}

class RouterRouteSegment extends _RouterRouteCommon {

  /// Routes
  final List<_RouterRouteCommon> subRoutes = [];
  
  /// Default route, if no other is found. Can be null
  RouterRoute _defaultRoute;
  
  RouterRoute get defaultRoute => _defaultRoute;
  
  RouterRouteSegment(List<String> namedParams) : super(namedParams);
  
  setDefaultRoute(RouterRoute defaultRoute) => _defaultRoute = defaultRoute;
}

class RouterRoute extends _RouterRouteCommon {
  /// Controller name
  final String controller;
  
  /// Action name
  final String action;
  
  /// Optionnal extension
  final bool extension;

  RouterRoute(this.controller, this.action, this.extension, List<String> namedParams)
    : super(namedParams);
}

/// A representation of a route for a specific lang
class RouterRouteLang {
  /// The regExp
  final RegExp regExp;
  
  /// The route, with %s instead of params
  final String strf;
  
  RouterRouteLang(this.regExp, String strf):
      this.strf = strf == '/' ? '/' : strf.replaceFirst(new RegExp(r'\/+$'),'');
  
  Match match(String input) => regExp.firstMatch(input);
}