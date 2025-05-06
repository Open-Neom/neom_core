
import 'package:flutter/cupertino.dart';

class AppLocaleConstants {

  static final List<String> supportedLanguages = ['english', 'spanish', 'french', 'deutsch'];

  static const Map<String, Locale> supportedLocales = {
    'english': Locale('en', 'US'),
    'spanish': Locale('es', 'MX'),
    'french': Locale('fr', 'FR'),
    'deutsch': Locale('de', 'DE')
  };

  static const String es = 'es';

  static String languageFromLocale(Locale locale) {
    String language = "";
    switch(locale.languageCode){
      case 'en':
        language = "english";
        break;
      case 'esp':
        language = "spanish";
        break;
      case 'es':
        language = "spanish";
        break;
      case 'fr':
        language = "french";
        break;
      case 'de':
        language = "deutsch";
        break;
    }

    return language;
  }

  static const List<String> spanishCountries = [
    'Mexico', 'Spain', 'Argentina', 'Colombia', 'Peru', 'Venezuela',
    'Chile', 'Ecuador', 'Guatemala', 'Cuba', 'Bolivia', 'Honduras',
    'Paraguay', 'El Salvador', 'Nicaragua', 'Costa Rica', 'Puerto Rico',
    'Uruguay', 'Panama', 'Dominican Republic', 'Equatorial Guinea'
  ];

  static const List<String> frenchCountries = [
    'France', 'Belgium', 'Switzerland', 'Senegal', 'Ivory Coast',
    'Cameroon', 'Burkina Faso', 'Niger', 'Mali', 'Haiti', 'Chad',
    'Guinea', 'Rwanda', 'Burundi', 'Benin', 'Togo', 'Central African Republic',
    'Republic of the Congo', 'Gabon', 'Djibouti', 'Comoros', 'Luxembourg',
    'Monaco', 'Seychelles', 'Vanuatu'
  ];

  static const List<String> germanCountries = [
    'Germany', 'Austria', 'Switzerland', 'Luxembourg', 'Belgium', 'Liechtenstein'
  ];


}
