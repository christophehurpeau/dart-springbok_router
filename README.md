[![Build Status](https://drone.io/github.com/christophehurpeau/dart-springbok_router/status.png)](https://drone.io/github.com/christophehurpeau/dart-springbok_router/latest)

See the [auto-generated docs](http://christophehurpeau.github.io/dart-springbok_router/docs/router.html)

### How to use


```
import 'dart:io';
import 'dart:async';
import 'package:springbok_router/router.dart';
import 'package:yaml/yaml.dart';


main(){
  String routesLangsConfig = new File('../example/routesLangs.yaml').readAsStringSync();
  RoutesTranslations routesTranslations = new RoutesTranslations(Yaml.loadYaml(routesLangsConfig));
  
  RouterBuilder builder = new RouterBuilder(routesTranslations, ['en', 'fr']);
  
  builder
    ..add('/', '/', 'Site.index')
    ..add('postView', '/post/:id-:slug', 'Post.view',
        namedParamsDefinition: {'slug': r'[A-Za-z\-]+'},
        extension: 'htm')

    ..addDefaultRoutes();
  
  final router = builder.router;
    
  HttpServer.bind(HOST, PORT).then((HttpServer server) {
    server.listen((HttpRequest request) {
      try {
        Route route = router.find(request.uri.path);
        // now you should have
      } catch(e) {
        // it the route was not found : e is RouteNotFoundException
      }
    });
  });
}
```