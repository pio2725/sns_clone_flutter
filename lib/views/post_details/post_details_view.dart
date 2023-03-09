import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:instagram_clone/enums/date_sorting.dart';
import 'package:instagram_clone/state/comments/models/post_comments_request.dart';
import 'package:instagram_clone/state/posts/providers/can_current_user_delete_post_provider.dart';
import 'package:instagram_clone/state/posts/providers/delete_post_provider.dart';
import 'package:instagram_clone/state/posts/providers/specific_post_with_comments_provider.dart';
import 'package:instagram_clone/views/components/animations/small_error_animation_view.dart';
import 'package:instagram_clone/views/components/comment/compact_comment_column.dart';
import 'package:instagram_clone/views/components/dialogs/alert_dialog_model.dart';
import 'package:instagram_clone/views/components/dialogs/delete_dialog.dart';
import 'package:instagram_clone/views/components/like_button.dart';
import 'package:instagram_clone/views/components/likes_count_view.dart';
import 'package:instagram_clone/views/components/posts/post_date_view.dart';
import 'package:instagram_clone/views/components/posts/post_display_name_and_messsage_view.dart';
import 'package:instagram_clone/views/components/posts/post_image_or_video_view.dart';
import 'package:instagram_clone/views/constants/strings.dart';
import 'package:instagram_clone/views/post_comments/post_comments_view.dart';
import 'package:share_plus/share_plus.dart';

import '../../state/posts/models/post.dart';

class PostDetailsView extends ConsumerStatefulWidget {
  final Post post;
  const PostDetailsView({super.key, required this.post});

  @override
  ConsumerState<PostDetailsView> createState() => _PostDetailsViewState();
}

class _PostDetailsViewState extends ConsumerState<PostDetailsView> {
  @override
  Widget build(BuildContext context) {
    final request = RequestForPostAndComments(
        postId: widget.post.postId,
        limit: 3,
        sortByCreatedAt: true,
        dateSorting: DateSorting.oldestOnTop);
    final postWithComments =
        ref.watch(specificPostWithCommentsProvider(request));
    final canDeletePost =
        ref.watch(canCurrentUserDeletePostProvider(widget.post));

    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.postDetails),
        actions: [
          // share button
          postWithComments.when(
            data: (postWithComments) {
              return IconButton(
                  onPressed: () {
                    final url = postWithComments.post.fileUrl;
                    Share.share(
                      url,
                      subject: Strings.checkOutThisPost,
                    );
                  },
                  icon: const Icon(Icons.share));
            },
            error: (error, stackTrace) {
              return const SmallErrorAnimationView();
            },
            loading: () {
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
          // delete button
          if (canDeletePost.value ?? false)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final shouldDeletePost = await const DeleteDialog(
                        titleOfObjectToDelete: Strings.post)
                    .present(context)
                    .then((shouldDelete) => shouldDelete ?? false);
                if (shouldDeletePost) {
                  await ref
                      .read(deletePostProvider.notifier)
                      .deletePost(post: widget.post);
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
        ],
      ),
      body: postWithComments.when(
        data: (postWithComments) {
          final postId = postWithComments.post.postId;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PostImageOrVideoView(post: postWithComments.post),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (postWithComments.post.allowLikes)
                      LikeButton(
                        postId: postId,
                      ),
                    if (postWithComments.post.allowComments)
                      IconButton(
                        icon: const Icon(Icons.mode_comment_outlined),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                PostCommentsView(postId: postId),
                          ));
                        },
                      )
                  ],
                ),
                PostDisplayNameAndMessageView(post: postWithComments.post),
                PostDateView(dateTime: postWithComments.post.createdAt),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Divider(
                    color: Colors.black54,
                  ),
                ),
                CompactCommentColumn(comments: postWithComments.comments),
                if (postWithComments.post.allowLikes)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        LikesCountView(
                          postId: postId,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(
                  height: 100,
                ),
              ],
            ),
          );
        },
        error: (error, stackTrace) {
          return const SmallErrorAnimationView();
        },
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
