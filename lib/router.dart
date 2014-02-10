library router;

part './router_route.dart';
part './router_builder.dart';
part './route.dart';
part './routes_translations.dart';

final regExpStartingSlash = new RegExp(r'^/+');
final regExpEndingSlash = new RegExp(r'/+$');

/// http://code.google.com/p/dart/issues/detail?id=1694
String stringFormat(String string, List<String> args) {
  int i = 0;
  return string.replaceAllMapped('%s', (Match m) => args[i++]);
}

class RouteNotFoundException implements Exception{
  final String path;

  RouteNotFoundException(this.path);

  String toString() => "This path was not found : ${this.path}";
}

class Router {
  final Map<String, RouterRoute> _routesMap = {};
  final List<_RouterRouteCommon> _routes = [];
  final RoutesTranslations _routesTranslations;

  // tests only
  _RouterRouteCommon get(String key) => _routesMap[key];

  Router(this._routesTranslations);

  _addRoute(String routeKey, _RouterRouteCommon route) {
    if (route is RouterRoute) {
      _addInternalRoute(routeKey, route);
    }
    _routes.add(route);
  }

  _addInternalRoute(String routeKey, RouterRoute route) {
    assert(!_routesMap.containsKey(routeKey));
    _routesMap[routeKey] = route;
  }


  Route find(String path, [String lang = 'en']){
    path = '/' + path.trim().replaceFirst(regExpStartingSlash,'').replaceFirst(regExpEndingSlash,'');

    return _findRoute(_routes, path, path, lang);
  }

  Route _findRoute(Iterable<_RouterRouteCommon> routes, String completePath, String path, String lang, [Map<String, String> namedParams]) {
    assert(lang != null);
    for(_RouterRouteCommon route_common in routes) {
      RouterRouteLang routeLang = route_common[lang];
      assert(routeLang != null);
      print('trying ${routeLang.regExp}');

      Match match = routeLang.match(path);
      if (match == null) continue;

      int groupCount = match.groupCount;

      if (route_common is RouterRouteSegment) {
        RouterRouteSegment route = route_common;

        final String restOfThePath = match[groupCount--];

        //Copy/paste... argh I hate that !

        if(route.namedParamsCount != 0) {
          // set params
          if (namedParams == null) {
            namedParams = new Map();
          }

          int group = 1;
          for (String paramName in route.namedParams) {
            String value = match[group++];
            if(value != null && value.isNotEmpty) {
              namedParams[paramName] = value;
            }

            if (namedParams.isEmpty) {
              namedParams = null;
            }
          }

          if (route.defaultRoute != null) {
            try {
              return _findRoute(route.subRoutes, completePath, restOfThePath, lang, namedParams);
            } on RouteNotFoundException catch (e) {
              return _createRoute(completePath, lang, route.defaultRoute, null, 0, namedParams);
            }
          } else {
            return _findRoute(route.subRoutes, completePath, restOfThePath, lang, namedParams);
          }
        }
      } else {
        RouterRoute route = route_common as RouterRoute;
        return _createRoute(completePath, lang, route, match, groupCount, namedParams);
      }
    }

    throw new RouteNotFoundException(path);
  }


  Route _createRoute(String completePath, String lang, RouterRoute route, Match match, int groupCount, Map namedParams){
    int group = 1;

    final extension = groupCount == 0 || route.extension == null ? null : match[groupCount--];

    String controller = route.controller, action = route.action;

    List<String> otherParams;

    if(route.namedParamsCount != 0) {
      // set params
      if (namedParams == null) {
        namedParams = new Map();
      }

      for (String paramName in route.namedParams) {
        String value = match[group++];
        if(value != null && value.isNotEmpty) {
          namedParams[paramName] = value;
        }
      }

      if (namedParams.isEmpty) {
        namedParams = null;
      }
    }

    if (namedParams != null) {
      // Replace controller and action if needed
      if (namedParams.containsKey('controller')) {
        controller = _routesTranslations.untranslate(namedParams['controller'], lang);
        controller = controller[0].toUpperCase() + controller.substring(1);
        // Should we remove it ?
        namedParams.remove('controller');
      }
      if (namedParams.containsKey('action')) {
        action = _routesTranslations.untranslate(namedParams['action'], lang);
        // Should we remove it ?
        namedParams.remove('action');
      }

      if (namedParams.isEmpty) {
        namedParams = null;
      }
    }


    // The only not-named param can be /*
    if (group == groupCount && match[group] != null) {
      otherParams = match[group].split('/');
    }

    return new Route(completePath, controller, action, namedParams, otherParams, extension);
  }

  String createLink(String lang, String routeKey, { List params,
                              String ext, String query, String hash }) {
    RouterRoute route = _routesMap[routeKey];

    String plus = '';
    if (ext != null) {
      plus = '.$ext';
    } else if (route.extension != null) {

    }
        (ext == null ? '' : '.$ext')
      + '';

    String link = route.routes[lang].strf;
    link = stringFormat(link, params.map(
        (param) => _routesTranslations.translate(param, lang)));
    return (link == '/' ? link : link.replaceFirst(regExpEndingSlash, '')) + plus;
  }
}