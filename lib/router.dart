library router;

part './router_route.dart';
part './route.dart';
part './routes_translations.dart';

final regExpStartingSlash = new RegExp(r'^/+');
final regExpEndingSlash = new RegExp(r'/+$');

class Router {
  final Map<String, RouterRoute> _routes = {};
  final RoutesTranslations _routesTranslations;
  
  // tests only
  RouterRoute get(String key) => _routes[key];
  
  Router(this._routesTranslations, Map<String, List> routes, [List<String> allLangs]){
    if (allLangs == null) {
      allLangs = ['en'];
    }
    
    final RegExp regExpNamedParam = new RegExp(r'(\(\?)?\:([a-zA-Z_]+)');
    final RegExp translatableRoutePart = new RegExp(r'/([a-zA-Z\_]+)');
    final RegExp translatableRouteNamedParamValue = new RegExp(r'^[a-zA-Z\|\_]+$');
    
    final Function translate = (String lang, String string){
      String lstring = string.toLowerCase();
      String translation = _routesTranslations.translate(string, lang);
      assert(translation != null);
      return translation;
    };
    
    routes.forEach((String routeKey, List route){
      // route: [ 'Site.index', { 'namedParam': '...' }, { 'fr': 'special route for lang fr' }, 'extension' ]
      
      List<String> controllerAndAction = route[0].split('.');
      assert(controllerAndAction.length == 2);
      
      Map<String, String> namedParamsDefinition = route.length > 1 ? route[1] : null;
      final Map<String, String> routeLangs = route.length > 2 ? (route[2] == null ? {} : route[2]) : {};
      final String extension = route.length > 3 ? route[3] : null;
      
      // -- Route langs --
      
      if (routeLangs.isNotEmpty) {
        for (String lang in allLangs) {
          if (!routeLangs.containsKey(lang)) {
            if (lang == 'en') routeLangs['en'] = routeKey;
            else throw new Exception('Missing lang "$lang" for route "$routeKey"');
          }
        }
      } else {
        if (!translatableRoutePart.hasMatch(routeKey)) {
          for (String lang in allLangs) routeLangs[lang] = routeKey;
        } else {
          for (String lang in allLangs) {
            routeLangs[lang] = routeKey.replaceAllMapped(translatableRoutePart,
                  (Match m) => '/'+translate(lang,m[1]));
          }
        }
      }

      var paramNames = <String>[];
      regExpNamedParam.allMatches(routeLangs[allLangs[0]])
        .forEach((Match m) => paramNames.add(m[2]));
      
      var finalRoute = _routes[routeKey] = 
          new RouterRoute(controllerAndAction[0], controllerAndAction[1], extension != null, paramNames);
      
      routeLangs.forEach((String lang, String routeLang){
        bool specialEnd, specialEnd2;
        String routeLangRegExp;
        
        if (specialEnd = routeLang.endsWith('/*')) {
          routeLangRegExp = routeLang.substring(0, routeLang.length-2);
        } else if (specialEnd2 = routeLang.endsWith('/*)?')) {
          routeLangRegExp = routeLang.substring(0, routeLang.length-4)
              + routeLang.substring(routeLang.length-2);
        } else {
          routeLangRegExp = routeLang;
        }
        
        routeLangRegExp = routeLangRegExp
            .replaceAll('-',r'\-')
            .replaceAll('*',r'(.*)')
            .replaceAll('(',r'(?:');
        
        final String extensionRegExp = extension == null ? '': 
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
        if(routeLangStrf == '') {
          routeLangStrf = '/';
        }
        finalRoute[lang] = new RouterRouteLang(new RegExp('^${replacedRegExp}${extensionRegExp}\$'), routeLangStrf);
      });
      
    });
  }
  
  
  Route find(String all, [String lang = 'en']){
    all = '/' + all.trim().replaceFirst(regExpStartingSlash,'').replaceFirst(regExpEndingSlash,'');
    
    for(RouterRoute route in _routes.values) { //_routes.values vs _routes.forEach ?
      RouterRouteLang routeLang = route[lang];
      assert(routeLang != null);
      
      Match match = routeLang.match(all);
      if (match == null) continue;
      
      int groupCount = match.groupCount;
      final extension = groupCount == 0 || !route.extension ? null : match[groupCount--];
      
      String controller = route.controller, action = route.action;
      
      Map<String, String> namedParams;
      List<String> otherParams;
      
      if(route.namedParamsCount != 0) {
        // set params
        namedParams = new Map();
        int group = 1;
        for (String paramName in route.namedParams) {
          String value = match[group++];
          if(value != null && value.isNotEmpty) {
            namedParams[paramName] = value;
          }
        }
        
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
        
        // The only not-named param can be /* (I think)
        if (group == groupCount) {
          otherParams = match[group].split('/');
        }
      }
      
      return new Route(all, controller, action, namedParams, otherParams, extension);
    }
  }
}