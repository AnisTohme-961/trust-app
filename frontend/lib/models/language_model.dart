class LanguageModel {
  final String id;         
  final String name;
  final String nativeName; 
  final String flag;

  LanguageModel({
    required this.id,
    required this.name,
    required this.nativeName,
    required this.flag,
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      id: json['_id'] ?? json['ID'] ?? '', // try _id first
      name: json['Name'] ?? '',
      nativeName: json['NativeName'] ?? '', // map backend native name
      flag: json['Flag'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "name": name,
      "nativeName": nativeName,
      "flag": flag,
    };
  }
}
