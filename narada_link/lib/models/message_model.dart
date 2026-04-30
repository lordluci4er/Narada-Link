class MessageModel {
  final String senderId;
  final String message;

  MessageModel({required this.senderId, required this.message});

  factory MessageModel.fromJson(Map json) {
    return MessageModel(
      senderId: json['senderId'],
      message: json['message'],
    );
  }
}