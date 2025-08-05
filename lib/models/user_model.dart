class UserModel {
  final String uid; // El ID único de Firebase Auth
  final String email;
  final String fullName;
  final String mobilePhone;
  final String street;
  final String number;
  final String betweenStreets;
  final String postalCode;
  final String neighborhood;
  final String city;
  final String country;
  final String plan; // Para saber el tipo de suscripción

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.mobilePhone,
    required this.street,
    required this.number,
    required this.betweenStreets,
    required this.postalCode,
    required this.neighborhood,
    required this.city,
    required this.country,
    this.plan = 'iniciacion', // Por defecto, todos empiezan en el plan gratuito
  });

  // Método para convertir nuestro objeto a un formato que Firestore entienda (JSON)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'mobilePhone': mobilePhone,
      'street': street,
      'number': number,
      'betweenStreets': betweenStreets,
      'postalCode': postalCode,
      'neighborhood': neighborhood,
      'city': city,
      'country': country,
      'plan': plan,
    };
  }
}
