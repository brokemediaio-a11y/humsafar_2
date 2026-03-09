import '../models/user_model.dart';
import '../services/user_search_service.dart';

class MentionParser {
  final UserSearchService _userSearchService = UserSearchService();

  /// Extract all @mentions from text
  /// Returns a list of usernames that were mentioned
  /// Handles names with spaces (e.g., @John Doe, @Sarah Smith)
  List<String> extractMentions(String text) {
    final mentions = <String>[];
    // Match @ followed by name (can have spaces, ends at space or end of string)
    // This regex matches: @John, @John Doe, @Sarah Smith, etc.
    final regex = RegExp(r'@([A-Za-z]+(?:\s+[A-Za-z]+)*)');
    final matches = regex.allMatches(text);
    
    for (final match in matches) {
      final mention = match.group(1)?.trim();
      if (mention != null && mention.isNotEmpty) {
        // Avoid duplicates
        if (!mentions.contains(mention)) {
          mentions.add(mention);
        }
      }
    }
    
    return mentions;
  }

  /// Find user IDs for mentioned usernames
  /// Returns a map of username -> UserModel
  Future<Map<String, UserModel>> findMentionedUsers(List<String> mentions) async {
    final userMap = <String, UserModel>{};
    
    for (final mention in mentions) {
      try {
        // Search for users matching this mention
        final users = await _userSearchService.searchUsers(mention);
        
        if (users.isEmpty) {
          continue; // Skip if no users found
        }
        
        // Try to find exact match first (case-insensitive)
        UserModel? matchedUser;
        for (final user in users) {
          if (user.fullName.toLowerCase() == mention.toLowerCase()) {
            matchedUser = user;
            break;
          }
        }
        
        // If no exact match, use the first result (best match from search)
        matchedUser ??= users.first;
        
        userMap[mention] = matchedUser;
      } catch (e) {
        // Skip this mention if there's an error
        continue;
      }
    }
    
    return userMap;
  }

  /// Parse mentions from text and return list of UserModels
  /// Returns empty list if no mentions found or if users can't be resolved
  Future<List<UserModel>> parseMentionsToUsers(String text) async {
    final mentions = extractMentions(text);
    if (mentions.isEmpty) return [];
    
    final userMap = await findMentionedUsers(mentions);
    return userMap.values.toList();
  }
}
