import 'dart:async';
import '../model/hashtag.dart';

abstract class HashtagRepository {

  Future<Hashtag> retrieve(String hashtag);
  Future<bool> exists(String hashtag);
  Future<void> insert(Hashtag hashtag);
  Future<bool> addPost(String hashtag, String postId);
  Future<bool> removePost(String hashtag, String postId);

}
