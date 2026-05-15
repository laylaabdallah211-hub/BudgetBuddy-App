class UserModel {
  final String uid;
  final String email;

  final double monthlyIncome;
  final double needsBudget;
  final double wantsBudget;
  final double savingsBudget;

  final String currency;
  final String budgetType;

  final bool onboardingComplete;
  final bool setupComplete;

  UserModel({
    required this.uid,
    required this.email,
    required this.monthlyIncome,
    required this.needsBudget,
    required this.wantsBudget,
    required this.savingsBudget,
    required this.currency,
    required this.budgetType,
    required this.onboardingComplete,
    required this.setupComplete,
  });

  // ---------------------------------------------------------
  // CREATE FROM FIRESTORE MAP
  // ---------------------------------------------------------
  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      monthlyIncome: (data['monthlyIncome'] ?? 0).toDouble(),
      needsBudget: (data['needsBudget'] ?? 0).toDouble(),
      wantsBudget: (data['wantsBudget'] ?? 0).toDouble(),
      savingsBudget: (data['savingsGoal'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'USD',
      budgetType: data['budgetType'] ?? 'Customizable',
      onboardingComplete: data['onboardingComplete'] ?? false,
      setupComplete: data['setupComplete'] ?? false,
    );
  }

  // ---------------------------------------------------------
  // CONVERT TO MAP (to store back into Firestore)
  // ---------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'monthlyIncome': monthlyIncome,
      'needsBudget': needsBudget,
      'wantsBudget': wantsBudget,
      'savingsGoal': savingsBudget,
      'currency': currency,
      'budgetType': budgetType,
      'onboardingComplete': onboardingComplete,
      'setupComplete': setupComplete,
    };
  }

  // ---------------------------------------------------------
  // COPYWITH (to update parts of userModel easily)
  // ---------------------------------------------------------
  UserModel copyWith({
    double? monthlyIncome,
    double? needsBudget,
    double? wantsBudget,
    double? savingsBudget,
    String? currency,
    String? budgetType,
    bool? onboardingComplete,
    bool? setupComplete,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      needsBudget: needsBudget ?? this.needsBudget,
      wantsBudget: wantsBudget ?? this.wantsBudget,
      savingsBudget: savingsBudget ?? this.savingsBudget,
      currency: currency ?? this.currency,
      budgetType: budgetType ?? this.budgetType,
      onboardingComplete:
      onboardingComplete ?? this.onboardingComplete,
      setupComplete: setupComplete ?? this.setupComplete,
    );
  }
}
