/// Synther Design System
/// Professional vaporwave aesthetic with neo-skeuomorphic components
/// 
/// This is the main entry point for all design system modules.
/// Import this file to access all design tokens, components, and utilities.

// Core design tokens
export 'tokens.dart';

// Typography system
export 'typography.dart';

// Shadow system
export 'shadows.dart';

// Animation system
export 'animations.dart';

// Responsive system
export 'responsive.dart';

// Component library
export 'components/components.dart';

// Re-export commonly used Flutter widgets for convenience
export 'package:flutter/material.dart' show 
  BuildContext,
  Widget,
  StatelessWidget,
  StatefulWidget,
  State,
  Key,
  Color,
  Colors,
  EdgeInsets,
  EdgeInsetsGeometry,
  BorderRadius,
  BoxDecoration,
  Container,
  Row,
  Column,
  Stack,
  Positioned,
  Align,
  Alignment,
  Center,
  Padding,
  SizedBox,
  Expanded,
  Flexible,
  Text,
  Icon,
  IconData,
  Icons,
  GestureDetector,
  InkWell,
  MouseRegion,
  AnimatedContainer,
  AnimatedBuilder,
  Animation,
  AnimationController,
  Tween,
  Curve,
  Curves,
  Duration,
  VoidCallback,
  ValueChanged,
  TickerProvider,
  SingleTickerProviderStateMixin,
  TickerProviderStateMixin;