import 'package:flutter/material.dart';

/// BubbleTheme provides a simplified interface for chat bubble styling
/// that bridges the gap between the old theme system and the current AdvancedChatTheme
class BubbleTheme {
  final BoxDecoration? messageDecoration;
  final BoxDecoration? userMessageDecoration;
  final TextStyle? messageTextStyle;
  final TextStyle? userMessageTextStyle;
  final EdgeInsets? messagePadding;
  final InputDecoration? inputDecoration;
  final TextStyle? inputTextStyle;
  final String name;

  const BubbleTheme({
    required this.name,
    this.messageDecoration,
    this.userMessageDecoration,
    this.messageTextStyle,
    this.userMessageTextStyle,
    this.messagePadding,
    this.inputDecoration,
    this.inputTextStyle,
  });

  /// Gradient theme with colorful bubbles
  factory BubbleTheme.gradient() {
    return const BubbleTheme(
      name: 'Gradient',
      messageDecoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      userMessageDecoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Color(0x20000000),
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      messageTextStyle: TextStyle(
        color: Color(0xFF2D3748),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      userMessageTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      messagePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      inputDecoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          borderSide: BorderSide(color: Color(0xFF6C5CE7), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      inputTextStyle: TextStyle(
        color: Color(0xFF2D3748),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  /// Neon theme with bright, glowing effects
  factory BubbleTheme.neon() {
    return const BubbleTheme(
      name: 'Neon',
      messageDecoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.all(Radius.circular(16)),
        border: Border.fromBorderSide(
          BorderSide(color: Color(0xFF00FF88), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x4000FF88),
            offset: Offset(0, 0),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      userMessageDecoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.all(Radius.circular(16)),
        border: Border.fromBorderSide(
          BorderSide(color: Color(0xFFFF0080), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x40FF0080),
            offset: Offset(0, 0),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      messageTextStyle: TextStyle(
        color: Color(0xFF00FF88),
        fontSize: 16,
        fontWeight: FontWeight.w400,
        shadows: [
          Shadow(color: Color(0x4000FF88), offset: Offset(0, 0), blurRadius: 8),
        ],
      ),
      userMessageTextStyle: TextStyle(
        color: Color(0xFFFF0080),
        fontSize: 16,
        fontWeight: FontWeight.w500,
        shadows: [
          Shadow(color: Color(0x40FF0080), offset: Offset(0, 0), blurRadius: 8),
        ],
      ),
      messagePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      inputDecoration: InputDecoration(
        filled: true,
        fillColor: Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          borderSide: BorderSide(color: Color(0xFF00FF88)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          borderSide: BorderSide(color: Color(0xFF00FF88)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          borderSide: BorderSide(color: Color(0xFF00FF88), width: 3),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      inputTextStyle: TextStyle(
        color: Color(0xFF00FF88),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  /// Glassmorphic theme with blur and transparency effects
  factory BubbleTheme.glassmorphic() {
    return const BubbleTheme(
      name: 'Glassmorphic',
      messageDecoration: BoxDecoration(
        color: Color(0x40FFFFFF),
        borderRadius: BorderRadius.all(Radius.circular(20)),
        border: Border.fromBorderSide(
          BorderSide(color: Color(0x20FFFFFF), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
            offset: Offset(0, 8),
            blurRadius: 32,
            spreadRadius: 0,
          ),
        ],
      ),
      userMessageDecoration: BoxDecoration(
        color: Color(0x60007AFF),
        borderRadius: BorderRadius.all(Radius.circular(20)),
        border: Border.fromBorderSide(
          BorderSide(color: Color(0x40FFFFFF), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x20007AFF),
            offset: Offset(0, 8),
            blurRadius: 32,
            spreadRadius: 0,
          ),
        ],
      ),
      messageTextStyle: TextStyle(
        color: Color(0xFF2D3748),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      userMessageTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      messagePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      inputDecoration: InputDecoration(
        filled: true,
        fillColor: Color(0x80FFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          borderSide: BorderSide(color: Color(0x20FFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          borderSide: BorderSide(color: Color(0x20FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          borderSide: BorderSide(color: Color(0x40FFFFFF), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      inputTextStyle: TextStyle(
        color: Color(0xFF2D3748),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  /// Elegant theme with sophisticated styling
  factory BubbleTheme.elegant() {
    return const BubbleTheme(
      name: 'Elegant',
      messageDecoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(8),
          bottomLeft: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            offset: Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      userMessageDecoration: BoxDecoration(
        color: Color(0xFF2D3748),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x15000000),
            offset: Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      messageTextStyle: TextStyle(
        color: Color(0xFF2D3748),
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      userMessageTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
      messagePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      inputDecoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
          borderSide: BorderSide(color: Color(0xFF2D3748), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      ),
      inputTextStyle: TextStyle(
        color: Color(0xFF2D3748),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  /// Minimal theme with clean, simple design
  factory BubbleTheme.minimal() {
    return const BubbleTheme(
      name: 'Minimal',
      messageDecoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.all(Radius.circular(12)),
        border: Border.fromBorderSide(
          BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      userMessageDecoration: BoxDecoration(
        color: Color(0xFF2D3748),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      messageTextStyle: TextStyle(
        color: Color(0xFF2D3748),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      userMessageTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      messagePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      inputDecoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color(0xFF2D3748), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      inputTextStyle: TextStyle(
        color: Color(0xFF2D3748),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
