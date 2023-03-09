import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:instagram_clone/state/constants/firebase_collection_name.dart';
import 'package:instagram_clone/state/constants/firebase_field_name.dart';
import 'package:instagram_clone/state/image_upload/extensions/get_collection_name_from_file_type.dart';
import 'package:instagram_clone/state/image_upload/typedefs/is_loading.dart';
import 'package:instagram_clone/state/posts/typedefs/post_id.dart';

import '../models/post.dart';

class DeletePostStateNotifier extends StateNotifier<IsLoading> {
  DeletePostStateNotifier() : super(false);
  set isLoading(bool value) => state = value;

  Future<bool> deletePost({required Post post}) async {
    isLoading = true;

    try {
      // delete thumbnail
      isLoading = true;
      await FirebaseStorage.instance
          .ref()
          .child(post.userId)
          .child(FirebaseCollectionName.thumbnails)
          .child(post.thumbnailStorageId)
          .delete();

      // delete original file (image or video)
      await FirebaseStorage.instance
          .ref()
          .child(post.userId)
          .child(post.fileType.collectionName)
          .child(post.originalFileStorageId)
          .delete();

      // delete all comments with the post
      await _deleteAllDocuments(
          postid: post.postId, inCollection: FirebaseCollectionName.comments);

      // delete likes with the post
      await _deleteAllDocuments(
          postid: post.postId, inCollection: FirebaseCollectionName.likes);

      // delete the post itself
      final postInCollection = await FirebaseFirestore.instance
          .collection(FirebaseCollectionName.posts)
          .where(FieldPath.documentId, isEqualTo: post.postId)
          .limit(1)
          .get();
      for (final post in postInCollection.docs) {
        await post.reference.delete();
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<void> _deleteAllDocuments({
    required PostId postid,
    required String inCollection,
  }) {
    return FirebaseFirestore.instance.runTransaction(
        maxAttempts: 3,
        timeout: const Duration(seconds: 20), (transaction) async {
      final query = await FirebaseFirestore.instance
          .collection(inCollection)
          .where(FirebaseFieldName.postId, isEqualTo: postid)
          .get();
      for (final doc in query.docs) {
        transaction.delete(doc.reference);
      }
    });
  }
}
