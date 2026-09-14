import 'package:flutter/material.dart';

class BionicToken {
  final String boldPrefix;
  final String normalSuffix;

  const BionicToken({required this.boldPrefix, required this.normalSuffix});
}

class BionicReadingEngine {
  /// Converts a word into Bionic Reading bold prefix and normal suffix.
  /// E.g. "reading" -> boldPrefix: "rea", normalSuffix: "ding"
  static BionicToken processWord(String word) {
    if (word.isEmpty) return const BionicToken(boldPrefix: '', normalSuffix: '');

    // Extract leading punctuation
    int start = 0;
    while (start < word.length && _isPunctuation(word[start])) {
      start++;
    }

    // Extract trailing punctuation
    int end = word.length - 1;
    while (end >= start && _isPunctuation(word[end])) {
      end--;
    }

    if (start > end) {
      // Entire word is punctuation/symbols
      return BionicToken(boldPrefix: '', normalSuffix: word);
    }

    final leadingPunct = word.substring(0, start);
    final coreWord = word.substring(start, end + 1);
    final trailingPunct = word.substring(end + 1);

    int boldLength;
    if (coreWord.length <= 3) {
      boldLength = 1;
    } else if (coreWord.length <= 6) {
      boldLength = 2;
    } else if (coreWord.length <= 9) {
      boldLength = 3;
    } else {
      boldLength = (coreWord.length * 0.4).round();
    }

    final boldCore = coreWord.substring(0, boldLength);
    final normalCore = coreWord.substring(boldLength);

    return BionicToken(
      boldPrefix: leadingPunct + boldCore,
      normalSuffix: normalCore + trailingPunct,
    );
  }

  static bool _isPunctuation(String char) {
    return RegExp(r'[^\w\s]').hasMatch(char);
  }

  /// Builds a RichText TextSpan for Bionic Reading.
  static TextSpan buildBionicTextSpan({
    required String text,
    required TextStyle baseStyle,
    required TextStyle boldStyle,
  }) {
    final words = text.split(RegExp(r'(\s+)'));
    final List<InlineSpan> spans = [];

    for (final word in words) {
      if (word.trim().isEmpty) {
        spans.add(TextSpan(text: word, style: baseStyle));
      } else {
        final token = processWord(word);
        spans.add(
          TextSpan(
            children: [
              TextSpan(text: token.boldPrefix, style: boldStyle),
              TextSpan(text: token.normalSuffix, style: baseStyle),
            ],
          ),
        );
      }
    }

    return TextSpan(children: spans);
  }
}
