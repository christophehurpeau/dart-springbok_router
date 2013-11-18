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
    expect(rr.action, 'index');
    expect(rr.namedParamsCount, 0);
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
    expect(rr.action, 'index');
    expect(rr.namedParamsCount, 2);
    expect(rr.namedParams, ['controller', 'action']);
    var en = rr['en'];
    expect(en.regExp.pattern,r'^/([^/\.]+)(?:/([^/\.]+))?(?:\.(html))?$');
    expect(en.strf,'/%s/%s%s');
    var fr = rr['fr'];
    expect(fr.regExp.pattern,r'^/([^/\.]+)(?:/([^/\.]+))?(?:\.(html))?$');
    expect(fr.strf,'/%s/%s%s');
  });
  
  test('Named param route', (){
    RouterRoute rr = router.get('/post/:slug');
    assert(rr != null);
    expect(rr.controller, 'Post');
    expect(rr.action, 'view');
    expect(rr.namedParamsCount, 1);
    expect(rr.namedParams, ['slug']);
    var en = rr['en'];
    expect(en.regExp.pattern,r'^/post/([a-z\-]+)\.(htm)$');
    expect(en.strf,'/post/%s');
    var fr = rr['fr'];
    expect(fr.regExp.pattern,r'^/article/([a-z\-]+)\.(htm)$');
    expect(fr.strf,'/article/%s');
  });
  
  test('Find simple routes', (){
    Route r = router.find('/', 'en');
    assert(r != null);
    expect(r.all,'/');
    expect(r.controller, 'Site');
    expect(r.action,'index');
    expect(r.extension,null);
    expect(r.namedParams,null);
    expect(r.otherParams,null);
    
    r = router.find('/', 'fr');
    assert(r != null);
    expect(r.all,'/');
    expect(r.controller, 'Site');
    expect(r.action,'index');
    expect(r.extension,null);
    expect(r.namedParams,null);
    expect(r.otherParams,null);
  });

  test('Find common routes, /:controller', (){
    Route r = router.find('/post', 'en');
    assert(r != null);
    expect(r.all, '/post');
    expect(r.controller, 'Post');
    expect(r.action, 'index');
    expect(r.extension, null);
    expect(r.namedParams, null);
    expect(r.otherParams, null);
    
    r = router.find('/post.html', 'en');
    assert(r != null);
    expect(r.all, '/post.html');
    expect(r.controller, 'Post');
    expect(r.extension, 'html');
    expect(r.namedParams, null);
    
    r = router.find('/article', 'fr');
    assert(r != null);
    expect(r.all, '/article');
    expect(r.controller, 'Post');
    expect(r.action, 'index');
    expect(r.extension, null);
    expect(r.namedParams, null);
    expect(r.otherParams, null);

    r = router.find('/article.html', 'fr');
    assert(r != null);
    expect(r.all, '/article.html');
    expect(r.controller, 'Post');
    expect(r.extension, 'html');
    expect(r.namedParams, null);
    
  });
}
