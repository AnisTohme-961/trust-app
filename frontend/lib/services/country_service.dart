import 'dart:convert';

import 'package:http/http.dart' as http;

class CountryService {
  final String baseUrl;

  CountryService({required this.baseUrl});

  Future<List<Map<String, String>>> fetchCountries() async {
    final response = await http.get(Uri.parse('$baseUrl/countries'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map<Map<String, String>>(
            (item) => {
              'id': item['ID'],
              'name': item['Name'],
              'flag': item['Flag'],
            },
          )
          .toList();
    } else {
      throw Exception('Failed to load countries');
    }
  }
}

class CountriesService {
  static final List<Map<String, String>> defaultCountries = [
    {'name': 'Afghanistan', 'flag': 'assets/images/flags/Afghanistan.svg'},
    {'name': 'Albania', 'flag': 'assets/images/flags/Albania.svg'},
    {'name': 'Algeria', 'flag': 'assets/images/flags/Algeria.svg'},
    {'name': 'Andorra', 'flag': 'assets/images/flags/Andorra.svg'},
    {'name': 'Angola', 'flag': 'assets/images/flags/Angola.svg'},
    {
      'name': 'Antigua and Barbuda',
      'flag': 'assets/images/flags/AntiguaandBarbuda.svg',
    },
    {'name': 'Argentina', 'flag': 'assets/images/flags/Argentina.svg'},
    {'name': 'Armenia', 'flag': 'assets/images/flags/Armenia.svg'},
    {'name': 'Australia', 'flag': 'assets/images/flags/Australia.svg'},
    {'name': 'Austria', 'flag': 'assets/images/flags/Austria.svg'},
    {'name': 'Azerbaijan', 'flag': 'assets/images/flags/Azerbaijan.svg'},
    {'name': 'Bahamas', 'flag': 'assets/images/flags/Bahamas.svg'},
    {'name': 'Bahrain', 'flag': 'assets/images/flags/Bahrain.svg'},
    {'name': 'Bangladesh', 'flag': 'assets/images/flags/Bangladesh.svg'},
    {'name': 'Barbados', 'flag': 'assets/images/flags/Barbados.svg'},
    {'name': 'Belarus', 'flag': 'assets/images/flags/Belarus.svg'},
    {'name': 'Belgium', 'flag': 'assets/images/flags/Belgium.svg'},
    {'name': 'Belize', 'flag': 'assets/images/flags/Belize.svg'},
    {'name': 'Benin', 'flag': 'assets/images/flags/Benin.svg'},
    {'name': 'Bhutan', 'flag': 'assets/images/flags/Bhutan.svg'},
    {'name': 'Bolivia', 'flag': 'assets/images/flags/Bolivia.svg'},
    {
      'name': 'Bosnia and Herzegovina',
      'flag': 'assets/images/flags/BosniaandHerzegovina.svg',
    },
    {'name': 'Botswana', 'flag': 'assets/images/flags/Botswana.svg'},
    {'name': 'Brazil', 'flag': 'assets/images/flags/Brazil.svg'},
    {'name': 'Brunei', 'flag': 'assets/images/flags/Brunei.svg'},
    {'name': 'Bulgaria', 'flag': 'assets/images/flags/Bulgaria.svg'},
    {'name': 'Burkina Faso', 'flag': 'assets/images/flags/BurkinaFaso.svg'},
    {'name': 'Burundi', 'flag': 'assets/images/flags/Burundi.svg'},
    {'name': 'Cabo Verde', 'flag': 'assets/images/flags/CaboVerde.svg'},
    {'name': 'Cambodia', 'flag': 'assets/images/flags/Cambodia.svg'},
    {'name': 'Cameroon', 'flag': 'assets/images/flags/Cameroon.svg'},
    {'name': 'Canada', 'flag': 'assets/images/flags/Canada.svg'},
    {
      'name': 'Central African Republic',
      'flag': 'assets/images/flags/CentralAfricanRepublic.svg',
    },
    {'name': 'Chad', 'flag': 'assets/images/flags/Chad.svg'},
    {'name': 'Chile', 'flag': 'assets/images/flags/Chile.svg'},
    {'name': 'China', 'flag': 'assets/images/flags/China.svg'},
    {'name': 'Colombia', 'flag': 'assets/images/flags/Colombia.svg'},
    {'name': 'Comoros', 'flag': 'assets/images/flags/Comoros.svg'},
    {'name': 'Congo', 'flag': 'assets/images/flags/CongoDemocratic.svg'},
    {'name': 'Congo', 'flag': 'assets/images/flags/CongoRepublic.svg'},
    {'name': 'Costa Rica', 'flag': 'assets/images/flags/CostaRica.svg'},
    {'name': 'Croatia', 'flag': 'assets/images/flags/Croatia.svg'},
    {'name': 'Cuba', 'flag': 'assets/images/flags/Cuba.svg'},
    {'name': 'Cyprus', 'flag': 'assets/images/flags/Cyprus.svg'},
    {'name': 'Czechia', 'flag': 'assets/images/flags/Czechia.svg'},
    {'name': 'Côte d\'Ivoire', 'flag': 'assets/images/flags/CotedIvoire.svg'},
    {'name': 'Denmark', 'flag': 'assets/images/flags/Denmark.svg'},
    {'name': 'Djibouti', 'flag': 'assets/images/flags/Djibouti.svg'},
    {'name': 'Dominica', 'flag': 'assets/images/flags/Dominica.svg'},
    {
      'name': 'Dominican Republic',
      'flag': 'assets/images/flags/DominicanRepublic.svg',
    },
    {'name': 'Ecuador', 'flag': 'assets/images/flags/Ecuador.svg'},
    {'name': 'Egypt', 'flag': 'assets/images/flags/Egypt.svg'},
    {'name': 'El Salvador', 'flag': 'assets/images/flags/ElSalvador.svg'},
    {
      'name': 'Equatorial Guinea',
      'flag': 'assets/images/flags/EquatorialGuinea.svg',
    },
    {'name': 'Eritrea', 'flag': 'assets/images/flags/Eritrea.svg'},
    {'name': 'Estonia', 'flag': 'assets/images/flags/Estonia.svg'},
    {'name': 'Eswatini', 'flag': 'assets/images/flags/Eswatini.svg'},
    {'name': 'Ethiopia', 'flag': 'assets/images/flags/Ethiopia.svg'},
    {'name': 'Fiji', 'flag': 'assets/images/flags/Fiji.svg'},
    {'name': 'Finland', 'flag': 'assets/images/flags/Finland.svg'},
    {'name': 'France', 'flag': 'assets/images/flags/France.svg'},
    {'name': 'Gabon', 'flag': 'assets/images/flags/Gabon.svg'},
    {'name': 'Gambia', 'flag': 'assets/images/flags/Gambia.svg'},
    {'name': 'Georgia', 'flag': 'assets/images/flags/Georgia.svg'},
    {'name': 'Germany', 'flag': 'assets/images/flags/Germany.svg'},
    {'name': 'Ghana', 'flag': 'assets/images/flags/Ghana.svg'},
    {'name': 'Greece', 'flag': 'assets/images/flags/Greece.svg'},
    {'name': 'Grenada', 'flag': 'assets/images/flags/Grenada.svg'},
    {'name': 'Guatemala', 'flag': 'assets/images/flags/Guatemala.svg'},
    {'name': 'Guinea', 'flag': 'assets/images/flags/Guinea.svg'},
    {'name': 'Guinea-Bissau', 'flag': 'assets/images/flags/GuineaBissau.svg'},
    {'name': 'Guyana', 'flag': 'assets/images/flags/Guyana.svg'},
    {'name': 'Haiti', 'flag': 'assets/images/flags/Haiti.svg'},
    {'name': 'Honduras', 'flag': 'assets/images/flags/Honduras.svg'},
    {'name': 'Hungary', 'flag': 'assets/images/flags/Hungary.svg'},
    {'name': 'Iceland', 'flag': 'assets/images/flags/Iceland.svg'},
    {'name': 'India', 'flag': 'assets/images/flags/India.svg'},
    {'name': 'Indonesia', 'flag': 'assets/images/flags/Indonesia.svg'},
    {'name': 'Iran', 'flag': 'assets/images/flags/Iran.svg'},
    {'name': 'Iraq', 'flag': 'assets/images/flags/Iraq.svg'},
    {'name': 'Ireland', 'flag': 'assets/images/flags/Ireland.svg'},
    {'name': 'Israel', 'flag': 'assets/images/flags/Israel.svg'},
    {'name': 'Italy', 'flag': 'assets/images/flags/Italy.svg'},
    {'name': 'Jamaica', 'flag': 'assets/images/flags/Jamaica.svg'},
    {'name': 'Japan', 'flag': 'assets/images/flags/Japan.svg'},
    {'name': 'Jordan', 'flag': 'assets/images/flags/Jordan.svg'},
    {'name': 'Kazakhstan', 'flag': 'assets/images/flags/Kazakhstan.svg'},
    {'name': 'Kenya', 'flag': 'assets/images/flags/Kenya.svg'},
    {'name': 'Kiribati', 'flag': 'assets/images/flags/Kiribati.svg'},
    {'name': 'Korea (North)', 'flag': 'assets/images/flags/KoreaNorth.svg'},
    {'name': 'Korea (South)', 'flag': 'assets/images/flags/KoreaSouth.svg'},
    {'name': 'Kuwait', 'flag': 'assets/images/flags/Kuwait.svg'},
    {'name': 'Kyrgyzstan', 'flag': 'assets/images/flags/Kyrgyzstan.svg'},
    {'name': 'Laos', 'flag': 'assets/images/flags/Laos.svg'},
    {'name': 'Latvia', 'flag': 'assets/images/flags/Latvia.svg'},
    {'name': 'Lebanon', 'flag': 'assets/images/flags/Lebanon.svg'},
    {'name': 'Lesotho', 'flag': 'assets/images/flags/Lesotho.svg'},
    {'name': 'Liberia', 'flag': 'assets/images/flags/Liberia.svg'},
    {'name': 'Libya', 'flag': 'assets/images/flags/Libya.svg'},
    {'name': 'Liechtenstein', 'flag': 'assets/images/flags/Liechtenstein.svg'},
    {'name': 'Lithuania', 'flag': 'assets/images/flags/Lithuania.svg'},
    {'name': 'Luxembourg', 'flag': 'assets/images/flags/Luxembourg.svg'},
    {'name': 'Madagascar', 'flag': 'assets/images/flags/Madagascar.svg'},
    {'name': 'Malawi', 'flag': 'assets/images/flags/Malawi.svg'},
    {'name': 'Malaysia', 'flag': 'assets/images/flags/Malaysia.svg'},
    {'name': 'Maldives', 'flag': 'assets/images/flags/Maldives.svg'},
    {'name': 'Mali', 'flag': 'assets/images/flags/Mali.svg'},
    {'name': 'Malta', 'flag': 'assets/images/flags/Malta.svg'},
    {
      'name': 'Marshall Islands',
      'flag': 'assets/images/flags/MarshallIslands.svg',
    },
    {'name': 'Mauritania', 'flag': 'assets/images/flags/Mauritania.svg'},
    {'name': 'Mauritius', 'flag': 'assets/images/flags/Mauritius.svg'},
    {'name': 'Mexico', 'flag': 'assets/images/flags/Mexico.svg'},
    {'name': 'Micronesia', 'flag': 'assets/images/flags/Micronesia.svg'},
    {'name': 'Moldova', 'flag': 'assets/images/flags/Moldova.svg'},
    {'name': 'Monaco', 'flag': 'assets/images/flags/Monaco.svg'},
    {'name': 'Mongolia', 'flag': 'assets/images/flags/Mongolia.svg'},
    {'name': 'Montenegro', 'flag': 'assets/images/flags/Montenegro.svg'},
    {'name': 'Morocco', 'flag': 'assets/images/flags/Morocco.svg'},
    {'name': 'Mozambique', 'flag': 'assets/images/flags/Mozambique.svg'},
    {'name': 'Myanmar', 'flag': 'assets/images/flags/Myanmar.svg'},
    {'name': 'Namibia', 'flag': 'assets/images/flags/Namibia.svg'},
    {'name': 'Nauru', 'flag': 'assets/images/flags/Nauru.svg'},
    {'name': 'Nepal', 'flag': 'assets/images/flags/Nepal.svg'},
    {'name': 'Netherlands', 'flag': 'assets/images/flags/Netherlands.svg'},
    {'name': 'New Zealand', 'flag': 'assets/images/flags/NewZealand.svg'},
    {'name': 'Nicaragua', 'flag': 'assets/images/flags/Nicaragua.svg'},
    {'name': 'Niger', 'flag': 'assets/images/flags/Niger.svg'},
    {'name': 'Nigeria', 'flag': 'assets/images/flags/Nigeria.svg'},
    {
      'name': 'North Macedonia',
      'flag': 'assets/images/flags/NorthMacedonia.svg',
    },
    {'name': 'Norway', 'flag': 'assets/images/flags/Norway.svg'},
    {'name': 'Oman', 'flag': 'assets/images/flags/Oman.svg'},
    {'name': 'Pakistan', 'flag': 'assets/images/flags/Pakistan.svg'},
    {'name': 'Palau', 'flag': 'assets/images/flags/Palau.svg'},
    {'name': 'Palestine', 'flag': 'assets/images/flags/Palestine.svg'},
    {'name': 'Panama', 'flag': 'assets/images/flags/Panama.svg'},
    {
      'name': 'Papua New Guinea',
      'flag': 'assets/images/flags/PapuaNewGuinea.svg',
    },
    {'name': 'Paraguay', 'flag': 'assets/images/flags/Paraguay.svg'},
    {'name': 'Peru', 'flag': 'assets/images/flags/Peru.svg'},
    {'name': 'Philippines', 'flag': 'assets/images/flags/Philippines.svg'},
    {'name': 'Poland', 'flag': 'assets/images/flags/Poland.svg'},
    {'name': 'Portugal', 'flag': 'assets/images/flags/Portugal.svg'},
    {'name': 'Qatar', 'flag': 'assets/images/flags/Qatar.svg'},
    {'name': 'Romania', 'flag': 'assets/images/flags/Romania.svg'},
    {'name': 'Russia', 'flag': 'assets/images/flags/Russia.svg'},
    {'name': 'Rwanda', 'flag': 'assets/images/flags/Rwanda.svg'},
    {
      'name': 'Saint Kitts and Nevis',
      'flag': 'assets/images/flags/SaintKittsandNevis.svg',
    },
    {'name': 'Saint Lucia', 'flag': 'assets/images/flags/SaintLucia.svg'},
    {
      'name': 'Saint Vincent and the Grenadines',
      'flag': 'assets/images/flags/SaintVincentandtheGrenadines.svg',
    },
    {'name': 'Samoa', 'flag': 'assets/images/flags/Samoa.svg'},
    {'name': 'San Marino', 'flag': 'assets/images/flags/SanMarino.svg'},
    {
      'name': 'Sao Tome and Principe',
      'flag': 'assets/images/flags/SaoTomeandPrincipe.svg',
    },
    {'name': 'Saudi Arabia', 'flag': 'assets/images/flags/SaudiArabia.svg'},
    {'name': 'Senegal', 'flag': 'assets/images/flags/Senegal.svg'},
    {'name': 'Serbia', 'flag': 'assets/images/flags/Serbia.svg'},
    {'name': 'Seychelles', 'flag': 'assets/images/flags/Seychelles.svg'},
    {'name': 'Sierra Leone', 'flag': 'assets/images/flags/SierraLeone.svg'},
    {'name': 'Singapore', 'flag': 'assets/images/flags/Singapore.svg'},
    {'name': 'Slovakia', 'flag': 'assets/images/flags/Slovakia.svg'},
    {'name': 'Slovenia', 'flag': 'assets/images/flags/Slovenia.svg'},
    {
      'name': 'Solomon Islands',
      'flag': 'assets/images/flags/SolomonIslands.svg',
    },
    {'name': 'Somalia', 'flag': 'assets/images/flags/Somalia.svg'},
    {'name': 'South Africa', 'flag': 'assets/images/flags/SouthAfrica.svg'},
    {'name': 'South Sudan', 'flag': 'assets/images/flags/SouthSudan.svg'},
    {'name': 'Spain', 'flag': 'assets/images/flags/Spain.svg'},
    {'name': 'Sri Lanka', 'flag': 'assets/images/flags/SriLanka.svg'},
    {'name': 'Sudan', 'flag': 'assets/images/flags/Sudan.svg'},
    {'name': 'Suriname', 'flag': 'assets/images/flags/Suriname.svg'},
    {'name': 'Sweden', 'flag': 'assets/images/flags/Sweden.svg'},
    {'name': 'Switzerland', 'flag': 'assets/images/flags/Switzerland.svg'},
    {'name': 'Syria', 'flag': 'assets/images/flags/Syria.svg'},
    {'name': 'Tajikistan', 'flag': 'assets/images/flags/Tajikistan.svg'},
    {'name': 'Tanzania', 'flag': 'assets/images/flags/Tanzania.svg'},
    {'name': 'Thailand', 'flag': 'assets/images/flags/Thailand.svg'},
    {'name': 'Timor-Leste', 'flag': 'assets/images/flags/TimorLeste.svg'},
    {'name': 'Togo', 'flag': 'assets/images/flags/Togo.svg'},
    {'name': 'Tonga', 'flag': 'assets/images/flags/Tonga.svg'},
    {
      'name': 'Trinidad and Tobago',
      'flag': 'assets/images/flags/TrinidadandTobago.svg',
    },
    {'name': 'Tunisia', 'flag': 'assets/images/flags/Tunisia.svg'},
    {'name': 'Turkey', 'flag': 'assets/images/flags/Turkey.svg'},
    {'name': 'Turkmenistan', 'flag': 'assets/images/flags/Turkmenistan.svg'},
    {'name': 'Tuvalu', 'flag': 'assets/images/flags/Tuvalu.svg'},
    {'name': 'Uganda', 'flag': 'assets/images/flags/Uganda.svg'},
    {'name': 'Ukraine', 'flag': 'assets/images/flags/Ukraine.svg'},
    {
      'name': 'United Arab Emirates',
      'flag': 'assets/images/flags/UnitedArabEmirates.svg',
    },
    {'name': 'United Kingdom', 'flag': 'assets/images/flags/UnitedKingdom.svg'},
    {'name': 'United States', 'flag': 'assets/images/flags/UnitedStates.svg'},
    {'name': 'Uruguay', 'flag': 'assets/images/flags/Uruguay.svg'},
    {'name': 'Uzbekistan', 'flag': 'assets/images/flags/Uzbekistan.svg'},
    {'name': 'Vanuatu', 'flag': 'assets/images/flags/Vanuatu.svg'},
    {'name': 'Vatican City', 'flag': 'assets/images/flags/VaticanCity.svg'},
    {'name': 'Venezuela', 'flag': 'assets/images/flags/Venezuela.svg'},
    {'name': 'Vietnam', 'flag': 'assets/images/flags/Vietnam.svg'},
    {'name': 'Yemen', 'flag': 'assets/images/flags/Yemen.svg'},
    {'name': 'Zambia', 'flag': 'assets/images/flags/Zambia.svg'},
    {'name': 'Zimbabwe', 'flag': 'assets/images/flags/Zimbabwe.svg'},
  ];

  // Method to get countries - you can later modify this to fetch from API
  static List<Map<String, String>> getCountries() {
    return List<Map<String, String>>.from(defaultCountries);
  }

  // Method to search/filter countries
  // static List<Map<String, String>> filterCountries(
  //   List<Map<String, String>> countries,
  //   String query,
  // ) {
  //   if (query.isEmpty) return countries;
  //   return countries
  //       .where(
  //         (country) =>
  //             country['name']!.toLowerCase().contains(query.toLowerCase()),
  //       )
  //       .toList();
  // }
}
