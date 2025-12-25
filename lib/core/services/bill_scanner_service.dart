import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;

/// Parsed bill data from OCR + AI
class ParsedBillData {
  final double? totalAmount;
  final String? vendorName;
  final String? category;
  final DateTime? date;
  final String? currency;
  final String? description;
  final double confidence; // 0.0 to 1.0
  final String rawText; // Original OCR text for debugging

  const ParsedBillData({
    this.totalAmount,
    this.vendorName,
    this.category,
    this.date,
    this.currency,
    this.description,
    this.confidence = 0.0,
    this.rawText = '',
  });

  factory ParsedBillData.fromJson(Map<String, dynamic> json) {
    return ParsedBillData(
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      vendorName: json['vendor_name'] as String?,
      category: json['category'] as String?,
      date: json['date'] != null ? DateTime.tryParse(json['date'] as String) : null,
      currency: json['currency'] as String? ?? 'INR',
      description: json['description'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      rawText: json['raw_text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_amount': totalAmount,
      'vendor_name': vendorName,
      'category': category,
      'date': date?.toIso8601String(),
      'currency': currency,
      'description': description,
      'confidence': confidence,
      'raw_text': rawText,
    };
  }

  @override
  String toString() {
    return 'ParsedBillData(totalAmount: $totalAmount, vendorName: $vendorName, category: $category, date: $date, currency: $currency, confidence: $confidence)';
  }
}

/// Service for scanning bills/receipts and extracting expense data
/// Uses ML Kit for OCR (on-device, free) + Groq LLM for parsing (free tier)
class BillScannerService {
  static const String _groqBaseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _groqModel = 'llama-3.3-70b-versatile';

  final String _groqApiKey;
  final TextRecognizer _textRecognizer;

  BillScannerService(this._groqApiKey)
      : _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Scan a bill image and extract expense data
  ///
  /// [imagePath] - Path to the bill image file
  /// Returns [ParsedBillData] with extracted information
  Future<ParsedBillData> scanBill(String imagePath) async {
    debugPrint('📸 [BillScanner] Starting bill scan for: $imagePath');

    try {
      // Step 1: Extract text using ML Kit OCR (on-device, free)
      final rawText = await _extractTextFromImage(imagePath);
      debugPrint('📝 [BillScanner] Extracted text (${rawText.length} chars)');

      if (rawText.trim().isEmpty) {
        debugPrint('⚠️ [BillScanner] No text found in image');
        return ParsedBillData(
          confidence: 0.0,
          rawText: '',
        );
      }

      // Step 2: Parse text using Groq LLM
      final parsedData = await _parseTextWithGroq(rawText);
      debugPrint('✅ [BillScanner] Parsed bill data: $parsedData');

      return parsedData;
    } catch (e, stackTrace) {
      debugPrint('❌ [BillScanner] Error scanning bill: $e');
      debugPrint('❌ [BillScanner] Stack: $stackTrace');
      rethrow;
    }
  }

  /// Extract text from image using ML Kit
  Future<String> _extractTextFromImage(String imagePath) async {
    debugPrint('🔍 [BillScanner] Running ML Kit OCR...');

    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    debugPrint('🔍 [BillScanner] ML Kit found ${recognizedText.blocks.length} text blocks');

    // Combine all text blocks
    final buffer = StringBuffer();
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        buffer.writeln(line.text);
      }
    }

    return buffer.toString();
  }

  /// Parse extracted text using Groq LLM
  Future<ParsedBillData> _parseTextWithGroq(String rawText) async {
    debugPrint('🤖 [BillScanner] Sending text to Groq for parsing...');

    final prompt = _buildParsingPrompt(rawText);

    final response = await http.post(
      Uri.parse(_groqBaseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_groqApiKey',
      },
      body: jsonEncode({
        'model': _groqModel,
        'messages': [
          {
            'role': 'system',
            'content': 'You are a receipt/bill parser. Extract expense information from OCR text and respond with valid JSON only. No markdown, no explanations.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.1, // Low temperature for consistent parsing
        'max_tokens': 500,
      }),
    );

    if (response.statusCode != 200) {
      debugPrint('❌ [BillScanner] Groq API error: ${response.statusCode}');
      debugPrint('Response: ${response.body}');
      throw Exception('Failed to parse bill: ${response.statusCode}');
    }

    final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = jsonResponse['choices'] as List?;

    if (choices == null || choices.isEmpty) {
      throw Exception('No response from Groq');
    }

    final content = choices[0]['message']['content'] as String;
    debugPrint('🤖 [BillScanner] Groq response: $content');

    // Parse the JSON response
    try {
      final cleanContent = _cleanJsonResponse(content);
      final parsedJson = jsonDecode(cleanContent) as Map<String, dynamic>;

      // Add raw text to the result
      parsedJson['raw_text'] = rawText;

      return ParsedBillData.fromJson(parsedJson);
    } catch (e) {
      debugPrint('⚠️ [BillScanner] Failed to parse Groq response, using fallback');
      // Fallback: try to extract amount using regex
      return _fallbackParsing(rawText);
    }
  }

  /// Build the parsing prompt for Groq
  String _buildParsingPrompt(String ocrText) {
    return '''
Extract expense information from this bill/receipt OCR text:

"""
$ocrText
"""

Extract the following and respond with JSON only:

{
  "total_amount": <number or null - the FINAL TOTAL amount paid, not subtotals>,
  "vendor_name": "<string or null - store/restaurant/vendor name>",
  "category": "<one of: food, transport, accommodation, activities, shopping, other>",
  "date": "<YYYY-MM-DD format or null if not found>",
  "currency": "<3-letter code like INR, USD, EUR - default INR for Indian receipts>",
  "description": "<brief description like 'Lunch at [restaurant]' or 'Grocery shopping'>",
  "confidence": <0.0-1.0 how confident you are in the extraction>
}

IMPORTANT:
- Look for words like "Total", "Grand Total", "Net Amount", "Amount Payable" for the final amount
- Ignore subtotals, tax breakdowns, discounts - only report FINAL amount
- If multiple amounts found, pick the largest reasonable total
- If currency symbol ₹ or Rs found, use INR
- Category should be based on vendor type (restaurant=food, hotel=accommodation, etc.)
- Confidence should be high (0.8+) only if total amount is clearly identified
''';
  }

  /// Clean JSON response from Groq (remove markdown if present)
  String _cleanJsonResponse(String content) {
    String cleaned = content.trim();

    // Remove markdown code blocks
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }

    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }

    cleaned = cleaned.trim();

    // Find JSON object
    final jsonStart = cleaned.indexOf('{');
    final jsonEnd = cleaned.lastIndexOf('}');

    if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
      cleaned = cleaned.substring(jsonStart, jsonEnd + 1);
    }

    return cleaned;
  }

  /// Fallback parsing using regex when LLM fails
  ParsedBillData _fallbackParsing(String rawText) {
    debugPrint('🔧 [BillScanner] Using fallback regex parsing');

    // Try to find amounts (Indian format: ₹1,234.56 or Rs. 1234)
    final amountPatterns = [
      RegExp(r'(?:Total|Grand\s*Total|Net|Amount|Payable)[:\s]*[₹Rs.]*\s*([\d,]+(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'[₹]\s*([\d,]+(?:\.\d{2})?)'),
      RegExp(r'Rs\.?\s*([\d,]+(?:\.\d{2})?)'),
      RegExp(r'([\d,]+\.\d{2})'), // Any decimal amount
    ];

    double? maxAmount;
    for (final pattern in amountPatterns) {
      final matches = pattern.allMatches(rawText);
      for (final match in matches) {
        final amountStr = match.group(1)?.replaceAll(',', '');
        final amount = double.tryParse(amountStr ?? '');
        if (amount != null && (maxAmount == null || amount > maxAmount)) {
          maxAmount = amount;
        }
      }
    }

    // Try to find date
    final datePattern = RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})');
    DateTime? date;
    final dateMatch = datePattern.firstMatch(rawText);
    if (dateMatch != null) {
      final day = int.tryParse(dateMatch.group(1) ?? '');
      final month = int.tryParse(dateMatch.group(2) ?? '');
      var year = int.tryParse(dateMatch.group(3) ?? '');
      if (year != null && year < 100) year += 2000;
      if (day != null && month != null && year != null) {
        try {
          date = DateTime(year, month, day);
        } catch (_) {}
      }
    }

    return ParsedBillData(
      totalAmount: maxAmount,
      date: date,
      currency: 'INR',
      category: 'other',
      confidence: maxAmount != null ? 0.5 : 0.0,
      rawText: rawText,
    );
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}
