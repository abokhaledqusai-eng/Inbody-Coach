class Meal {
  final int id;
  final String name;
  final int calories;
  final int proteins;
  final int carbs;
  final int fats;
  final String? imageUrl;
  final String? time;
  final String? ingredients;
  final String? instructions;
  final bool isLogged;
  final String typeLabel;

  Meal({
    required this.id,
    required this.name,
    required this.calories,
    required this.proteins,
    required this.carbs,
    required this.fats,
    this.imageUrl,
    this.time,
    this.ingredients,
    this.instructions,
    required this.isLogged,
    required this.typeLabel,
  });

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        calories: (json['calories'] ?? 0).toInt(),
        proteins: (json['proteins'] ?? 0).toInt(),
        carbs: (json['carbs'] ?? 0).toInt(),
        fats: (json['fats'] ?? 0).toInt(),
        imageUrl: json['image_url'] as String?,
        time: json['time'] as String?,
        ingredients: json['ingredients'] as String?,
        instructions: json['instructions'] as String?,
        isLogged: json['is_logged'] == true,
        typeLabel: json['type_label'] ?? json['meal_type'] ?? 'وجبة',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'calories': calories,
        'proteins': proteins,
        'carbs': carbs,
        'fats': fats,
        'image_url': imageUrl,
        'time': time,
        'ingredients': ingredients,
        'instructions': instructions,
        'is_logged': isLogged,
        'type_label': typeLabel,
      };
}
