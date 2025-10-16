import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'package:synther_holographic_pro/core/audio_engine.dart';
import 'package:synther_holographic_pro/core/basic_audio_backend.dart';
import 'package:synther_holographic_pro/ui/vaporwave_interface.dart';
import 'package:synther_holographic_pro/utils/ui_snapshotter.dart';

class _FakeWebViewPlatform extends WebViewPlatform {
  _FakeWebViewPlatform() : super();

  @override
  PlatformWebViewCookieManager createPlatformCookieManager(
    PlatformWebViewCookieManagerCreationParams params,
  ) {
    return _FakeCookieManager(params);
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return _FakeNavigationDelegate(params);
  }

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return _FakePlatformWebViewController(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return _FakePlatformWebViewWidget(params);
  }
}

class _FakePlatformWebViewController extends PlatformWebViewController {
  _FakePlatformWebViewController(PlatformWebViewControllerCreationParams params)
      : super.implementation(params);

  @override
  Future<void> loadFile(String absoluteFilePath) async {}

  @override
  Future<void> loadFlutterAsset(String key) async {}

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {}

  @override
  Future<void> loadRequest(LoadRequestParams params) async {}

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> runJavaScript(String javaScript) async {}

  @override
  Future<Object?> runJavaScriptReturningResult(String javaScript) async => null;

  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams params) async {}

  @override
  Future<void> removeJavaScriptChannel(String javaScriptChannelName) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}

  @override
  Future<bool> canGoBack() async => false;

  @override
  Future<bool> canGoForward() async => false;

  @override
  Future<void> goBack() async {}

  @override
  Future<void> goForward() async {}

  @override
  Future<void> reload() async {}

  @override
  Future<void> scrollBy(int x, int y) async {}

  @override
  Future<void> scrollTo(int x, int y) async {}

  @override
  Future<void> setUserAgent(String? userAgent) async {}

  @override
  Future<String?> getTitle() async => 'fake-webview';

  @override
  Future<void> enableZoom(bool enabled) async {}

  @override
  Future<void> clearCache() async {}

  @override
  Future<void> clearLocalStorage() async {}

  @override
  Future<void> setOnPlatformPermissionRequest(
      PlatformWebViewPermissionRequestHandler handler) async {}
}

class _FakePlatformWebViewWidget extends PlatformWebViewWidget {
  _FakePlatformWebViewWidget(PlatformWebViewWidgetCreationParams params)
      : super.implementation(params);

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Colors.black);
  }
}

class _FakeNavigationDelegate extends PlatformNavigationDelegate {
  _FakeNavigationDelegate(PlatformNavigationDelegateCreationParams params)
      : super.implementation(params);

  @override
  Future<void> setOnNavigationRequest(
      NavigationRequestCallback onNavigationRequest) async {}

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {}

  @override
  Future<void> setOnHttpError(HttpResponseErrorCallback onHttpError) async {}

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {}

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {}

  @override
  Future<void> setOnUrlChange(UrlChangeCallback onUrlChange) async {}

  @override
  Future<void> setOnHttpAuthRequest(HttpAuthRequestCallback onHttpAuthRequest) async {}

  @override
  Future<void> setOnSSlAuthError(SslAuthErrorCallback onSslAuthError) async {}
}

class _FakeCookieManager extends PlatformWebViewCookieManager {
  _FakeCookieManager(PlatformWebViewCookieManagerCreationParams params)
      : super.implementation(params);

  @override
  Future<bool> clearCookies() async => true;

  @override
  Future<void> setCookie(WebViewCookie cookie) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WebViewPlatform.instance = _FakeWebViewPlatform();

  const snapshotDir = String.fromEnvironment(
    'SNAPSHOT_OUTPUT_DIR',
    defaultValue: 'build/ui_snapshots',
  );

  testWidgets('captures vaporwave interface snapshot', (tester) async {
    final audioEngine = AudioEngine(backend: BasicAudioBackend());
    addTearDown(audioEngine.dispose);
    await audioEngine.initialize();

    await tester.pumpWidget(
      ChangeNotifierProvider<AudioEngine>.value(
        value: audioEngine,
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: VaporwaveInterface(),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    final repaintFinder = find.byWidgetPredicate((widget) {
      return widget is RepaintBoundary &&
          widget.key is GlobalKey &&
          (widget.key as GlobalKey).debugLabel == 'vaporwaveSnapshot';
    });

    expect(repaintFinder, findsOneWidget);

    final boundary =
        tester.renderObject<RenderRepaintBoundary>(repaintFinder.first);

    final Uint8List bytes = await UISnapshotter.captureBoundary(boundary);

    expect(bytes.length, greaterThan(2048));

    final directory = Directory(snapshotDir)..createSync(recursive: true);
    final file =
        File('${directory.path}${Platform.pathSeparator}vaporwave_interface.png');
    await file.writeAsBytes(bytes, flush: true);

    expect(file.existsSync(), isTrue);
  });
}
