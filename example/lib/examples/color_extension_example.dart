import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() {
  runApp(const ColorExtensionApp());
}

class ColorExtensionApp extends StatelessWidget {
  const ColorExtensionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Extension Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ColorExtensionDemo(),
    );
  }
}

class ColorExtensionDemo extends StatelessWidget {
  const ColorExtensionDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // Base color
    const baseColor = Colors.blue;

    // Various transformations using withValues
    final variants = [
      ColorVariant('Original', baseColor),
      ColorVariant('Alpha 50%', baseColor.withOpacityCompat(0.5)),
      ColorVariant('Alpha 25%', baseColor.withOpacityCompat(0.25)),
      ColorVariant('Red 255', baseColor.withValues(red: 255)),
      ColorVariant('Green 255', baseColor.withValues(green: 255)),
      ColorVariant('Blue 100', baseColor.withValues(blue: 100)),
      ColorVariant(
          'Multiple Changes',
          baseColor
              .withValues(red: 200, green: 100, blue: 50)
              .withOpacityCompat(0.8)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Extension Demo'),
        backgroundColor: baseColor,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: variants.length,
        itemBuilder: (context, index) {
          final variant = variants[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ColorTile(
              title: variant.name,
              color: variant.color,
            ),
          );
        },
      ),
    );
  }
}

class ColorTile extends StatelessWidget {
  final String title;
  final Color color;

  const ColorTile({
    super.key,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate a contrasting text color
    final luminance = color.computeLuminance();
    final textColor = luminance > 0.5 ? Colors.black : Colors.white;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacityCompat(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$title (${color.r}, ${color.g}, ${color.b}, ${color.a.toStringAsFixed(2)}),',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class ColorVariant {
  final String name;
  final Color color;

  ColorVariant(this.name, this.color);
}
