
class Review {

  String id;
  String text;
  int ratingValue;
  int createdDate;
  String reviewerProfileId;
  String reviewerName;
  String reviewerTitle;
  String profileImgUrl;
  bool recommend;

  Review({
    this.id = "",
    this.text = "",
    this.ratingValue = 0,
    this.createdDate = 0,
    this.reviewerProfileId = "",
    this.reviewerName = "",
    this.reviewerTitle = "",
    this.profileImgUrl = "",
    this.recommend = true,
  });

  @override
  String toString() {
    return 'Review{id: $id, text: $text, ratingValue: $ratingValue, createdDate: $createdDate, reviewerProfileId: $reviewerProfileId, reviewerName: $reviewerName, reviewerTitle: $reviewerTitle, profileImgUrl: $profileImgUrl, recommend: $recommend}';
  }

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      'ratingValue': ratingValue,
      'createdDate': createdDate,
      'reviewerProfile': reviewerProfileId,
      'reviewerName': reviewerName,
      'reviewerTitle': reviewerTitle,
      'profileImgUrl':profileImgUrl,
      'recommend': recommend
    };
  }

  Review.fromJSON(data) :
    id = data["id"] ?? "",
    text = data["text"] ?? "",
    ratingValue = data["ratingValue"] ?? 0,
    createdDate = data["createdDate"] ?? 0,
    reviewerProfileId = data["reviewerProfile"] ?? "",
    reviewerName = data["reviewerName"] ?? "",
    reviewerTitle = data["reviewerTitle"] ?? "",
    profileImgUrl = data["profileImgUrl"] ?? "",
    recommend = data["recommend"] ?? false;

}
