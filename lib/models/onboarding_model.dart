class OnboardingModel {
  final int id;
  final String title;
  final String description;
  final String iconUrl;
  final int order;
  final String buttonText;

  OnboardingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.order,
    required this.buttonText,
  });

  factory OnboardingModel.fromJson(Map<String, dynamic> json) {
    return OnboardingModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      iconUrl: json['icon_url'],
      order: json['order'],
      buttonText: json['button_text'],
    );
  }
}
