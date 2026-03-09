class ChatModel {
  final String id;
  final List<String> participantIds; // [user1Id, user2Id]
  final Map<String, String> participantNames; // {userId: name}
  final Map<String, String> participantImages; // {userId: imageUrl}
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount; // {userId: count}
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantImages,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageTime,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantImages': participantImages,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      participantImages: Map<String, String>.from(map['participantImages'] ?? {}),
      lastMessage: map['lastMessage'],
      lastMessageSenderId: map['lastMessageSenderId'],
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.parse(map['lastMessageTime'])
          : null,
      unreadCount: Map<String, int>.from(
        (map['unreadCount'] as Map<dynamic, dynamic>?)?.map(
              (key, value) => MapEntry(key.toString(), value as int),
            ) ??
            {},
      ),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  String getOtherUserId(String currentUserId) {
    try {
      return participantIds.firstWhere(
        (id) => id != currentUserId,
        orElse: () => participantIds.isNotEmpty ? participantIds.first : '',
      );
    } catch (e) {
      // Fallback: return first participant if current user not found
      return participantIds.isNotEmpty ? participantIds.first : '';
    }
  }

  String getOtherUserName(String currentUserId) {
    final otherId = getOtherUserId(currentUserId);
    if (otherId.isEmpty) return 'Unknown';
    return participantNames[otherId] ?? 'Unknown';
  }

  String getOtherUserImage(String currentUserId) {
    final otherId = getOtherUserId(currentUserId);
    if (otherId.isEmpty) return '';
    return participantImages[otherId] ?? '';
  }

  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }
}

