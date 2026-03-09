import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _postsCollection =>
      _firestore.collection('posts');

  /// Save a new post to Firestore
  Future<bool> createPost(PostModel post) async {
    try {
      await _postsCollection.doc(post.id).set(post.toMap());
      return true;
    } catch (e) {
      debugPrint('Error creating post: $e');
      return false;
    }
  }

  /// Get all posts
  Stream<List<PostModel>> getAllPosts() {
    return _postsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Get posts by type
  Stream<List<PostModel>> getPostsByType(PostType type) {
    final typeString = type == PostType.driver ? 'driver' : 'passenger';
    return _postsCollection
        .where('type', isEqualTo: typeString)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Get user's posts
  Stream<List<PostModel>> getUserPosts(String userId) {
    return _postsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Delete a post
  Future<bool> deletePost(String postId) async {
    try {
      await _postsCollection.doc(postId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting post: $e');
      return false;
    }
  }
}

