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
        scaffoldBackgroundColor: const Color(0xFF070B14),
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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _checkFloatingStatus();

    // 正南对准时的呼吸光效
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 奶龙悬浮灵动微动效
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -4.0, end: 4.0).animate(
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
      debugPrint('Floating toggle error: $e');
    }
  }

  String _getDirectionPoem(double heading) {
    if (heading >= 348.75 || heading < 11.25) return '正北 · 北境星野';
    if (heading >= 11.25 && heading < 78.75) return '东北 · 晨曦微澜';
    if (heading >= 78.75 && heading < 101.25) return '正东 · 东方既白';
    if (heading >= 101.25 && heading < 168.75) return '东南 · 暖风过境';
    if (heading >= 168.75 && heading < 191.25) return '正南 · 与你相见';
    if (heading >= 191.25 && heading < 258.75) return '西南 · 暮云沉醉';
    if (heading >= 258.75 && heading < 281.25) return '正西 · 晚霞漫天';
    if (heading >= 281.25 && heading < 348.75) return '西北 · 旷野长空';
    return '正南 · 与你相见';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.4,
            colors: [
              Color(0xFF141E33),
              Color(0xFF0A0F1D),
              Color(0xFF04060A),
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<CompassEvent>(
            stream: FlutterCompass.events,
            builder: (context, snapshot) {
              double heading = snapshot.data?.heading ?? 0;
              if (heading < 0) {
                heading = (heading + 360) % 360;
              }

              // 对准正南容差（±6° 触发金色奶龙与正南高亮）
              final bool isSouth = (heading - 180).abs() <= 6;

              return Column(
                children: [
                  // 顶部抽象美学 Header
                  _buildHeader(heading, isSouth),

                  // 罗盘与人物指针核心区（已加入奶龙抽象守护与光晕）
                  Expanded(
                    child: Center(
                      child: _buildCompassCore(heading, isSouth),
                    ),
                  ),

                  // 底部极简艺术文案
                  _buildBottomPoem(isSouth),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double heading, bool isSouth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '南方见',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 奶龙灵动情绪徽章
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSouth
                          ? const Color(0xFFFFD166).withOpacity(0.2)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSouth
                            ? const Color(0xFFFFD166)
                            : Colors.white12,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isSouth ? '🐲 见南' : '💤 寻南',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSouth
                                ? const Color(0xFFFFD166)
                                : Colors.white60,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _getDirectionPoem(heading),
                style: TextStyle(
                  fontSize: 12,
                  color: isSouth
                      ? const Color(0xFFFFD166)
                      : Colors.white.withOpacity(0.45),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),

          // 角度仪表
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                heading.round().toString().padLeft(3, '0'),
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w200,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isSouth ? const Color(0xFFFFD166) : Colors.white,
                  shadows: isSouth
                      ? [
                          const Shadow(
                            color: Color(0xFFFFD166),
                            blurRadius: 18,
                          )
                        ]
                      : [],
                ),
              ),
              Text(
                '°',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  color: isSouth ? const Color(0xFFFFD166) : Colors.white38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompassCore(double heading, bool isSouth) {
    // 核心校准：图片正上方（头顶举手方向）是【南】！
    // 正南偏移角度为 (180 - heading)
    final double pointerRad = (180 - heading) * (math.pi / 180);
    final double dialRad = -heading * (math.pi / 180);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = math.min(constraints.maxWidth * 0.92, 390);

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. 正南呼应：奶龙金色灵力呼吸光晕
              if (isSouth)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: size * 0.94,
                        height: size * 0.94,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD166).withOpacity(0.35),
                              blurRadius: 50,
                              spreadRadius: 10,
                            ),
                            BoxShadow(
                              color: const Color(0xFFFF5252).withOpacity(0.25),
                              blurRadius: 70,
                              spreadRadius: 15,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // 2. 抽象星轨刻度盘
              Transform.rotate(
                angle: dialRad,
                child: CustomPaint(
                  size: Size(size, size),
                  painter: AbstractStarDialPainter(isSouth: isSouth),
                ),
              ),

              // 3. 核心主角：人物指针（以自身正上为南精细锁定）
              Transform.rotate(
                angle: pointerRad,
                child: SizedBox(
                  width: size * 0.86,
                  height: size * 0.86,
                  child: Image.asset(
                    'assets/images/pointer_centered.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // 4. 奶龙 Q版抽象陪伴元素（正南时开心亮起，随指针常驻指南针上方守护）
              Transform.rotate(
                angle: pointerRad,
                child: Transform.translate(
                  offset: Offset(size * 0.28, -size * 0.32),
                  child: AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: _buildAbstractNailongBadge(isSouth),
                      );
                    },
                  ),
                ),
              ),

              // 5. 极简抽象轴心
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSouth
                      ? const Color(0xFFFFD166)
                      : const Color(0xFF64B5F6),
                  boxShadow: [
                    BoxShadow(
                      color: (isSouth
                              ? const Color(0xFFFFD166)
                              : const Color(0xFF64B5F6))
                          .withOpacity(0.8),
                      blurRadius: 12,
                      spreadRadius: 3,
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

  // 抽象奶龙灵宠徽章组件
  Widget _buildAbstractNailongBadge(bool isSouth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSouth
            ? const Color(0xFFFFD166).withOpacity(0.9)
            : const Color(0xFF1E283C).withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSouth ? Colors.white : const Color(0xFFFFD166).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isSouth
                ? const Color(0xFFFFD166).withOpacity(0.6)
                : Colors.black45,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isSouth ? '✨' : '🐲',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            isSouth ? '奶龙点赞·南方到啦!' : '奶龙带你看南',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSouth ? const Color(0xFF5A3A00) : const Color(0xFFFFD166),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPoem(bool isSouth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Text(
              isSouth
                  ? '“山川入海，我们在南方见。”'
                  : '“不论身在何方，他始终面朝南方守护你。”',
              key: ValueKey<bool>(isSouth),
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                letterSpacing: 2,
                color: isSouth ? const Color(0xFFFFD166) : Colors.white54,
                shadows: isSouth
                    ? [
                        const Shadow(
                          color: Color(0xFFFFD166),
                          blurRadius: 14,
                        )
                      ]
                    : [],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          // 悬浮窗快捷开启胶囊按钮
          GestureDetector(
            onTap: _toggleFloatingWindow,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isFloatingEnabled
                      ? [
                          const Color(0xFFFFD166).withOpacity(0.3),
                          const Color(0xFFFF5252).withOpacity(0.3)
                        ]
                      : [
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.04)
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isFloatingEnabled
                      ? const Color(0xFFFFD166)
                      : Colors.white24,
                  width: 1.2,
                ),
                boxShadow: _isFloatingEnabled
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFFD166).withOpacity(0.3),
                          blurRadius: 12,
                        )
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isFloatingEnabled
                        ? Icons.visibility_rounded
                        : Icons.picture_in_picture_alt_rounded,
                    size: 16,
                    color: _isFloatingEnabled
                        ? const Color(0xFFFFD166)
                        : Colors.white70,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isFloatingEnabled ? '桌面迷你悬浮人物：已开启' : '开启桌面悬浮人物 (永远指向南方)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isFloatingEnabled
                          ? const Color(0xFFFFD166)
                          : Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'NANFANGJIAN · DESIGN SYSTEM 2026',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 3,
              color: Colors.white.withOpacity(0.2),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// 抽象未来主义罗盘盘面绘制
class AbstractStarDialPainter extends CustomPainter {
  final bool isSouth;
  AbstractStarDialPainter({required this.isSouth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 渐变深空底盘
    final rect = Rect.fromCircle(center: center, radius: radius);
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF131C2D).withOpacity(0.7),
          const Color(0xFF090E18).withOpacity(0.92),
          const Color(0xFF030508).withOpacity(0.98),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 4, bgPaint);

    // 抽象星轨同心圆（内环与外环）
    final orbitPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius * 0.65, orbitPaint);
    canvas.drawCircle(center, radius * 0.40, orbitPaint..color = Colors.white.withOpacity(0.04));

    // 黄金奶龙南向流线光环
    final outerRing = Paint()
      ..color = isSouth
          ? const Color(0xFFFFD166).withOpacity(0.5)
          : Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 6, outerRing);

    // 刻度线绘制（抽象简约风格，突出南）
    final normalTick = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.0;
    final majorTick = Paint()
      ..color = Colors.white.withOpacity(0.65)
      ..strokeWidth = 1.6;
    final southTick = Paint()
      ..color = const Color(0xFFFFD166)
      ..strokeWidth = 3.0;

    for (int deg = 0; deg < 360; deg += 3) {
      final rad = (deg - 90) * math.pi / 180;
      final bool is30 = deg % 30 == 0;
      final bool is90 = deg % 90 == 0;
      final bool isSouthDeg = deg == 180;

      final double outerR = radius - 10;
      double innerR = radius - 16;
      if (is90) {
        innerR = radius - 26;
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

    // 方位抽象文字：重塑四方位（将“南”以奶龙金色特别强化）
    _drawDirectionText(canvas, center, radius - 46, 180, '南', const Color(0xFFFFD166), 22, true);
    _drawDirectionText(canvas, center, radius - 44, 0, '北', const Color(0xFF64B5F6), 14, false);
    _drawDirectionText(canvas, center, radius - 44, 90, '东', Colors.white38, 14, false);
    _drawDirectionText(canvas, center, radius - 44, 270, '西', Colors.white38, 14, false);
  }

  void _drawDirectionText(Canvas canvas, Offset center, double distance,
      double deg, String text, Color color, double fontSize, bool isGlow) {
    final rad = (deg - 90) * math.pi / 180;
    final pos = Offset(center.dx + distance * math.cos(rad),
        center.dy + distance * math.sin(rad));

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        shadows: isGlow
            ? [
                const Shadow(
                  color: Color(0xFFFFD166),
                  blurRadius: 16,
                ),
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
  bool shouldRepaint(covariant AbstractStarDialPainter oldDelegate) =>
      oldDelegate.isSouth != isSouth;
}
