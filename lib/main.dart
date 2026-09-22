import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const NanFangJianApp());
}

class NanFangJianApp extends StatelessWidget {
  const NanFangJianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '南方见',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0C08),
        fontFamily: 'sans-serif',
      ),
      home: const CompassScreen(),
    );
  }
}

class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen>
    with TickerProviderStateMixin {
  static const _floatingChannel =
      MethodChannel('com.example.custom_compass/floating');

  bool _isFloatingEnabled = false;

  // 正南至纯能量光效
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // 奶龙悬浮浮动动效
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _checkFloatingStatus();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.90, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutQuad),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    await Permission.locationWhenInUse.request();
  }

  Future<void> _checkFloatingStatus() async {
    try {
      final bool active =
          await _floatingChannel.invokeMethod('isFloating') ?? false;
      setState(() => _isFloatingEnabled = active);
    } catch (_) {}
  }

  Future<void> _toggleFloatingWindow() async {
    try {
      if (_isFloatingEnabled) {
        await _floatingChannel.invokeMethod('hideFloatingWindow');
        setState(() => _isFloatingEnabled = false);
      } else {
        final bool hasPermission =
            await _floatingChannel.invokeMethod('checkOverlayPermission') ??
                false;
        if (!hasPermission) {
          await _floatingChannel.invokeMethod('requestOverlayPermission');
          return;
        }
        await _floatingChannel.invokeMethod('showFloatingWindow');
        setState(() => _isFloatingEnabled = true);
      }
    } catch (e) {
      debugPrint('Floating error: $e');
    }
  }

  String _getConstructivistDirection(double heading) {
    if (heading >= 348.75 || heading < 11.25) return 'NORTH // 极北';
    if (heading >= 11.25 && heading < 78.75) return 'NORTH-EAST // 拂晓';
    if (heading >= 78.75 && heading < 101.25) return 'EAST // 破晓';
    if (heading >= 101.25 && heading < 168.75) return 'SOUTH-EAST // 骤暖';
    if (heading >= 168.75 && heading < 191.25) return 'SOUTH // 南方见 · 锁定';
    if (heading >= 191.25 && heading < 258.75) return 'SOUTH-WEST // 暮野';
    if (heading >= 258.75 && heading < 281.25) return 'WEST // 炽霞';
    if (heading >= 281.25 && heading < 348.75) return 'NORTH-WEST // 裂空';
    return 'SOUTH // 南方见 · 锁定';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 底层：至上主义/构成主义先锋艺术海报背景
          Image.asset(
            'assets/images/abstract_bg.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),

          // 2. 几何光影遮罩（使中心指南针与文字清晰立现，同时透出极强的抽象构图）
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, 0),
                radius: 1.0,
                colors: [
                  const Color(0xFF0C0906).withOpacity(0.55),
                  const Color(0xFF090604).withOpacity(0.85),
                  const Color(0xFF050302).withOpacity(0.96),
                ],
              ),
            ),
          ),

          // 3. 动态传感器响应层
          SafeArea(
            child: StreamBuilder<CompassEvent>(
              stream: FlutterCompass.events,
              builder: (context, snapshot) {
                double heading = snapshot.data?.heading ?? 0;
                if (heading < 0) {
                  heading = (heading + 360) % 360;
                }

                // 容差判定：±6° 内正中南方
                final bool isSouth = (heading - 180).abs() <= 6;

                return Column(
                  children: [
                    // 构成主义先锋 Header
                    _buildConstructivistHeader(heading, isSouth),

                    // 先锋罗盘核心
                    Expanded(
                      child: Center(
                        child: _buildAvantGardeDial(heading, isSouth),
                      ),
                    ),

                    // 底部控制台与奶龙抽象呼应
                    _buildBottomConsole(isSouth),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConstructivistHeader(double heading, bool isSouth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 左侧：抽象几何构图标题
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 构成主义红色标志色块
                  Container(
                    width: 14,
                    height: 28,
                    color: const Color(0xFFD62828),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '南方见',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      color: Color(0xFFF7F4EB), // 复古羊皮纸白
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 先锋几何标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSouth
                          ? const Color(0xFFF77F00)
                          : const Color(0xFFD62828).withOpacity(0.3),
                      border: Border.all(
                        color: isSouth
                            ? const Color(0xFFFCBF49)
                            : const Color(0xFFD62828),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      isSouth ? 'SEE SOUTH' : 'SEEKING',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _getConstructivistDirection(heading),
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                  color: isSouth
                      ? const Color(0xFFFCBF49)
                      : const Color(0xFFF7F4EB).withOpacity(0.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // 右侧：大号工业字体角度读数
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                heading.round().toString().padLeft(3, '0'),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isSouth
                      ? const Color(0xFFFCBF49)
                      : const Color(0xFFF7F4EB),
                  letterSpacing: -1,
                  shadows: isSouth
                      ? [
                          const Shadow(
                            color: Color(0xFFD62828),
                            blurRadius: 20,
                          ),
                          const Shadow(
                            color: Color(0xFFFCBF49),
                            blurRadius: 30,
                          )
                        ]
                      : [],
                ),
              ),
              const Text(
                '°',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD62828),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvantGardeDial(double heading, bool isSouth) {
    // 关键方位换算：原图正上方是【南】！
    // 正南角度相对于当前手机车头的偏转角：(180 - heading)
    final double pointerRad = (180 - heading) * (math.pi / 180);
    final double dialRad = -heading * (math.pi / 180);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = math.min(constraints.maxWidth * 0.90, 370);

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. 构成主义对撞光效（正南对准时爆发纯正先锋红黄张力）
              if (isSouth)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: size * 0.96,
                        height: size * 0.96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFD62828).withOpacity(0.8),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD62828).withOpacity(0.45),
                              blurRadius: 50,
                              spreadRadius: 10,
                            ),
                            BoxShadow(
                              color: const Color(0xFFFCBF49).withOpacity(0.35),
                              blurRadius: 70,
                              spreadRadius: 15,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // 2. 至上主义几何刻度盘（带有先锋斜角与粗黑红黄色块）
              Transform.rotate(
                angle: dialRad,
                child: CustomPaint(
                  size: Size(size, size),
                  painter: ConstructivistDialPainter(isSouth: isSouth),
                ),
              ),

              // 3. 人物指针（主角：手执正南方，精准咬合）
              Transform.rotate(
                angle: pointerRad,
                child: SizedBox(
                  width: size * 0.84,
                  height: size * 0.84,
                  child: Image.asset(
                    'assets/images/pointer_centered.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // 4. 真实奶龙实体浮空立像（双手抱胸，目光穿透屏幕随方位守护）
              Transform.rotate(
                angle: pointerRad,
                child: Transform.translate(
                  offset: Offset(size * 0.32, -size * 0.28),
                  child: AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSouth
                                  ? const Color(0xFFFCBF49)
                                  : const Color(0xFFD62828),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSouth
                                    ? const Color(0xFFFCBF49).withOpacity(0.6)
                                    : Colors.black54,
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/nailong_cutout.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 5. 构成主义极简红黄几何轴心
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSouth
                      ? const Color(0xFFFCBF49)
                      : const Color(0xFFD62828),
                  border: Border.all(color: const Color(0xFFF7F4EB), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: isSouth
                          ? const Color(0xFFFCBF49).withOpacity(0.9)
                          : const Color(0xFFD62828).withOpacity(0.8),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomConsole(bool isSouth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 构成主义标语横幅
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSouth
                  ? const Color(0xFFD62828).withOpacity(0.85)
                  : Colors.black.withOpacity(0.65),
              border: Border.all(
                color: isSouth
                    ? const Color(0xFFFCBF49)
                    : const Color(0xFFD62828).withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSouth ? '✦ 坐标对齐 · 南方已至 ✦' : '“风过千山，我们在南方见”',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: isSouth
                        ? const Color(0xFFF7F4EB)
                        : const Color(0xFFF7F4EB).withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 悬浮窗控制胶囊
          GestureDetector(
            onTap: _toggleFloatingWindow,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _isFloatingEnabled
                    ? const Color(0xFFFCBF49).withOpacity(0.95)
                    : const Color(0xFFD62828).withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: _isFloatingEnabled
                        ? const Color(0xFFFCBF49).withOpacity(0.4)
                        : const Color(0xFFD62828).withOpacity(0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isFloatingEnabled
                        ? Icons.check_circle_rounded
                        : Icons.layers_rounded,
                    size: 16,
                    color: _isFloatingEnabled
                        ? const Color(0xFF0F0C08)
                        : Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isFloatingEnabled
                        ? '桌面悬浮人物：全天候指向南方 (已开启)'
                        : '启动桌面悬浮指针 (任意界面永远指正南)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: _isFloatingEnabled
                          ? const Color(0xFF0F0C08)
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'SUPREMATISM // NANFANGJIAN ART EDITION 2026',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 3,
              color: Color(0xFFF7F4EB),
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// 先锋构成主义刻度盘
class ConstructivistDialPainter extends CustomPainter {
  final bool isSouth;
  ConstructivistDialPainter({required this.isSouth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 半透明极简羊皮纸黑底盘
    final bgPaint = Paint()
      ..color = const Color(0xFF0D0B08).withOpacity(0.82)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 4, bgPaint);

    // 外框构成主义红黄双线
    final ringPaint = Paint()
      ..color = isSouth
          ? const Color(0xFFFCBF49)
          : const Color(0xFFD62828).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius - 6, ringPaint);

    final innerRingPaint = Paint()
      ..color = const Color(0xFFF7F4EB).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius * 0.70, innerRingPaint);

    // 刻度线
    final normalTick = Paint()
      ..color = const Color(0xFFF7F4EB).withOpacity(0.25)
      ..strokeWidth = 1.2;
    final majorTick = Paint()
      ..color = const Color(0xFFF7F4EB).withOpacity(0.85)
      ..strokeWidth = 2.0;
    final southTick = Paint()
      ..color = const Color(0xFFFCBF49)
      ..strokeWidth = 4.0;

    for (int deg = 0; deg < 360; deg += 3) {
      final rad = (deg - 90) * math.pi / 180;
      final bool is30 = deg % 30 == 0;
      final bool is90 = deg % 90 == 0;
      final bool isSouthDeg = deg == 180;

      final double outerR = radius - 10;
      double innerR = radius - 16;
      if (is90) {
        innerR = radius - 28;
      } else if (is30) {
        innerR = radius - 22;
      }

      final p1 = Offset(center.dx + outerR * math.cos(rad),
          center.dy + outerR * math.sin(rad));
      final p2 = Offset(center.dx + innerR * math.cos(rad),
          center.dy + innerR * math.sin(rad));

      if (isSouthDeg) {
        canvas.drawLine(p1, p2, southTick);
      } else if (is30) {
        canvas.drawLine(p1, p2, majorTick);
      } else {
        canvas.drawLine(p1, p2, normalTick);
      }
    }

    // 构成主义粗黑体四方位字
    _drawDirection(canvas, center, radius - 46, 180, '南', const Color(0xFFFCBF49), 24, true);
    _drawDirection(canvas, center, radius - 44, 0, '北', const Color(0xFFF7F4EB), 16, false);
    _drawDirection(canvas, center, radius - 44, 90, '东', const Color(0xFFF7F4EB).withOpacity(0.5), 15, false);
    _drawDirection(canvas, center, radius - 44, 270, '西', const Color(0xFFF7F4EB).withOpacity(0.5), 15, false);
  }

  void _drawDirection(Canvas canvas, Offset center, double distance, double deg,
      String text, Color color, double fontSize, bool isHighlight) {
    final rad = (deg - 90) * math.pi / 180;
    final pos = Offset(center.dx + distance * math.cos(rad),
        center.dy + distance * math.sin(rad));

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        fontFamily: 'monospace',
        letterSpacing: 2,
        shadows: isHighlight
            ? [
                const Shadow(color: Color(0xFFD62828), blurRadius: 18),
                const Shadow(color: Color(0xFFFCBF49), blurRadius: 25),
              ]
            : null,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant ConstructivistDialPainter oldDelegate) =>
      oldDelegate.isSouth != isSouth;
}
