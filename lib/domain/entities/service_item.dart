class ServiceItem {
  ServiceItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.sousCategory,
    required this.price,
    required this.duration,
    required this.tags,
    required this.imageUrl,
    required this.providerId,
    required this.isActive,
  });

  final int id;
  final String name;
  final String description;
  final String category;
  final String sousCategory;
  final String price;
  final String duration;
  final String tags;
  final String imageUrl;
  final int? providerId;
  final bool isActive;

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      name: '${json['name'] ?? ''}',
      description: '${json['description'] ?? ''}',
      category: '${json['Category'] ?? json['category'] ?? ''}',
      sousCategory: '${json['sous_category'] ?? ''}',
      price: '${json['price'] ?? ''}',
      duration: '${json['duration'] ?? ''}',
      tags: '${json['tags'] ?? ''}',
      imageUrl: '${json['imageurl'] ?? json['imageUrl'] ?? ''}',
      providerId: json['provider_id'] != null
          ? (json['provider_id'] is int
              ? json['provider_id'] as int
              : int.tryParse('${json['provider_id']}'))
          : null,
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }
}
