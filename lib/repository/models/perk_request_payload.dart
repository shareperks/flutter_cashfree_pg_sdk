class PerkRequestPayload {
  final String userId;
  final String userName;
  final String userEmail;
  final String userMobile;
  final String? userImage;
  final String company;
  final String perkType;
  final String text;

  const PerkRequestPayload({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userMobile,
    this.userImage,
    required this.company,
    required this.perkType,
    required this.text,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'userEmail': userEmail,
    'userMobile': userMobile,
    if (userImage != null) 'userImage': userImage,
    'company': company,
    'perkType': perkType,
    'text': text,
  };
}
