import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// 특성 UUID 정의 (ESP32에서 사용하는 UUID로 수정하세요)
const String characteristicUUID = "12345678-1234-5678-1234-56789abcdef1"; // 예시 UUID

class ProductPage extends StatefulWidget {
  final BluetoothDevice device;

  const ProductPage({required this.device});

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  Color selectedColor = Colors.red; // 초기 색상
  int selectedBrightness = 0;
  BluetoothCharacteristic? characteristic;
  double hue = 0; // 초기 hue 값
  double brightness = 64;
  DateTime? lastSentTime; // 마지막 전송 시간
  final Duration sendInterval = Duration(milliseconds: 100); // 100ms 간격
  bool isPowerOn = false; // 전원 상태

  @override
  void initState() {
    super.initState();
    _getCharacteristic(); // 특성 가져오기
  }

  Future<void> _getCharacteristic() async {
    List<BluetoothService> services = await widget.device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.uuid.toString() == characteristicUUID) {
          this.characteristic = characteristic; // 특성 저장
        }
      }
    }
  }

  void sendColorToESP32(Color color) async {
    if (characteristic != null) {
      int r = color.red;
      int g = color.green;
      int b = color.blue;
      String command = "COLOR ${r} ${g} ${b}";

      try {
        // 응답을 기다리도록 설정
        await characteristic!.write(command.codeUnits, withoutResponse: false);
      } catch (e) {
        print("Error writing to characteristic: $e");
      }
    } else {
      print("Characteristic is not found.");
    }
  }

  void sendBrightnessToESP32(int brightness) async {
    if (characteristic != null) {
      String command = "BRIGHT ${brightness}";

      try {
        // 응답을 기다리도록 설정
        await characteristic!.write(command.codeUnits, withoutResponse: false);
      } catch (e) {
        print("Error writing to characteristic: $e");
      }
    } else {
      print("Characteristic is not found.");
    }
  }

  void _onHueChanged(double value) {
    setState(() {
      hue = value; // Hue 값 업데이트
      selectedColor = HSLColor.fromAHSL(1.0, hue, 1.0, 0.5).toColor(); // Hue로 RGB 변환
    });

    // 현재 시간 확인
    DateTime now = DateTime.now();
    if (lastSentTime == null || now.difference(lastSentTime!) > sendInterval) {
      lastSentTime = now; // 시간 업데이트
      sendColorToESP32(selectedColor); // 선택한 색상 전송
    }
  }

  void _onBrightChanged(double value) {
    setState(() {
      brightness = value; // Hue 값 업데이트
      selectedBrightness = brightness.toInt();
    });

    // 현재 시간 확인
    DateTime now = DateTime.now();
    if (lastSentTime == null || now.difference(lastSentTime!) > sendInterval) {
      lastSentTime = now; // 시간 업데이트
      sendBrightnessToESP32(selectedBrightness); // 선택한 색상 전송
    }
  }

  void _togglePower() {
    setState(() {
      isPowerOn = !isPowerOn; // 전원 상태 토글
      if (isPowerOn) {
        sendColorToESP32(selectedColor); // 전원 켜기
      } else {
        sendColorToESP32(Colors.black); // 전원 끄기
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.device.name),
      ),
      child: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 300), // 위쪽 여백 추가
              // 커스텀 슬라이더
              Container(
                width: 280, // 원하는 슬라이더 너비
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 색상 그라데이션 배경
                    CustomPaint(
                      size: Size(double.infinity, 8), // 슬라이더 배경 두께
                      painter: ColorSliderPainter(),
                    ),
                    // 슬라이더
                    Positioned(
                      top: 0,
                      child: SizedBox(
                        width: 300, // CustomPaint와 같은 너비로 설정
                        child: CupertinoSlider(
                          value: hue,
                          min: 0,
                          max: 360,
                          onChanged: _onHueChanged, // Hue 변경 핸들러
                          divisions: 360,
                          activeColor: Colors.transparent, // 현재 선택된 색상으로 슬라이더의 색상 변경
                          thumbColor: Colors.white, // Thumb 색상
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),// 슬라이더와 슬라이더 간의 여백
              CupertinoSlider( // 밝기 조절 슬라이더
                  value: brightness,
                  min: 0,
                  max: 255,
                  divisions: 255,
                  onChanged: _onBrightChanged,
              ),
              SizedBox(height: 20),// 슬라이더와 전원 버튼 간의 여백
              // 전원 버튼
              GestureDetector(
                onTap: _togglePower, // 전원 버튼 클릭 핸들러
                child: Container(
                  width: 200,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isPowerOn ? selectedColor : Colors.grey, // 전원 상태에 따라 색상 변경
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isPowerOn ? "전원 끄기" : "전원 켜기", // 버튼 텍스트
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
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

class ColorSliderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 색상 그라데이션
    for (int i = 0; i < size.width; i++) {
      paint.color = HSLColor.fromAHSL(1.0, (i / size.width) * 360, 1.0, 0.5).toColor();
      canvas.drawRect(Rect.fromLTWH(i.toDouble(), 0, 1, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(ColorSliderPainter oldDelegate) {
    return false; // 항상 repaint하지 않음
  }
}
