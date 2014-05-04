import 'dart:io';
import 'package:unittest/unittest.dart';
import 'package:yaml/yaml.dart' as Yaml;

import 'package:springbok_router/router.dart';
import '../example/routes.dart';


void main(){
  //String routesConfig = new File('../example/routes.yaml').readAsStringSync();
  String routesLangsConfig = new File('../example/routesLangs.yaml').readAsStringSync();
  
  RoutesTranslations rt = new RoutesTranslations(Yaml.loadYaml(routesLangsConfig));
  
  test('Route translations', (){
    expect(rt.translate('login', 'fr'), 'connexion');
    expect(rt.untranslate('connexion', 'fr'), 'login');
  });
  
  
  Router router = createRouter();
  
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
    RouterRoute rrs = router.get('defaultSimple');
    assert(rrs != null);
    expect(rrs.controller, 'Site');
    expect(rrs.action, 'index');
    expect(rrs.namedParamsCount, 0);
    var rsen = rrs['en'];
    expect(rsen.regExp.pattern,r'^(?:\.(html))?$');
    expect(rsen.strf,'/%s');
    var rsfr = rrs['fr'];
    expect(rsfr.regExp.pattern,r'^(?:\.(html))?$');
    expect(rsfr.strf,'/%s');
    
    RouterRoute rr = router.get('default');
    assert(rr != null);
    expect(rr.controller, 'Site');
    expect(rr.action, 'index');
    expect(rr.namedParamsCount, 1);
    expect(rr.namedParams, ['action']);
    var en = rr['en'];
    //expect(en.regExp.pattern,r'^/([^/\.]+)(?:/([^/\.]+)(?:/([^\.]*))?)?(?:\.(html))?$');
    expect(en.regExp.pattern,r'^/([^/\.]+)(?:/([^\.]*))?(?:\.(html))?$');
    expect(en.strf,'/%s/%s%s');
    var fr = rr['fr'];
    //expect(fr.regExp.pattern,r'^/([^/\.]+)(?:/([^/\.]+)(?:/([^\.]*))?)?(?:\.(html))?$');
    expect(en.regExp.pattern,r'^/([^/\.]+)(?:/([^\.]*))?(?:\.(html))?$');
    expect(fr.strf,'/%s/%s%s');
  });
  
  test('Named param route', (){
    RouterRoute rr = router.get('postView');
    assert(rr != null);
    expect(rr.controller, 'Post');
    expect(rr.action, 'view');
    expect(rr.namedParamsCount, 2);
    expect(rr.namedParams, ['id', 'slug']);
    var en = rr['en'];
    expect(en.regExp.pattern,r'^/post/([0-9]+)\-([A-Za-z\-]+)\.(htm)$');
    expect(en.strf,'/post/%s-%s');
    var fr = rr['fr'];
    expect(fr.regExp.pattern,r'^/article/([0-9]+)\-([A-Za-z\-]+)\.(htm)$');
    expect(fr.strf,'/article/%s-%s');
  });
  
  test('More complex param route', () {
    RouterRoute rr = router.get('postWithDate');
    assert(rr != null);
    expect(rr.controller, 'Post');
    expect(rr.action, 'view');
    expect(rr.namedParamsCount, 3);
    expect(rr.namedParams, ['tagKey', 'date', 'slug']);
    var en = rr['en'];
    expect(en.regExp.pattern, r'^/post(?:/([^/.]+))?(?:/(\d{4}\-\d{2}\-\d{2})_([^/.]+))$');
    expect(en.strf,'/post/%s/%s%s');
    var fr = rr['fr'];
    expect(fr.regExp.pattern, r'^/article(?:\/([^/.]+))?(?:\/(\d{4}\-\d{2}\\-\d{2})_([^/.]+))$');
    expect(fr.strf,'/article/%s/%s%s');
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
  

  test('Find common routes, /:controller/:action', (){
    Route r = router.find('/post/view', 'en');
    assert(r != null);
    expect(r.all, '/post/view');
    expect(r.controller, 'Post');
    expect(r.action, 'view');
    expect(r.extension, null);
    expect(r.namedParams, null);
    expect(r.otherParams, null);
    
    r = router.find('/post/view.html', 'en');
    assert(r != null);
    expect(r.all, '/post/view.html');
    expect(r.controller, 'Post');
    expect(r.action, 'view');
    expect(r.extension, 'html');
    expect(r.namedParams, null);
    
    r = router.find('/article/afficher', 'fr');
    assert(r != null);
    expect(r.all, '/article/afficher');
    expect(r.controller, 'Post');
    expect(r.action, 'view');
    expect(r.extension, null);
    expect(r.namedParams, null);
    expect(r.otherParams, null);

    r = router.find('/article/afficher.html', 'fr');
    assert(r != null);
    expect(r.all, '/article/afficher.html');
    expect(r.controller, 'Post');
    expect(r.action, 'view');
    expect(r.extension, 'html');
    expect(r.namedParams, null);
  });
  

  test('Find common routes, /:controller/:action/*', (){
    Route r = router.find('/post/view/test1/test2', 'en');
    assert(r != null);
    expect(r.all, '/post/view/test1/test2');
    expect(r.controller, 'Post');
    expect(r.action, 'view');
    expect(r.extension, null);
    expect(r.namedParams, null);
    expect(r.otherParams, ['test1', 'test2']);
    
    r = router.find('/post/view/test1/test2.html', 'en');
    assert(r != null);
    expect(r.all, '/post/view/test1/test2.html');
    expect(r.controller, 'Post');
    expect(r.extension, 'html');
    expect(r.namedParams, null);
    expect(r.otherParams, ['test1', 'test2']);
    
    r = router.find('/article/afficher/test1/test2', 'fr');
    assert(r != null);
    expect(r.all, '/article/afficher/test1/test2');
    expect(r.controller, 'Post');
    expect(r.action, 'view');
    expect(r.extension, null);
    expect(r.namedParams, null);
    expect(r.otherParams, ['test1', 'test2']);

    r = router.find('/article/afficher/test1/test2.html', 'fr');
    assert(r != null);
    expect(r.all, '/article/afficher/test1/test2.html');
    expect(r.controller, 'Post');
    expect(r.action, 'view');
    expect(r.extension, 'html');
    expect(r.namedParams, null);
    expect(r.otherParams, ['test1', 'test2']);
  });
  

  test('Find named param route', (){
    Route r = router.find('/post/001-The-First-Post.htm', 'en');
    assert(r != null);
    expect(r.all, '/post/001-The-First-Post.htm');
    expect(r.controller, 'Post');
    expect(r.action, 'view');
    expect(r.extension, 'htm');
    expect(r.namedParams, {'id': '001', 'slug': 'The-First-Post'});
    expect(r.otherParams, null);
    
    r = router.find('/article/001-Le-Premier-Billet.htm', 'fr');
    assert(r != null);
    expect(r.all, '/article/001-Le-Premier-Billet.htm');
    expect(r.controller, 'Post');
    expect(r.action, 'view');
    expect(r.extension, 'htm');
    expect(r.namedParams, {'id': '001', 'slug': 'Le-Premier-Billet'});
    expect(r.otherParams, null);
  });
}
