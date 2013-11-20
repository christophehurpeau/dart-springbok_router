[![Build Status](https://drone.io/github.com/christophehurpeau/dart-springbok_router/status.png)](https://drone.io/github.com/christophehurpeau/dart-springbok_router/latest)

### How to use

```
main(){
  final RoutesTranslations routesTranslations = new RoutesTranslations(
        loadYaml(new File('$configPath/routesTranslations.yaml').readAsStringSync()));
  final Router router = new Router(routesTranslations,
      loadYaml(new File('$configPath/routes.yaml').readAsStringSync()),
      config['allLangs']);

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