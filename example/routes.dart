import 'dart:io';
import 'package:yaml/yaml.dart' as Yaml;
import 'package:springbok_router/router.dart';

Router createRouter() {
  String routesLangsConfig = new File('../example/routesLangs.yaml').readAsStringSync();
  RoutesTranslations routesTranslations = new RoutesTranslations(Yaml.loadYaml(routesLangsConfig));

  RouterBuilder builder = new RouterBuilder(routesTranslations, ['en', 'fr']);

  builder
    ..add('/', '/', 'Site.index')
    ..add('postView', '/post/:id-:slug', 'Post.view',
        namedParamsDefinition: {'slug': r'[A-Za-z\-]+'},
        extension: 'htm')

    ..addDefaultRoutes();

  return builder.router;
}