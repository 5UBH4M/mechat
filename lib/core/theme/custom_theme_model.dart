import 'dart:convert';
import 'package:flutter/material.dart';

class CustomThemeModel {
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final String fontFamily;
  final double bubbleRadius;

  const CustomThemeModel({
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.fontFamily,
    required this.bubbleRadius,
  });

  factory CustomThemeModel.defaultTheme() {
    return const CustomThemeModel(
      primaryColor: Color(0xFF6366F1),
      secondaryColor: Color(0xFF14B8A6),
      backgroundColor: Color(0xFF0E131F),
      surfaceColor: Color(0xFF1E293B),
      fontFamily: 'Roboto',
      bubbleRadius: 16.0,
    );
  }

  CustomThemeModel copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? backgroundColor,
    Color? surfaceColor,
    String? fontFamily,
    double? bubbleRadius,
  }) {
    return CustomThemeModel(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      fontFamily: fontFamily ?? this.fontFamily,
      bubbleRadius: bubbleRadius ?? this.bubbleRadius,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primaryColor': primaryColor.value,
      'secondaryColor': secondaryColor.value,
      'backgroundColor': backgroundColor.value,
      'surfaceColor': surfaceColor.value,
      'fontFamily': fontFamily,
      'bubbleRadius': bubbleRadius,
    };
  }

  factory CustomThemeModel.fromJson(Map<String, dynamic> json) {
    return CustomThemeModel(
      primaryColor: Color(json['primaryColor'] ?? 0xFF6366F1),
      secondaryColor: Color(json['secondaryColor'] ?? 0xFF14B8A6),
      backgroundColor: Color(json['backgroundColor'] ?? 0xFF0E131F),
      surfaceColor: Color(json['surfaceColor'] ?? 0xFF1E293B),
      fontFamily: json['fontFamily'] ?? 'Roboto',
      bubbleRadius: (json['bubbleRadius'] as num?)?.toDouble() ?? 16.0,
    );
  }
}
