class SectionModel {
  final String id;
  final String name;
  final int rank;
  final String type; // e.g., "home-food", "kissan-fresh"
  final List<String> categories;

  SectionModel({
    required this.id,
    required this.name,
    required this.rank,
    required this.type,
    required this.categories,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json, String documentId) {
    return SectionModel(
      id: documentId,
      name: json['name'] ?? 'Unknown Section',
      rank: (json['rank'] ?? 0).toInt(),
      type: json['type'] ?? 'kissan-fresh',
      categories: json['categories'] != null
          ? List<String>.from(json['categories'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rank': rank,
      'type': type,
      'categories': categories,
    };
  }
}
