// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'books_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BooksResponse _$BooksResponseFromJson(Map<String, dynamic> json) =>
    BooksResponse(
      id: json['_id'] as String?,
      title: json['title'] as String?,
      author: json['author'] as String?,
      category: json['category'] as String?,
      description: json['description'] as String?,
      pdfUrl: json['pdfUrl'] as String?,
      wordUrl: json['wordUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      partsCount: (json['partsCount'] as num?)?.toInt(),
      subject: json['subject'] as String?,
      language: json['language'] as String?,
      publisher: json['publisher'] as String?,
      publishingPlace: json['publishingPlace'] as String?,
      publicationYear: (json['publicationYear'] as num?)?.toInt(),
      century: json['century'] as String?,
      authorDoctrine: json['authorDoctrine'] as String?,
      bookVersion: json['bookVersion'] as String?,
      otherNames:
          (json['otherNames'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      createdAt:
          json['createdAt'] == null
              ? null
              : DateTime.parse(json['createdAt'] as String),
      updatedAt:
          json['updatedAt'] == null
              ? null
              : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$BooksResponseToJson(BooksResponse instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'title': instance.title,
      'author': instance.author,
      'category': instance.category,
      'description': instance.description,
      'pdfUrl': instance.pdfUrl,
      'wordUrl': instance.wordUrl,
      'audioUrl': instance.audioUrl,
      'imageUrl': instance.imageUrl,
      'partsCount': instance.partsCount,
      'subject': instance.subject,
      'language': instance.language,
      'publisher': instance.publisher,
      'publishingPlace': instance.publishingPlace,
      'publicationYear': instance.publicationYear,
      'century': instance.century,
      'authorDoctrine': instance.authorDoctrine,
      'bookVersion': instance.bookVersion,
      'otherNames': instance.otherNames,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
