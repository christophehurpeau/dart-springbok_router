library router;

part './router_route.dart';
part './route.dart';
part './routes_translations.dart';

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
      Map<String, String> routeLangs = route.length > 2 ? route[2] : null;
      String extension = route.length > 3 ? route[3] : null;
      
      // -- Route langs --
      
      if (routeLangs != null && routeLangs.length != 0) {
        for (String lang in allLangs) {
          if (!routeLangs.containsKey(lang)) {
            if (lang == 'en') routeLangs['en'] = routeKey;
            else throw new Exception('Missing lang "$lang" for route "$routeKey"');
          }
        }
      } else {
        if (routeLangs == null) {
          routeLangs = {};
        }
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
          new RouterRoute(controllerAndAction[0], controllerAndAction[1], paramNames);
      
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
          (extension == 'html' ? r'(?:\.html)?': r'\.' + extension);
        
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
          
          return '([^\/]+)';
        });
        var routeLangStrf = routeLang.replaceAll(new RegExp(r'(\:[a-zA-Z_]+)'),'%s')
            .replaceAll(new RegExp(r'[\?\(\)]+'),'')
            .replaceAll('/*','%s')
            .trim()
            .replaceFirst(new RegExp(r'\/+$'),'');
        if(routeLangStrf == '') {
          routeLangStrf = '/';
        }
        finalRoute[lang] = new RouterRouteLang(new RegExp('^${replacedRegExp}${extensionRegExp}\$'), routeLangStrf);
      });
      
    });
  }
}