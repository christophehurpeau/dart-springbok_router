import 'dart:io';
import 'package:unittest/unittest.dart';
import 'package:yaml/yaml.dart' as Yaml;

import 'package:springbok_router/router.dart';

void main(){
  String routesConfig = new File('../example/routes.yaml').readAsStringSync();
  String routesLangsConfig = new File('../example/routesLangs.yaml').readAsStringSync();
  
  RoutesTranslations rt = new RoutesTranslations(Yaml.loadYaml(routesLangsConfig));
  
  test('Route translations', (){
    expect(rt.translate('login', 'fr'), 'connexion');
    expect(rt.untranslate('connexion', 'fr'), 'login');
  });
  
  
  Router router = new Router(rt, Yaml.loadYaml(routesConfig), ['en', 'fr']);
  
  test('Simple route',(){
    RouterRoute rr = router.get('/');
    assert(rr != null);
    expect(rr.controller, 'Site');
    expect(rr.action, 'Index');
    expect(rr.paramsCount, 0);
    var en = rr['en'];
    expect(en.regExp.pattern,r'^/$');
    expect(en.strf,'/');
    var fr = rr['fr'];
    expect(fr.regExp.pattern,r'^/$');
    expect(fr.strf,'/');
  });
  
  test('Common route', (){
    RouterRoute rr = router.get('/:controller(/:action/*)?');
    assert(rr != null);
    expect(rr.controller, 'Site');
    expect(rr.action, 'Index');
    expect(rr.paramsCount, 2);
    expect(rr.paramsNames, ['controller', 'action']);
    var en = rr['en'];
    expect(en.regExp.pattern,r'^/([^/]+)(?:/([^/]+))?(?:\.html)?$');
    expect(en.strf,'/%s/%s/%s');
    var fr = rr['fr'];
    expect(fr.regExp.pattern,r'^/([^/]+)(?:/([^/]+))?(?:\.html)?$');
    expect(fr.strf,'/%s/%s/%s');
  });
  
  test('Named param route', (){
    RouterRoute rr = router.get('/post/:slug');
    assert(rr != null);
    expect(rr.controller, 'Post');
    expect(rr.action, 'View');
    expect(rr.paramsCount, 1);
    expect(rr.paramsNames, ['slug']);
    var en = rr['en'];
    expect(en.regExp.pattern,r'^/post/([^/]+)\.htm$');
    expect(en.strf,'/post/%s');
    var fr = rr['fr'];
    expect(fr.regExp.pattern,r'^/article/([^/]+)\.htm$');
    expect(fr.strf,'/post/%s');
  });
  
  test('Find routes', (){
    
  });
}
