part of router;

/// Convert a simple conf file key=>value into a two-way translation map
class RoutesTranslations{
  final Map<String, Map<String, String>> _translations = {};
  
  RoutesTranslations(Map<String, dynamic> translations){
    translations.forEach((String key, Map<String, String> translations){
      translations.forEach((String lang, String translation){
        if (!_translations.containsKey('>$lang')) {
          _translations['>$lang']=new Map<String,String>();
          _translations['$lang>']=new Map<String,String>();
        }
        _translations['>$lang'][key.toLowerCase()] = translation;
        _translations['$lang>'][translation.toLowerCase()] = key;
      });
    });
  }
  
  String translate(String string, String lang){
    string = string.toLowerCase();
    if (!_translations.containsKey('>$lang') || !_translations['>$lang'].containsKey(string)) {
      throw new Exception('Missing untranslation $string for lang $lang');
    }
    assert(_translations.containsKey('>$lang'));
    assert(_translations['>$lang'].containsKey(string));
    return _translations['>$lang'][string];
  }
  
  String untranslate(String string, String lang){
    string = string.toLowerCase();
    if (!_translations.containsKey('$lang>') || !_translations['$lang>'].containsKey(string)) {
      throw new Exception('Missing untranslation $string for lang $lang');
    }
    assert(_translations.containsKey('$lang>'));
    assert(_translations['$lang>'].containsKey(string));
    return _translations['$lang>'][string];
  }
}