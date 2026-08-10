import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  ReviewModel({
    this.id,
    this.jobId,
    this.reviewerId,
    this.reviewedId,
    this.rating,
    this.comment,
    this.photos = const [],
    this.videos = const [],
    this.ratings,
    this.isAnonymous = false,
    this.createdAt,
    this.updatedAt,
    this.isResponse = false,
    this.responseText,
    this.responseAt,
    this.reviewerName,
    this.reviewerPhoto,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'],
      jobId: map['jobId'],
      reviewerId: map['reviewerId'],
      reviewedId: map['reviewedId'],
      rating: map['rating']?.toDouble(),
      comment: map['comment'],
      photos: List<String>.from(map['photos'] ?? []),
      videos: List<String>.from(map['videos'] ?? []),
      ratings: map['ratings']?.cast<String, double>(),
      isAnonymous: map['isAnonymous'] ?? false,
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
      isResponse: map['isResponse'] ?? false,
      responseText: map['responseText'],
      responseAt: map['responseAt']?.toDate(),
    );
  }
  final String? id;
  final String? jobId;
  final String? reviewerId;
  final String? reviewedId;
  final double? rating;
  final String? comment;
  final List<String>? photos;
  final List<String>? videos;
  final Map<String, double>? ratings; // For multiple rating dimensions
  final bool? isAnonymous;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isResponse;
  final String? responseText;
  final DateTime? responseAt;

  // Not persisted to Firestore - populated client-side by joining against
  // the reviewer's user doc, so the UI has a name/photo to show.
  final String? reviewerName;
  final String? reviewerPhoto;

  Map<String, dynamic> toMap() => {
    'id': id,
    'jobId': jobId,
    'reviewerId': reviewerId,
    'reviewedId': reviewedId,
    'rating': rating,
    'comment': comment,
    'photos': photos,
    'videos': videos,
    'ratings': ratings,
    'isAnonymous': isAnonymous,
    'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    'isResponse': isResponse,
    'responseText': responseText,
    'responseAt': responseAt,
  };

  ReviewModel copyWith({
    String? id,
    String? jobId,
    String? reviewerId,
    String? reviewedId,
    double? rating,
    String? comment,
    List<String>? photos,
    List<String>? videos,
    Map<String, double>? ratings,
    bool? isAnonymous,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isResponse,
    String? responseText,
    DateTime? responseAt,
    String? reviewerName,
    String? reviewerPhoto,
  }) => ReviewModel(
    id: id ?? this.id,
    jobId: jobId ?? this.jobId,
    reviewerId: reviewerId ?? this.reviewerId,
    reviewedId: reviewedId ?? this.reviewedId,
    rating: rating ?? this.rating,
    comment: comment ?? this.comment,
    photos: photos ?? this.photos,
    videos: videos ?? this.videos,
    ratings: ratings ?? this.ratings,
    isAnonymous: isAnonymous ?? this.isAnonymous,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isResponse: isResponse ?? this.isResponse,
    responseText: responseText ?? this.responseText,
    responseAt: responseAt ?? this.responseAt,
    reviewerName: reviewerName ?? this.reviewerName,
    reviewerPhoto: reviewerPhoto ?? this.reviewerPhoto,
  );
}
