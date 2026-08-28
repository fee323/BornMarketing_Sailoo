import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  if (WebViewPlatform.instance == null) {
    WebViewPlatform.instance = AndroidWebViewPlatform();
  }

  runApp(const MyApp());
}

const _callChannel = MethodChannel('com.cartzlink.bmapp/call');

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

// ─── SPLASH ───────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSaved();
  }

  Future<void> _checkSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('subdomain');
    if (!mounted) return;
    if (saved != null && saved.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => WebViewScreen(subdomain: saved)),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const KeywordInputScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFF1AF00)),
      ),
    );
  }
}

// ─── KEYWORD INPUT SCREEN ─────────────────────────────────────
class KeywordInputScreen extends StatefulWidget {
  const KeywordInputScreen({super.key});

  @override
  State<KeywordInputScreen> createState() => _KeywordInputScreenState();
}

class _KeywordInputScreenState extends State<KeywordInputScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _saving = false;
  String? _error;

  Future<void> _continue() async {
    final keyword = _controller.text.trim().toLowerCase();
    if (keyword.isEmpty) {
      setState(() => _error = 'Please enter your keyword');
      return;
    }
    final valid = RegExp(r'^[a-z0-9\-]+$').hasMatch(keyword);
    if (!valid) {
      setState(() => _error = 'Invalid keyword. Only letters and numbers allowed.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subdomain', keyword);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => WebViewScreen(subdomain: keyword)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;

    final logoWidth = (shortestSide * 0.65).clamp(170.0, 400.0);
    final horizontalPad = (size.width * 0.08).clamp(24.0, 80.0);
    const maxContentWidth = 480.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    width: logoWidth,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Welcome',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Enter your keyword to get started',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black45),
                  ),
                  const SizedBox(height: 48),

                  // ─── INPUT FIELD ───────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _error != null
                            ? Colors.red.shade300
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _continue(),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black),
                      decoration: const InputDecoration(
                        hintText: 'Keyword',
                        hintStyle: TextStyle(
                            color: Colors.black26,
                            fontWeight: FontWeight.normal),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 18, vertical: 18),
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _error!,
                        style: TextStyle(
                            color: Colors.red.shade600, fontSize: 12),
                      ),
                    ),
                  ],

                  // ─── CONTINUE BUTTON (same width as field) ─
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1AF00),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        elevation: 2,
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : const Text(
                              'CONTINUE',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1),
                            ),
                    ),
                  ),

                  // ─── POWERED BY ────────────────────────────
                  const SizedBox(height: 20),
                  const Text.rich(
                    TextSpan(
                      text: 'Powered by ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black38,
                        letterSpacing: 0.3,
                      ),
                      children: [
                        TextSpan(
                          text: 'Born Marketerz',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFF1AF00),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── WEBVIEW SCREEN ───────────────────────────────────────────
class WebViewScreen extends StatefulWidget {
  final String subdomain;
  const WebViewScreen({super.key, required this.subdomain});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen>
    with SingleTickerProviderStateMixin {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  double _pullDistance = 0.0;
  bool _isRefreshing = false;
  bool _canPull = false;
  static const double _refreshTrigger = 80.0;
  static const double _maxPull = 120.0;

  late AnimationController _spinController;

  String get _baseUrl => 'http://${widget.subdomain}.primeerp.top';

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _initWebView();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(false)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 15; SM-S906B) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage message) {
          _handleWebMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted)
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
          },
          onPageFinished: (url) async {
            if (mounted) setState(() => _isLoading = false);

            await _disableWebViewZoom();

            await _controller.runJavaScript('''
              window.addEventListener('scroll', function() {
                window.flutter_scrollY = window.scrollY;
              });
            ''');

            _injectCallBridge();
            _registerDeviceForPush();
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage =
                    'Error ${error.errorCode}: ${error.description}';
              });
            }
          },
          onNavigationRequest: (request) async {
            final url = request.url;

            if (url.contains('r=user/user/logout') || url.contains('r=user/user/logout&ajax=true&_lang=en')) {
              _unregisterThisDevice();
            }

            if (url.startsWith(
                '${widget.subdomain}.primeerp.top')) {
              final httpUrl = url.replaceFirst('https://', 'http://');
              _controller.loadRequest(Uri.parse(httpUrl));
              return NavigationDecision.prevent;
            }

            if (url.startsWith('tel:') ||
                url.startsWith('mailto:') ||
                url.startsWith('whatsapp:') ||
                url.startsWith('intent:')) {
              if (url.startsWith('tel:')) {
                final phone = url.replaceFirst('tel:', '').trim();
                if (mounted) _openInAppDialer(phone);
                return NavigationDecision.prevent;
              }
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              return NavigationDecision.prevent;
            }

            if (url.contains('wa.me') ||
                url.contains('api.whatsapp.com')) {
              final uri = Uri.parse(url);
              final phone = uri.pathSegments.isNotEmpty
                  ? uri.pathSegments.last
                  : '';
              final whatsappUri =
                  Uri.parse('whatsapp://send?phone=$phone');
              if (await canLaunchUrl(whatsappUri)) {
                await launchUrl(whatsappUri,
                    mode: LaunchMode.externalApplication);
              } else {
                await launchUrl(uri,
                    mode: LaunchMode.externalApplication);
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_baseUrl));
  }

  Future<void> _disableWebViewZoom() async {
    try {
      await _controller.runJavaScript(r'''
        (function () {
          const viewportContent =
              'width=device-width, initial-scale=1.0, minimum-scale=1.0, ' +
              'maximum-scale=1.0, user-scalable=no, viewport-fit=cover';

          function lockViewport() {
            let viewport = document.querySelector('meta[name="viewport"]');

            if (!viewport) {
              viewport = document.createElement('meta');
              viewport.name = 'viewport';
              document.head.appendChild(viewport);
            }

            if (viewport.getAttribute('content') !== viewportContent) {
              viewport.setAttribute('content', viewportContent);
            }
          }

          lockViewport();

          if (document.head && !window.__flutterZoomObserverInstalled) {
            window.__flutterZoomObserverInstalled = true;

            new MutationObserver(function () {
              lockViewport();
            }).observe(document.head, {
              childList: true,
              subtree: true,
              attributes: true,
              attributeFilter: ['content']
            });
          }

          if (!window.__flutterZoomEventsInstalled) {
            window.__flutterZoomEventsInstalled = true;

            document.addEventListener('touchmove', function (event) {
              if (event.touches && event.touches.length > 1) {
                event.preventDefault();
              }
            }, { passive: false });

            let lastTouchEnd = 0;
            document.addEventListener('touchend', function (event) {
              const now = Date.now();

              if (now - lastTouchEnd <= 300) {
                event.preventDefault();
              }

              lastTouchEnd = now;
            }, { passive: false });

            ['gesturestart', 'gesturechange', 'gestureend'].forEach(
              function (eventName) {
                document.addEventListener(eventName, function (event) {
                  event.preventDefault();
                }, { passive: false });
              }
            );
          }

          if (!document.getElementById('flutter-disable-zoom-style')) {
            const style = document.createElement('style');
            style.id = 'flutter-disable-zoom-style';
            style.textContent = `
              html, body {
                touch-action: pan-x pan-y !important;
              }

              input, textarea, select {
                font-size: 16px !important;
              }
            `;
            document.head.appendChild(style);
          }
        })();
      ''');
    } catch (e) {
      debugPrint('Disable zoom injection error: $e');
    }
  }

  void _injectCallBridge() {
    _controller.runJavaScript(r'''
      (function() {

        function sendToDialer(phone) {
          var clean = phone.replace(/[^\d+]/g, '');
          if (clean.length < 5) return;
          FlutterBridge.postMessage(JSON.stringify({ action: 'openDialer', phone: clean }));
        }

        function sendToWhatsApp(url) {
          FlutterBridge.postMessage(JSON.stringify({ action: 'openWhatsApp', url: url }));
        }

        var _originalOpen = window.open;
        window.open = function(url, target, features) {
          if (url && typeof url === 'string') {
            if (url.startsWith('tel:')) {
              sendToDialer(url.replace('tel:', ''));
              return null;
            }
            if (url.indexOf('wa.me') !== -1 || url.indexOf('whatsapp') !== -1) {
              sendToWhatsApp(url);
              return null;
            }
            if (target === '_blank') {
              FlutterBridge.postMessage(JSON.stringify({ action: 'openExternal', url: url }));
              return null;
            }
          }
          return _originalOpen.apply(window, arguments);
        };

        document.addEventListener('click', function(e) {
          var target = e.target.closest('a[href^="tel:"]');
          if (target) {
            e.preventDefault();
            sendToDialer(target.href.replace('tel:', ''));
          }
        }, true);

        console.log('FlutterBridge injected');
      })();
    ''');
  }

  Future<void> _registerDeviceForPush() async {
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }

      final token = await messaging.getToken();
      if (token == null) return;

      final platform = Platform.isIOS ? 'ios' : 'android';

      await _controller.runJavaScript('''
        fetch('/admin/indexyii.php?r=site/RegisterDevice', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          credentials: 'same-origin',
          body: 'token=$token&platform=$platform'
        }).then(function(r) { return r.text(); })
          .then(function(t) { console.log('RegisterDevice response: ' + t); })
          .catch(function(e) { console.log('RegisterDevice error: ' + e); });
      ''');
    } catch (e) {
      debugPrint('Push registration error: $e');
    }
  }

  Future<void> _unregisterThisDevice() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await http.post(
        Uri.parse('$_baseUrl/admin/indexyii.php?r=site/UnregisterDevice'),
        body: {'token': token},
      );
    } catch (e) {
      debugPrint('Unregister error: $e');
    }
  }

  void _handleWebMessage(String message) {
    try {
      final actionMatch =
          RegExp(r'"action"\s*:\s*"([^"]+)"').firstMatch(message);
      final action = actionMatch?.group(1) ?? '';

      switch (action) {
        case 'openDialer':
          final phone = _extractValue(message, 'phone');
          if (phone.isNotEmpty) _openInAppDialer(phone);
          break;
        case 'openWhatsApp':
          final url = _extractValue(message, 'url');
          if (url.isNotEmpty) _launchExternal(url);
          break;
        case 'openExternal':
          final url = _extractValue(message, 'url');
          if (url.isNotEmpty) _launchExternal(url);
          break;
      }
    } catch (e) {
      debugPrint('WebMessage error: $e');
    }
  }

  String _extractValue(String json, String key) {
    final regex = RegExp('"$key"\\s*:\\s*"([^"]+)"');
    return regex.firstMatch(json)?.group(1) ?? '';
  }

  Future<void> _launchExternal(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Launch error: $e');
    }
  }

  void _openInAppDialer(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.length < 5) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InAppDialer(
        initialNumber: clean,
        onCall: (number) {
          _makeCall(number);
        },
        onHangup: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _makeCall(String phone) async {
    try {
      await _callChannel.invokeMethod('makeCall', {'phone': phone});
    } on PlatformException catch (e) {
      debugPrint('Call error: ${e.message}');
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _onRefresh() async {
    await _controller.reload();
    await Future.delayed(const Duration(milliseconds: 800));
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }
    return false;
  }

  Future<bool> _isAtTop() async {
    try {
      final result = await _controller.runJavaScriptReturningResult(
        'window.scrollY || document.documentElement.scrollTop || 0',
      );
      return (double.tryParse(result.toString()) ?? 0) <= 0;
    } catch (_) {
      return true;
    }
  }

  double _pointerStartY = 0;

  void _onPointerDown(PointerDownEvent e) {
    if (_isRefreshing) return;
    _pointerStartY = e.position.dy;
    _isAtTop().then((atTop) {
      if (mounted) setState(() => _canPull = atTop);
    });
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_isRefreshing || !_canPull) return;
    final dy = e.position.dy - _pointerStartY;
    if (dy > 0) {
      setState(() {
        _pullDistance = (dy * 0.45).clamp(0.0, _maxPull);
      });
    } else {
      if (_pullDistance > 0)
        setState(() {
          _pullDistance = 0;
          _canPull = false;
        });
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    if (_isRefreshing || !_canPull) return;
    if (_pullDistance >= _refreshTrigger) {
      _triggerRefresh();
    } else {
      _resetPull();
    }
  }

  void _resetPull() {
    if (mounted) setState(() { _pullDistance = 0.0; _canPull = false; });
  }

  void _triggerRefresh() {
    setState(() {
      _isRefreshing = true;
      _pullDistance = _refreshTrigger * 0.75;
      _canPull = false;
    });
    _spinController.repeat();
    _onRefresh().then((_) {
      if (mounted) {
        _spinController.stop();
        _spinController.reset();
        setState(() {
          _isRefreshing = false;
          _pullDistance = 0.0;
        });
      }
    });
  }

  double get _indicatorTopOffset {
    if (_isRefreshing) return 14.0;
    final progress = (_pullDistance / _refreshTrigger).clamp(0.0, 1.0);
    return -30.0 + (progress * 44.0);
  }

  double get _indicatorOpacity {
    if (_isRefreshing) return 1.0;
    return (_pullDistance / (_refreshTrigger * 0.5)).clamp(0.0, 1.0);
  }

  double get _iconRotation {
    if (_isRefreshing) return _spinController.value * 2 * math.pi;
    return (_pullDistance / _refreshTrigger) * 2 * math.pi;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              Listener(
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                onPointerCancel: (_) => _resetPull(),
                behavior: HitTestBehavior.translucent,
                child: WebViewWidget(controller: _controller),
              ),

              AnimatedBuilder(
                animation: _spinController,
                builder: (context, child) {
                  return Positioned(
                    top: _indicatorTopOffset,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity: _indicatorOpacity,
                      child: Center(
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2)),
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4),
                            ],
                          ),
                          child: Center(
                            child: Transform.rotate(
                              angle: _iconRotation,
                              child: _isRefreshing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Color(0xFFF1AF00)))
                                  : Icon(Icons.refresh_rounded,
                                      size: 22,
                                      color: _pullDistance >= _refreshTrigger
                                          ? const Color(0xFFF1AF00)
                                          : Colors.grey.shade500),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              if (_isLoading)
                const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFF1AF00))),

              if (!_isLoading && _errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Page failed to load',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SelectableText(_errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _onRefresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1AF00),
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── IN-APP DIALER ────────────────────────────────────────────
class InAppDialer extends StatefulWidget {
  final String initialNumber;
  final void Function(String number) onCall;
  final VoidCallback onHangup;

  const InAppDialer({
    super.key,
    required this.initialNumber,
    required this.onCall,
    required this.onHangup,
  });

  @override
  State<InAppDialer> createState() => _InAppDialerState();
}

class _InAppDialerState extends State<InAppDialer> {
  late String _number;
  bool _isCallActive = false;
  bool _isMuted = false;
  int _seconds = 0;
  late final Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _number = widget.initialNumber;
    _stopwatch = Stopwatch();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  void _appendDigit(String digit) => setState(() => _number += digit);

  void _deleteDigit() {
    if (_number.isNotEmpty) {
      setState(() => _number = _number.substring(0, _number.length - 1));
    }
  }

  void _startCall() {
    if (_number.isEmpty) return;
    widget.onCall(_number);
    widget.onHangup();
  }

  Future<void> _toggleMute() async {
    final newMute = !_isMuted;
    try {
      await _callChannel.invokeMethod('muteCall', {'mute': newMute});
    } catch (_) {}
    setState(() => _isMuted = newMute);
  }

  String get _timeStr {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _isCallActive ? 'Call in Progress' : 'Call Lead',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222222)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    _number.isEmpty ? 'Enter number' : _number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: _number.isEmpty
                          ? Colors.grey.shade400
                          : const Color(0xFF111111),
                    ),
                  ),
                ),
                if (_number.isNotEmpty && !_isCallActive)
                  GestureDetector(
                    onTap: _deleteDigit,
                    child: const Icon(Icons.backspace_outlined,
                        color: Colors.grey, size: 22),
                  ),
              ],
            ),
          ),

          if (_isCallActive)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _timeStr,
                style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF22C55E),
                    fontWeight: FontWeight.w600),
              ),
            ),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),

          if (!_isCallActive) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  _buildDialRow(['1', '2', '3']),
                  _buildDialRow(['4', '5', '6']),
                  _buildDialRow(['7', '8', '9']),
                  _buildDialRow(['*', '0', '#']),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _number.isNotEmpty ? _startCall : null,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _number.isNotEmpty
                      ? const Color(0xFF22C55E)
                      : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  boxShadow: _number.isNotEmpty
                      ? [
                          BoxShadow(
                              color: const Color(0xFF22C55E)
                                  .withValues(alpha: 0.4),
                              blurRadius: 16,
                              spreadRadius: 2)
                        ]
                      : [],
                ),
                child:
                    const Icon(Icons.call_rounded, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Tap to call',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _InCallButton(
                    icon: _isMuted
                        ? Icons.mic_off_rounded
                        : Icons.mic_rounded,
                    label: _isMuted ? 'Unmute' : 'Mute',
                    color: _isMuted
                        ? Colors.red.shade400
                        : Colors.grey.shade700,
                    bgColor:
                        _isMuted ? Colors.red.shade50 : Colors.grey.shade100,
                    onTap: _toggleMute,
                  ),
                  _InCallButton(
                    icon: Icons.call_end_rounded,
                    label: 'End',
                    color: Colors.white,
                    bgColor: Colors.red,
                    onTap: widget.onHangup,
                    size: 64,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDialRow(List<String> digits) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: digits
            .map((d) => _DialButton(digit: d, onTap: () => _appendDigit(d)))
            .toList(),
      ),
    );
  }
}

class _InCallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  final double size;

  const _InCallButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: size * 0.46),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _DialButton extends StatelessWidget {
  final String digit;
  final VoidCallback onTap;

  const _DialButton({required this.digit, required this.onTap});

  static const Map<String, String> _subLabels = {
    '2': 'ABC', '3': 'DEF', '4': 'GHI', '5': 'JKL',
    '6': 'MNO', '7': 'PQRS', '8': 'TUV', '9': 'WXYZ',
    '0': '+',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(digit,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111111))),
            if (_subLabels.containsKey(digit))
              Text(_subLabels[digit]!,
                  style: const TextStyle(
                      fontSize: 9, color: Colors.grey, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}