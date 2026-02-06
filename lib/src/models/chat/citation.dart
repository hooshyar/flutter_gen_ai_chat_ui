import 'package:flutter/foundation.dart';

/// Represents a single citation/source reference in a chat message.
/// Designed for legal citations but flexible enough for any source reference.
class ChatCitation {
  /// Unique identifier for the citation
  final String id;

  /// Short inline citation text (e.g., "Art. 7, Law 43")
  final String shortCitation;

  /// Full formal citation text
  final String fullCitation;

  /// Optional source title (e.g., law name, document title)
  final String? sourceTitle;

  /// Optional source number (e.g., law number, article number)
  final String? sourceNumber;

  /// Optional year of the source
  final int? year;

  /// Optional category/domain (e.g., "civil_law", "criminal_law")
  final String? category;

  /// Optional content excerpt from the source
  final String? contentExcerpt;

  /// Localized citations for different languages (e.g., {'ar': '...', 'en': '...'})
  final Map<String, String>? localizedCitations;

  /// Localized titles for different languages
  final Map<String, String>? localizedTitles;

  /// Localized content for different languages
  final Map<String, String>? localizedContent;

  /// Custom properties for additional data
  final Map<String, dynamic>? customProperties;

  const ChatCitation({
    required this.id,
    required this.shortCitation,
    required this.fullCitation,
    this.sourceTitle,
    this.sourceNumber,
    this.year,
    this.category,
    this.contentExcerpt,
    this.localizedCitations,
    this.localizedTitles,
    this.localizedContent,
    this.customProperties,
  });

  /// Factory constructor from JSON/Map
  factory ChatCitation.fromJson(Map<String, dynamic> json) {
    try {
      return ChatCitation(
        id: json['id']?.toString() ?? json['article_id']?.toString() ?? '',
        shortCitation: json['short_citation']?.toString() ?? '',
        fullCitation: json['full_citation']?.toString() ??
            json['legal_citation']?.toString() ??
            '',
        sourceTitle: json['source_title']?.toString() ??
            json['law_title']?.toString(),
        sourceNumber: json['source_number']?.toString() ??
            json['law_number']?.toString() ??
            json['article_number']?.toString(),
        year: json['year'] is int
            ? json['year'] as int
            : int.tryParse(json['year']?.toString() ?? ''),
        category: json['category']?.toString() ??
            json['legal_domain']?.toString(),
        contentExcerpt: json['content_excerpt']?.toString() ??
            json['matched_content']?.toString(),
        localizedCitations: _parseStringMap(json['localized_citations'] ??
            json['citations_all_languages']),
        localizedTitles: _parseStringMap(json['localized_titles'] ??
            json['law_title']),
        localizedContent: _parseStringMap(json['localized_content'] ??
            json['matched_content_all_languages']),
        customProperties: json['custom_properties'] as Map<String, dynamic>?,
      );
    } catch (e) {
      debugPrint('Error parsing ChatCitation: $e');
      return ChatCitation(
        id: '',
        shortCitation: '',
        fullCitation: '',
      );
    }
  }

  /// Helper to parse a Map<String, String> from dynamic
  static Map<String, String>? _parseStringMap(dynamic data) {
    if (data == null) return null;
    if (data is! Map) return null;
    try {
      return Map<String, String>.from(
        data.map((key, value) => MapEntry(key.toString(), value.toString())),
      );
    } catch (_) {
      return null;
    }
  }

  /// Convert to JSON/Map
  Map<String, dynamic> toJson() => {
        'id': id,
        'short_citation': shortCitation,
        'full_citation': fullCitation,
        if (sourceTitle != null) 'source_title': sourceTitle,
        if (sourceNumber != null) 'source_number': sourceNumber,
        if (year != null) 'year': year,
        if (category != null) 'category': category,
        if (contentExcerpt != null) 'content_excerpt': contentExcerpt,
        if (localizedCitations != null) 'localized_citations': localizedCitations,
        if (localizedTitles != null) 'localized_titles': localizedTitles,
        if (localizedContent != null) 'localized_content': localizedContent,
        if (customProperties != null) 'custom_properties': customProperties,
      };

  /// Get citation in a specific language with fallback
  String getCitationInLanguage(String language) {
    return localizedCitations?[language] ?? fullCitation;
  }

  /// Get title in a specific language with fallback
  String? getTitleInLanguage(String language) {
    return localizedTitles?[language] ?? sourceTitle;
  }

  /// Get content in a specific language with fallback
  String? getContentInLanguage(String language) {
    return localizedContent?[language] ?? contentExcerpt;
  }

  /// Whether this citation has content available
  bool get hasContent => contentExcerpt != null && contentExcerpt!.isNotEmpty;

  /// Whether this citation has localized content
  bool get hasLocalizedContent =>
      localizedContent != null && localizedContent!.isNotEmpty;

  /// Create a copy with modified fields
  ChatCitation copyWith({
    String? id,
    String? shortCitation,
    String? fullCitation,
    String? sourceTitle,
    String? sourceNumber,
    int? year,
    String? category,
    String? contentExcerpt,
    Map<String, String>? localizedCitations,
    Map<String, String>? localizedTitles,
    Map<String, String>? localizedContent,
    Map<String, dynamic>? customProperties,
  }) =>
      ChatCitation(
        id: id ?? this.id,
        shortCitation: shortCitation ?? this.shortCitation,
        fullCitation: fullCitation ?? this.fullCitation,
        sourceTitle: sourceTitle ?? this.sourceTitle,
        sourceNumber: sourceNumber ?? this.sourceNumber,
        year: year ?? this.year,
        category: category ?? this.category,
        contentExcerpt: contentExcerpt ?? this.contentExcerpt,
        localizedCitations: localizedCitations ?? this.localizedCitations,
        localizedTitles: localizedTitles ?? this.localizedTitles,
        localizedContent: localizedContent ?? this.localizedContent,
        customProperties: customProperties ?? this.customProperties,
      );

  @override
  String toString() =>
      'ChatCitation(id: $id, shortCitation: $shortCitation)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatCitation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Container for citations attached to a message
class ChatCitationsData {
  /// List of citations for the message
  final List<ChatCitation> citations;

  /// Language code for display (e.g., 'ar', 'en', 'ku')
  final String language;

  /// Optional label for the citations section
  final String? sectionLabel;

  const ChatCitationsData({
    required this.citations,
    this.language = 'en',
    this.sectionLabel,
  });

  /// Factory constructor from JSON/Map
  factory ChatCitationsData.fromJson(Map<String, dynamic> json) {
    return ChatCitationsData(
      citations: (json['citations'] as List?)
              ?.map((e) => ChatCitation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      language: json['language']?.toString() ?? 'en',
      sectionLabel: json['section_label']?.toString(),
    );
  }

  /// Convert to JSON/Map
  Map<String, dynamic> toJson() => {
        'citations': citations.map((c) => c.toJson()).toList(),
        'language': language,
        if (sectionLabel != null) 'section_label': sectionLabel,
      };

  /// Whether there are any citations
  bool get hasCitations => citations.isNotEmpty;

  /// Get the primary/first citation
  ChatCitation? get primaryCitation =>
      citations.isNotEmpty ? citations.first : null;

  /// Get default section label based on language
  String getDefaultSectionLabel() {
    switch (language) {
      case 'ar':
        return 'المصادر';
      case 'ku':
        return 'سەرچاوەکان';
      default:
        return 'Sources';
    }
  }

  /// Create a copy with modified fields
  ChatCitationsData copyWith({
    List<ChatCitation>? citations,
    String? language,
    String? sectionLabel,
  }) =>
      ChatCitationsData(
        citations: citations ?? this.citations,
        language: language ?? this.language,
        sectionLabel: sectionLabel ?? this.sectionLabel,
      );
}
