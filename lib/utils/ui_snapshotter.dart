import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// Helper that captures UI snapshots from [RenderRepaintBoundary] widgets.
///
/// The holographic interface is wrapped in a `RepaintBoundary` so we can grab
/// pixel-perfect previews for QA handoff documents or bug reports without
/// relying on platform specific screenshot tooling.
class UISnapshotter {
  const UISnapshotter._();

  /// Captures the provided [boundary] as a PNG encoded byte list.
  static Future<Uint8List> captureBoundary(
    RenderRepaintBoundary boundary, {
    double pixelRatio = 2.0,
  }) async {
    await _waitForBoundaryPaint(boundary);

    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Unable to encode repaint boundary as PNG data.');
    }
    return byteData.buffer.asUint8List();
  }

  /// Attempts to locate a [RenderRepaintBoundary] for the provided [key] and
  /// capture it as PNG bytes.
  static Future<Uint8List> captureFromGlobalKey(
    GlobalKey boundaryKey, {
    double pixelRatio = 2.0,
  }) async {
    final context = boundaryKey.currentContext;
    if (context == null) {
      throw StateError('RepaintBoundary context not ready for snapshot capture');
    }
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError(
        'Expected a RenderRepaintBoundary but found ${renderObject.runtimeType}',
      );
    }
    return captureBoundary(renderObject, pixelRatio: pixelRatio);
  }

  static Future<void> _waitForBoundaryPaint(RenderRepaintBoundary boundary) async {
    if (!boundary.debugNeedsPaint) {
      return;
    }

    await Future<void>.delayed(Duration.zero);
    await SchedulerBinding.instance.endOfFrame;

    if (boundary.debugNeedsPaint) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }
}
