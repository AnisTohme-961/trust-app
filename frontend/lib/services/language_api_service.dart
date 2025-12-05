import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/language_model.dart';
import '../constants/api_constants.dart';

class LanguageApiService {
  final String baseUrl;

  LanguageApiService({String? baseUrl})
    : baseUrl = baseUrl ?? ApiConstants.baseUrl;

  Future<List<LanguageModel>> fetchLanguages() async {
    final response = await http.get(Uri.parse('$baseUrl/languages'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => LanguageModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch ');
    }
  }
}

class LanguagesService {
  static final List<Map<String, String>> defaultLanguages = [
    {'name': 'Arabic (العربية)', 'flag': 'assets/images/flags/SaudiArabia.svg'},
    {
      'name': 'English (English)',
      'flag': 'assets/images/flags/UnitedStates.svg',
    },
    {'name': 'French (Français)', 'flag': 'assets/images/flags/France.svg'},
    {'name': 'Spanish (Español)', 'flag': 'assets/images/flags/Spain.svg'},
    {'name': 'German (Deutsch)', 'flag': 'assets/images/flags/Germany.svg'},
    {'name': 'Chinese (中文)', 'flag': 'assets/images/flags/China.svg'},
    {'name': 'Japanese (日本語)', 'flag': 'assets/images/flags/Japan.svg'},
    {'name': 'Korean (한국어)', 'flag': 'assets/images/flags/KoreaSouth.svg'},
    {'name': 'Russian (Русский)', 'flag': 'assets/images/flags/Russia.svg'},
    {
      'name': 'Portuguese (Português)',
      'flag': 'assets/images/flags/Portugal.svg',
    },
    {'name': 'Italian (Italiano)', 'flag': 'assets/images/flags/Italy.svg'},
    {'name': 'Hindi (हिन्दी)', 'flag': 'assets/images/flags/India.svg'},
    {'name': 'Bengali (বাংলা)', 'flag': 'assets/images/flags/Bangladesh.svg'},
    {'name': 'Turkish (Türkçe)', 'flag': 'assets/images/flags/Turkey.svg'},
    {'name': 'Persian (فارسی)', 'flag': 'assets/images/flags/Iran.svg'},
    {'name': 'Urdu (اردو)', 'flag': 'assets/images/flags/Pakistan.svg'},
    {'name': 'Tamil (தமிழ்)', 'flag': 'assets/images/flags/SriLanka.svg'},
    {'name': 'Thai (ภาษาไทย)', 'flag': 'assets/images/flags/Thailand.svg'},
    {'name': 'Greek (Ελληνικά)', 'flag': 'assets/images/flags/Greece.svg'},
    {
      'name': 'Dutch (Nederlands)',
      'flag': 'assets/images/flags/Netherlands.svg',
    },
    {'name': 'Swedish (Svenska)', 'flag': 'assets/images/flags/Sweden.svg'},
    {'name': 'Finnish (Suomi)', 'flag': 'assets/images/flags/Finland.svg'},
    {'name': 'Norwegian (Norsk)', 'flag': 'assets/images/flags/Norway.svg'},
    {'name': 'Danish (Dansk)', 'flag': 'assets/images/flags/Denmark.svg'},
    {'name': 'Polish (Polski)', 'flag': 'assets/images/flags/Poland.svg'},
    {'name': 'Czech (Čeština)', 'flag': 'assets/images/flags/Czechia.svg'},
    {'name': 'Hungarian (Magyar)', 'flag': 'assets/images/flags/Hungary.svg'},
    {'name': 'Romanian (Română)', 'flag': 'assets/images/flags/Romania.svg'},
    {'name': 'Slovak (Slovenčina)', 'flag': 'assets/images/flags/Slovakia.svg'},
    {'name': 'Croatian (Hrvatski)', 'flag': 'assets/images/flags/Croatia.svg'},
    {'name': 'Serbian (Српски)', 'flag': 'assets/images/flags/Serbia.svg'},
    {
      'name': 'Ukrainian (Українська)',
      'flag': 'assets/images/flags/Ukraine.svg',
    },
    {
      'name': 'Afrikaans (Afrikaans)',
      'flag': 'assets/images/flags/SouthAfrica.svg',
    },
    {
      'name': 'Indonesian (Bahasa Indonesia)',
      'flag': 'assets/images/flags/Indonesia.svg',
    },
    {
      'name': 'Malay (Bahasa Melayu)',
      'flag': 'assets/images/flags/Malaysia.svg',
    },
    {
      'name': 'Filipino (Filipino)',
      'flag': 'assets/images/flags/Philippines.svg',
    },
    {'name': 'Georgian (ქართული)', 'flag': 'assets/images/flags/Georgia.svg'},
    {'name': 'Albanian (Shqip)', 'flag': 'assets/images/flags/Albania.svg'},
    {'name': 'Amharic (አማርኛ)', 'flag': 'assets/images/flags/Ethiopia.svg'},
    {'name': 'Somali (Soomaali)', 'flag': 'assets/images/flags/Somalia.svg'},
    {'name': 'Swahili (Kiswahili)', 'flag': 'assets/images/flags/Kenya.svg'},
    {'name': 'Igbo (Igbo)', 'flag': 'assets/images/flags/Nigeria.svg'},
    {'name': 'Yoruba (Yorùbá)', 'flag': 'assets/images/flags/Nigeria.svg'},
    {'name': 'Zulu (Zulu)', 'flag': 'assets/images/flags/SouthAfrica.svg'},
    {'name': 'Latvian (Latviešu)', 'flag': 'assets/images/flags/Latvia.svg'},
    {
      'name': 'Lithuanian (Lietuvių)',
      'flag': 'assets/images/flags/Lithuania.svg',
    },
    {'name': 'Estonian (Eesti)', 'flag': 'assets/images/flags/Estonia.svg'},
    {'name': 'Icelandic (Íslenska)', 'flag': 'assets/images/flags/Iceland.svg'},
    {'name': 'Catalan (Català)', 'flag': 'assets/images/flags/Andorra.svg'},
    {'name': 'Galician (Galego)', 'flag': 'assets/images/flags/Spain.svg'},
    {
      'name': 'Bulgarian (Български)',
      'flag': 'assets/images/flags/Bulgaria.svg',
    },
    {'name': 'Maori (Māori)', 'flag': 'assets/images/flags/NewZealand.svg'},
    {'name': 'Samoan (Samoan)', 'flag': 'assets/images/flags/Samoa.svg'},
    {'name': 'Fijian (Fijian)', 'flag': 'assets/images/flags/Fiji.svg'},
    {'name': 'Oromo (አፋን ኦሮሞ)', 'flag': 'assets/images/flags/Ethiopia.svg'},
    {'name': 'Kurdish (Kurmanji)', 'flag': 'assets/images/flags/Iraq.svg'},
    {'name': 'Pashto (پشتو)', 'flag': 'assets/images/flags/Afghanistan.svg'},
    {'name': 'Sindhi (سنڌي)', 'flag': 'assets/images/flags/Pakistan.svg'},
    {'name': 'Nepali (नेपाली)', 'flag': 'assets/images/flags/Nepal.svg'},
    {'name': 'Sinhala (සිංහල)', 'flag': 'assets/images/flags/SriLanka.svg'},
    {'name': 'Burmese (မြန်မာ)', 'flag': 'assets/images/flags/Myanmar.svg'},
    {'name': 'Khmer (ខ្មែរ)', 'flag': 'assets/images/flags/Cambodia.svg'},
    {'name': 'Lao (ລາວ)', 'flag': 'assets/images/flags/Laos.svg'},
    {'name': 'Mongolian (Монгол)', 'flag': 'assets/images/flags/Mongolia.svg'},
    {'name': 'Kazakh (Қазақ)', 'flag': 'assets/images/flags/Kazakhstan.svg'},
    {
      'name': 'Turkmen (Türkmen)',
      'flag': 'assets/images/flags/Turkmenistan.svg',
    },
    {'name': 'Uzbek (Oʻzbek)', 'flag': 'assets/images/flags/Uzbekistan.svg'},
    {
      'name': 'Azerbaijani (Azərbaycan dili)',
      'flag': 'assets/images/flags/Azerbaijan.svg',
    },
    {'name': 'Armenian (Հայերեն)', 'flag': 'assets/images/flags/Armenia.svg'},
    {
      'name': 'Vietnamese (Tiếng Việt)',
      'flag': 'assets/images/flags/Vietnam.svg',
    },
    {
      'name': 'Haitian Creole (Kreyòl Ayisyen)',
      'flag': 'assets/images/flags/Haiti.svg',
    },
    {'name': 'Irish (Gaeilge)', 'flag': 'assets/images/flags/Ireland.svg'},
    {'name': 'Welsh (Cymraeg)', 'flag': 'assets/images/flags/wales.svg'},
    {'name': 'Breton (Brezhoneg)', 'flag': 'assets/images/flags/France.svg'},
    {'name': 'Basque (Euskara)', 'flag': 'assets/images/flags/Spain.svg'},
    {
      'name': 'Belarusian (Беларуская)',
      'flag': 'assets/images/flags/Belarus.svg',
    },
    {'name': 'Kyrgyz (Кыргызча)', 'flag': 'assets/images/flags/Kyrgyzstan.svg'},
    {'name': 'Tajik (Tajik)', 'flag': 'assets/images/flags/Tajikistan.svg'},
    {'name': 'Tigrinya (ትግርኛ)', 'flag': 'assets/images/flags/Eritrea.svg'},
    {'name': 'Shona (Shona)', 'flag': 'assets/images/flags/Zimbabwe.svg'},
    {'name': 'Sesotho (Sesotho)', 'flag': 'assets/images/flags/Lesotho.svg'},
    {'name': 'Tswana (Setswana)', 'flag': 'assets/images/flags/Botswana.svg'},
    {'name': 'Xhosa (isiXhosa)', 'flag': 'assets/images/flags/SouthAfrica.svg'},
    {'name': 'Zulu (isiZulu)', 'flag': 'assets/images/flags/SouthAfrica.svg'},
  ];

  static List<Map<String, String>> getLanguages() {
    return List<Map<String, String>>.from(defaultLanguages);
  }

  static List<Map<String, String>> searchLanguages(String query) {
    final languages = getLanguages();
    if (query.isEmpty) return languages;
    return languages
        .where(
          (lang) => lang['name']!.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }
}
