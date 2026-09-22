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
        scaffoldBackgroundColor: const Color(0xFF0A0E17),
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
    with SingleTickerProviderStateMixin {
  double _manualHeading = 180.0;
  bool _useManual = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _requestPermission();

    // 正南呼吸光晕动效
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    await Permission.locationWhenInUse.request();
  }

  String _getDirectionDetail(double heading) {
    if (heading >= 348.75 || heading < 11.25) return '正北 · 北境之风';
    if (heading >= 11.25 && heading < 78.75) return '东北 · 拂晓晨曦';
    if (heading >= 78.75 && heading < 101.25) return '正东 · 紫气东来';
    if (heading >= 101.25 && heading < 168.75) return '东南 · 暖意将至';
    if (heading >= 168.75 && heading < 191.25) return '正南 · 与你相见';
    if (heading >= 191.25 && heading < 258.75) return '西南 · 暮色长空';
    if (heading >= 258.75 && heading < 281.25) return '正西 · 霞光映照';
    if (heading >= 281.25 && heading < 348.75) return '西北 · 寒芒如雪';
    return '正南 · 与你相见';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.3,
            colors: [
              Color(0xFF161F30),
              Color(0xFF0B0F19),
              Color(0xFF05070B),
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<CompassEvent>(
            stream: FlutterCompass.events,
            builder: (context, snapshot) {
              double? sensorHeading = snapshot.data?.heading;
              if (sensorHeading != null && sensorHeading < 0) {
                sensorHeading = (sensorHeading + 360) % 360;
              }

              final double currentHeading =
                  _useManual || sensorHeading == null
                      ? _manualHeading
                      : sensorHeading;

              // 是否对准南方（允许 ±6 度的浪漫对准容差）
              final bool isSouth = (currentHeading - 180).abs() <= 6;

              return Column(
                children: [
                  // 顶部品牌意境区
                  _buildBrandHeader(currentHeading, isSouth),

                  // 罗盘与人物指针核心区
                  Expanded(
                    child: Center(
                      child: _buildCompassDial(currentHeading, isSouth),
                    ),
                  ),

                  // 底部温暖诗意文案与控制台
                  _buildFooter(isSouth, sensorHeading != null),
                  const SizedBox(height: 18),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader(double heading, bool isSouth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '南方见',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSouth
                              ? const Color(0xFFFF5252).withOpacity(0.2)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSouth
                                ? const Color(0xFFFF5252)
                                : Colors.white24,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          isSouth ? '相见' : '寻南',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSouth
                                ? const Color(0xFFFF5252)
                                : Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getDirectionDetail(heading),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSouth ? const Color(0xFFFF8A80) : Colors.white54,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              // 角度度数显示
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    heading.round().toString(),
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w200,
                      color: isSouth ? const Color(0xFFFF5252) : Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    '°',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      color: isSouth ? const Color(0xFFFF5252) : Colors.white54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isSouth
                      ? const Color(0xFFFF5252).withOpacity(0.6)
                      : Colors.white12,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompassDial(double heading, bool isSouth) {
    // 核心算法：
    // 图片原图正上方（头顶/举手）代表正南 (180°)。
    // 手机顶部朝向 heading，地球正南在手机坐标系中顺时针偏移 (180° - heading)。
    // 图片按此角度旋转，头顶直指正南方！
    final double pointerRad = (180 - heading) * (math.pi / 180);
    final double dialRad = -heading * (math.pi / 180);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = math.min(constraints.maxWidth * 0.90, 380);

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 正南呼应外发光光晕
              if (isSouth)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: size * 0.92,
                        height: size * 0.92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF3366).withOpacity(0.35),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // 顶部基准指针与光标
              Positioned(
                top: 0,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isSouth
                              ? [const Color(0xFFFF416C), const Color(0xFFFF4B2B)]
                              : [const Color(0xFF3A7BD5), const Color(0xFF3A6073)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (isSouth
                                    ? const Color(0xFFFF416C)
                                    : const Color(0xFF3A7BD5))
                                .withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        isSouth ? '向南而行' : '手机朝向',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: isSouth
                          ? const Color(0xFFFF4B2B)
                          : const Color(0xFF3A7BD5),
                      size: 20,
                    ),
                  ],
                ),
              ),

              // 1. 拟物暗色渐变刻度盘
              Transform.rotate(
                angle: dialRad,
                child: CustomPaint(
                  size: Size(size, size),
                  painter: NanFangDialPainter(isSouth: isSouth),
                ),
              ),

              // 2. 人物指南针主角（正上方指正南）
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

              // 3. 极简中心轴
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isSouth ? const Color(0xFFFF5252) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: isSouth
                          ? const Color(0xFFFF5252).withOpacity(0.8)
                          : Colors.white30,
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

  Widget _buildFooter(bool isSouth, bool sensorConnected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          // 意境金句
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              isSouth
                  ? '“风过千山，我们在南方见。”'
                  : '“不论身在何方，他始终面朝南方守护你。”',
              key: ValueKey<bool>(isSouth),
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.5,
                color: isSouth ? const Color(0xFFFF8A80) : Colors.white60,
                shadows: isSouth
                    ? [const Shadow(color: Color(0xFFFF5252), blurRadius: 10)]
                    : [],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),

          // 调试模拟滑块
          if (_useManual)
            Row(
              children: [
                const Text('模拟角度',
                    style: TextStyle(fontSize: 11, color: Colors.white38)),
                Expanded(
                  child: Slider(
                    value: _manualHeading,
                    min: 0,
                    max: 359,
                    activeColor: const Color(0xFFFF5252),
                    inactiveColor: Colors.white12,
                    onChanged: (v) => setState(() => _manualHeading = v),
                  ),
                ),
                Text('${_manualHeading.round()}°',
                    style: const TextStyle(fontSize: 11, color: Colors.white54)),
              ],
            ),

          // 模式切换小按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => _useManual = !_useManual);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _useManual
                            ? Icons.touch_app_rounded
                            : Icons.explore_rounded,
                        size: 14,
                        color: _useManual
                            ? const Color(0xFFFF5252)
                            : const Color(0xFF64B5F6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _useManual ? '手动模拟模式 (点击切换真实)' : '真实传感器驱动 (点击模拟)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 专属精致罗盘盘面绘制
class NanFangDialPainter extends CustomPainter {
  final bool isSouth;
  NanFangDialPainter({required this.isSouth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 渐变底盘
    final rect = Rect.fromCircle(center: center, radius: radius);
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF161E2E).withOpacity(0.9),
          const Color(0xFF0F1420).withOpacity(0.95),
          const Color(0xFF080C14).withOpacity(0.98),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 4, bgPaint);

    // 外金属细环
    final ringPaint = Paint()
      ..color = isSouth
          ? const Color(0xFFFF5252).withOpacity(0.4)
          : Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius - 5, ringPaint);

    // 刻度线绘制
    final majorPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 1.8;
    final minorPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.0;
    final southPaint = Paint()
      ..color = const Color(0xFFFF5252)
      ..strokeWidth = 2.8;

    for (int deg = 0; deg < 360; deg += 2) {
      final rad = (deg - 90) * math.pi / 180;
      final bool is30 = deg % 30 == 0;
      final bool is10 = deg % 10 == 0;
      final bool isSouthTick = deg == 180;

      final double outerR = radius - 10;
      double innerR = radius - 16;
      if (is30) {
        innerR = radius - 24;
      } else if (is10) {
        innerR = radius - 20;
      }

      final p1 = Offset(center.dx + outerR * math.cos(rad),
          center.dy + outerR * math.sin(rad));
      final p2 = Offset(center.dx + innerR * math.cos(rad),
          center.dy + innerR * math.sin(rad));

      Paint paintToUse;
      if (isSouthTick) {
        paintToUse = southPaint;
      } else if (is30) {
        paintToUse = majorPaint;
      } else if (is10) {
        paintToUse = majorPaint..color = Colors.white38;
      } else {
        paintToUse = minorPaint;
      }

      canvas.drawLine(p1, p2, paintToUse);
    }

    // 四大方位大字，突出【南】（南方见主题核心）
    _drawDirection(canvas, center, radius - 44, 180, '南', const Color(0xFFFF5252), true);
    _drawDirection(canvas, center, radius - 42, 0, '北', const Color(0xFF64B5F6), false);
    _drawDirection(canvas, center, radius - 42, 90, '东', Colors.white54, false);
    _drawDirection(canvas, center, radius - 42, 270, '西', Colors.white54, false);
  }

  void _drawDirection(Canvas canvas, Offset center, double distance, double deg,
      String text, Color color, bool isFeatured) {
    final rad = (deg - 90) * math.pi / 180;
    final pos = Offset(center.dx + distance * math.cos(rad),
        center.dy + distance * math.sin(rad));

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: isFeatured ? 20 : 15,
        fontWeight: isFeatured ? FontWeight.w900 : FontWeight.w500,
        letterSpacing: 2,
        shadows: isFeatured
            ? [const Shadow(color: Color(0xFFFF5252), blurRadius: 14)]
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
  bool shouldRepaint(covariant NanFangDialPainter oldDelegate) =>
      oldDelegate.isSouth != isSouth;
}
