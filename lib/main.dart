import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 保持竖屏
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const CustomCompassApp());
}

class CustomCompassApp extends StatelessWidget {
  const CustomCompassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '专属人物指南针',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
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

class _CompassScreenState extends State<CompassScreen> {
  bool _hasPermissions = false;
  double _manualHeading = 180.0; // 模拟测试值
  bool _useManual = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted) {
      setState(() => _hasPermissions = true);
    } else {
      final requested = await Permission.locationWhenInUse.request();
      setState(() => _hasPermissions = requested.isGranted);
    }
  }

  String _getDirectionName(double heading) {
    if (heading >= 348.75 || heading < 11.25) return '正北';
    if (heading >= 11.25 && heading < 78.75) return '东北';
    if (heading >= 78.75 && heading < 101.25) return '正东';
    if (heading >= 101.25 && heading < 168.75) return '东南';
    if (heading >= 168.75 && heading < 191.25) return '正南';
    if (heading >= 191.25 && heading < 258.75) return '西南';
    if (heading >= 258.75 && heading < 281.25) return '正西';
    if (heading >= 281.25 && heading < 348.75) return '西北';
    return '正南';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<CompassEvent>(
          stream: FlutterCompass.events,
          builder: (context, snapshot) {
            // 如果开启手动模式或传感器无数据，则使用手动值
            double? compassHeading = snapshot.data?.heading;
            if (compassHeading != null && compassHeading < 0) {
              compassHeading = (compassHeading + 360) % 360;
            }

            final double effectiveHeading = _useManual || compassHeading == null
                ? _manualHeading
                : compassHeading;

            return Column(
              children: [
                const SizedBox(height: 20),
                // 顶部读数区域
                _buildHeader(effectiveHeading),

                // 罗盘与指针核心区域
                Expanded(
                  child: Center(
                    child: _buildCompassView(effectiveHeading),
                  ),
                ),

                // 底部状态与操作控制
                _buildFooter(compassHeading != null),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(double heading) {
    final bool isSouth = (heading - 180).abs() <= 5;
    return Column(
      children: [
        Text(
          _getDirectionName(heading),
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: isSouth ? const Color(0xFFFF5252) : Colors.white,
            shadows: isSouth
                ? [const Shadow(color: Color(0xFFFF5252), blurRadius: 16)]
                : [],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              heading.round().toString(),
              style: const TextStyle(
                fontSize: 54,
                fontWeight: FontWeight.w200,
                color: Colors.white,
              ),
            ),
            const Text(
              '°',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w300,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '🎯 形象正上方始终指向正南 (S)',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildCompassView(double heading) {
    // 关键算法：
    // 用户指定：图片正上方向是【南】！
    // 真实罗盘中，正南是 180°。
    // 当手机朝向角度为 heading（以北为0°，顺时针）时：
    // 地理上的正南相对于手机顶部方向的角度为：(180 - heading) 度。
    // 因为图片素材本身正上方就是南，所以图片顺时针旋转 (180 - heading) 度后，
    // 图片的正上方就精确对准了地球的物理正南方！
    final double pointerAngleRad = (180 - heading) * (math.pi / 180);
    // 刻度盘旋转：通常罗盘刻度盘反向旋转保持北朝向真实北极
    final double dialAngleRad = -heading * (math.pi / 180);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = math.min(constraints.maxWidth * 0.88, 360);

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 顶部基准指示器（手机车头/朝向指示）
              Positioned(
                top: -6,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF416C),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '手机朝向',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down,
                        color: Color(0xFFFF416C), size: 20),
                  ],
                ),
              ),

              // 1. 刻度表盘（随方向旋转）
              Transform.rotate(
                angle: dialAngleRad,
                child: CustomPaint(
                  size: Size(size, size),
                  painter: CompassDialPainter(),
                ),
              ),

              // 2. 人物指针（以自身图片正上为南进行旋转校准）
              Transform.rotate(
                angle: pointerAngleRad,
                child: SizedBox(
                  width: size * 0.85,
                  height: size * 0.85,
                  child: Image.asset(
                    'assets/images/pointer_centered.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // 3. 中心红点轴心
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4B2B),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Color(0xFFFF4B2B),
                        blurRadius: 8,
                        spreadRadius: 2),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter(bool sensorConnected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  sensorConnected ? '传感器: 正常工作' : '传感器: 未检测到',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  _useManual ? '模式: 手动调试' : '模式: 真实传感器',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 模拟滑块
          Row(
            children: [
              const Text('手动模拟', style: TextStyle(fontSize: 12, color: Colors.white54)),
              Expanded(
                child: Slider(
                  value: _manualHeading,
                  min: 0,
                  max: 359,
                  activeColor: const Color(0xFFFF5252),
                  onChanged: (val) {
                    setState(() {
                      _manualHeading = val;
                      _useManual = true;
                    });
                  },
                ),
              ),
              Text('${_manualHeading.round()}°',
                  style: const TextStyle(fontSize: 12, color: Colors.white54)),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _useManual ? Colors.blueAccent : Colors.white12,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              setState(() {
                _useManual = !_useManual;
              });
            },
            child: Text(_useManual ? '切换为实时传感器模式' : '切换为手动拖拽模式'),
          ),
        ],
      ),
    );
  }
}

// 绘制罗盘刻度线与方向文字
class CompassDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 背景暗色圆盘
    final bgPaint = Paint()
      ..color = const Color(0xFF141923).withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 4, bgPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 4, borderPaint);

    // 刻度线
    final majorTick = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 2;
    final minorTick = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1;
    final cardinalTick = Paint()
      ..color = const Color(0xFFFF5252)
      ..strokeWidth = 3;

    for (int deg = 0; deg < 360; deg += 5) {
      final rad = (deg - 90) * math.pi / 180;
      final bool isCardinal = deg % 90 == 0;
      final bool isMajor = deg % 30 == 0;

      final double outerR = radius - 10;
      final double innerR = isCardinal
          ? radius - 26
          : (isMajor ? radius - 22 : radius - 16);

      final p1 = Offset(center.dx + outerR * math.cos(rad),
          center.dy + outerR * math.sin(rad));
      final p2 = Offset(center.dx + innerR * math.cos(rad),
          center.dy + innerR * math.sin(rad));

      final paint = isCardinal ? cardinalTick : (isMajor ? majorTick : minorTick);
      canvas.drawLine(p1, p2, paint);
    }

    // 绘制 4 个方位字
    _drawText(canvas, center, radius - 42, 0, '北', const Color(0xFF4FC3F7));
    _drawText(canvas, center, radius - 42, 90, '东', Colors.white70);
    _drawText(canvas, center, radius - 42, 180, '南', const Color(0xFFFF5252));
    _drawText(canvas, center, radius - 42, 270, '西', Colors.white70);
  }

  void _drawText(Canvas canvas, Offset center, double distance, double deg,
      String text, Color color) {
    final rad = (deg - 90) * math.pi / 180;
    final pos = Offset(center.dx + distance * math.cos(rad),
        center.dy + distance * math.sin(rad));

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: 16,
        fontWeight: FontWeight.bold,
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
