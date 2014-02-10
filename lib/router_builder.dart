part of router;

class RouterBuilder {
  final Router router;

  final List<String> _allLangs;


  final RegExp regExpNamedParam = new RegExp(r'(\(\?)?\:([a-zA-Z_]+)');
  final RegExp translatableRoutePart = new RegExp(r'/([a-zA-Z\_]+)');
  final RegExp translatableRouteNamedParamValue = new RegExp(r'^[a-zA-Z\|\_]+$');

  final RoutesTranslations _routesTranslations;

  RouterBuilder(RoutesTranslations routesTranslations, this._allLangs)
      : _routesTranslations = routesTranslations,
        router = new Router(routesTranslations);

  String translate(String lang, String string) {
    String lstring = string.toLowerCase();
    String translation = _routesTranslations.translate(string, lang);
    assert(translation != null);
    return translation;
  }

  fromMap(Map<String, List> routes) {
    routes.forEach((String routeKey, List route){
      // route: [ 'Site.index', { 'namedParam': '...' }, { 'fr': 'special route for lang fr' }, 'extension' ]

      add(routeKey, routeKey, route[0],
          namedParamsDefinition: route.length > 1 ? route[1] : null,
          routeLangs: route.length > 2 ? (route[2] == null ? {} : route[2]) : {},
          extension: route.length > 3 ? route[3] : null);
    });
  }

  // TODO next step : pass a Type !
  void add(String routeKey, String routeUrl,
           String controllerAndActionSeparatedByDot,
      { Map<String, String> namedParamsDefinition,
        Map<String, String> routeLangs,
        String extension
      }) {

    var route = _createRoute(false, null,routeUrl, controllerAndActionSeparatedByDot, namedParamsDefinition, routeLangs, extension);
    router._addRoute(routeKey, route);
  }

  void addSegment(String routeUrl, { Map<String, String> namedParamsDefinition,
          Map<String, String> routeLangs,
          buildSegment(RouterBuilderSegment segment)}) {
    RouterRouteSegment route = _createRouteSegment(null, routeUrl, namedParamsDefinition, routeLangs);
    var segment = new RouterBuilderSegment(this, route, null);
    buildSegment(segment);
    router._addRoute(null, route);
  }

  _RouterRouteCommon _createRouteSegment(RouterRouteSegment parent, String routeUrl, Map<String, String> namedParamsDefinition,
               Map<String, String> routeLangs) {
    return _createRoute(true, parent, routeUrl, null, namedParamsDefinition, routeLangs, null);
  }

  _RouterRouteCommon _createRoute(bool segment, RouterRouteSegment parent, String routeUrl, String controllerAndActionSeparatedByDot, Map<String, String> namedParamsDefinition,
               Map<String, String> routeLangs, String extension) {
    List<String> controllerAndAction;
    if (!segment) {
      controllerAndAction = controllerAndActionSeparatedByDot.split('.');
      assert(controllerAndAction.length == 2);
    }

    if (routeLangs == null) {
      routeLangs = {};
    }

    // -- Route langs --

    if (routeLangs.isNotEmpty) {
      for (String lang in _allLangs) {
        if (!routeLangs.containsKey(lang)) {
          if (lang == 'en') routeLangs['en'] = routeUrl;
          else throw new Exception('Missing lang "$lang" for route "$routeUrl"');
        }
      }
    } else {
      if (!translatableRoutePart.hasMatch(routeUrl)) {
        for (String lang in _allLangs) routeLangs[lang] = routeUrl;
      } else {
        for (String lang in _allLangs) {
          routeLangs[lang] = routeUrl.replaceAllMapped(translatableRoutePart,
              (Match m) => '/'+translate(lang,m[1]));
        }
      }
    }

    var paramNames = <String>[];
    regExpNamedParam.allMatches(routeLangs[_allLangs[0]])
      .forEach((Match m) => paramNames.add(m[2]));

    var finalRoute = segment ? new RouterRouteSegment(paramNames)
        : new RouterRoute(controllerAndAction[0], controllerAndAction[1], extension, paramNames);

    routeLangs.forEach((String lang, String routeLang){
      bool specialEnd = false, specialEnd2 = false;
      String routeLangRegExp;

      if (!segment && (specialEnd = routeLang.endsWith('/*'))) {
        routeLangRegExp = routeLang.substring(0, routeLang.length-2);
      } else if (!segment && (specialEnd2 = routeLang.endsWith(r'/*)?'))) {
        routeLangRegExp = routeLang.substring(0, routeLang.length-4)
            + routeLang.substring(routeLang.length-2);
      } else {
        routeLangRegExp = routeLang;
      }

      routeLangRegExp = routeLangRegExp
        .replaceAll('-',r'\-')
        .replaceAll('*',r'(.*)')
        .replaceAll('(',r'(?:');

      if (specialEnd) {
        routeLangRegExp = routeLangRegExp + r'(?:/([^\.]*))?';
      } else if (specialEnd2) {
        routeLangRegExp = routeLangRegExp.substring(0, routeLangRegExp.length - 2)
            + r'(?:/([^\.]*))?' + routeLangRegExp.substring(routeLangRegExp.length - 2);
      }

      final String extensionRegExp = segment || extension == null ? '':
        (extension == 'html' ? r'(?:\.(html))?': r'\.(' + '$extension)');

      var replacedRegExp = routeLangRegExp.replaceAllMapped(regExpNamedParam,(Match m){
        if (m[1] != null) return m[0];

        if (namedParamsDefinition != null && namedParamsDefinition.containsKey(m[2])) {
          var paramDefVal = namedParamsDefinition[m[2]];
          if (paramDefVal is Map) {
            paramDefVal = paramDefVal[lang];
            assert(paramDefVal != null);
          } else {
            if (translatableRouteNamedParamValue.hasMatch(paramDefVal)) {
              paramDefVal = paramDefVal.split('|')
                  .map((String s) => translate(lang, s)).join('|');
            }
          }
          return paramDefVal == 'id' ? r'([0-9]+)' : '(' + paramDefVal.replaceAll('(','(?:') + ')';
        }

        if (m[2] == 'id') {
          return r'([0-9]+)';
        }

        return r'([^/\.]+)';
      });
      var routeLangStrf = routeLang.replaceAll(new RegExp(r'(\:[a-zA-Z_]+)'),'%s')
          .replaceAll(new RegExp(r'[\?\(\)]+'),'')
          .replaceAll('/*','%s')
          .trim()
          .replaceFirst(regExpEndingSlash,'');

      if (parent != null) {
        routeLangStrf = parent.routes[lang].strf + routeLangStrf;
      }

      if(routeLangStrf == '') {
        routeLangStrf = '/';
      }
      finalRoute[lang] = new RouterRouteLang(
          new RegExp('^${replacedRegExp}${extensionRegExp}' + ( segment ? '(.*)\$' : '\$')),
          routeLangStrf
      );
    });

    return finalRoute;
  }

  addDefaultRoutes() {
    addSegment('/:controller', buildSegment: (RouterBuilderSegment segment) {
      segment
        ..add('default', '/:action/*', 'Site.index', extension: 'html')
        ..defaultRoute('defaultSimple', 'Site.index', extension: 'html');
    });
  }
}

class RouterBuilderSegment {
  final RouterBuilder builder;
  final RouterRouteSegment route;
  final RouterRouteSegment parent;

  RouterBuilderSegment(this.builder, this.route, this.parent);

  void add(String routeKey, String routeUrl,
           String controllerAndActionSeparatedByDot,
      { Map<String, String> namedParamsDefinition,
        Map<String, String> routeLangs,
        String extension}) {

    var route = builder._createRoute(false, this.route, routeUrl, controllerAndActionSeparatedByDot, namedParamsDefinition, routeLangs, extension);
    this.route.subRoutes.add(route);
    builder.router._addInternalRoute(routeKey, route);
  }

  void defaultRoute(String routeKey,
                    String controllerAndActionSeparatedByDot,
                    { Map<String, String> namedParamsDefinition,
                      Map<String, String> routeLangs,
                      String extension}) {
    var route = builder._createRoute(false, this.route, '', controllerAndActionSeparatedByDot, namedParamsDefinition, routeLangs, extension);
    builder.router._addInternalRoute(routeKey, route);
    this.route.subRoutes.add(route);
  }

  void addSegment(String routeUrl, { Map<String, String> namedParamsDefinition,
          Map<String, String> routeLangs,
          buildSegment(RouterBuilderSegment segment)}) {
    RouterRouteSegment route = builder._createRouteSegment(this.route, routeUrl, namedParamsDefinition, routeLangs);
    RouterBuilderSegment segment = new RouterBuilderSegment(builder, route, this.route);
    buildSegment(segment);
    this.route.subRoutes.add(segment.route);
  }
}