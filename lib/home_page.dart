// lib/home_page.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'product_page.dart';  // ProductPage를 가져옵니다.

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<BluetoothDevice> devices = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
  }

  void startScan() {
    if (!isScanning) {
      setState(() {
        isScanning = true;
        // devices.clear(); // 스캔 시작 시 기존 디바이스 목록을 초기화
      });

      // Bluetooth 스캔 시작
      FlutterBluePlus.startScan(timeout: Duration(seconds: 4));

      // 스캔 결과를 처리
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          print('Found device: ${r.device.platformName}');
          if (r.device.platformName == "MUSUNSA" && !devices.contains(r.device)) {
            setState(() {
              devices.add(r.device); // MUSUNSA 디바이스만 추가
            });
          }
        }
      });

      // 스캔 종료
      Future.delayed(Duration(seconds: 4), () {
        FlutterBluePlus.stopScan().then((_) {
          setState(() {
            isScanning = false;
          });
          // 스캔이 끝났을 때 다이얼로그를 열어 디바이스 목록을 표시
          showFoundDevicesDialog();
        });
      });
    }
  }

  void showFoundDevicesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('찾은 디바이스'),
          content: SingleChildScrollView(
            child: ListBody(
              children: devices.isNotEmpty
                  ? devices.map((device) {
                return Text(device.platformName.isNotEmpty
                    ? device.platformName
                    : "Unnamed Device");
              }).toList()
                  : [Text("찾은 디바이스가 없습니다.")],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text('닫기'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void connectToDevice(BluetoothDevice device) async {
    // 디바이스에 연결
    await device.connect();
    // 연결 후 추가 처리 (필요시)
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('디바이스 목록'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.search),
          onPressed: () {
            startScan(); // "+" 버튼 클릭 시 스캔 시작
          },
        ),
      ),
      child: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // 제품 화면으로 이동
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => ProductPage(device: devices[index]), // 디바이스 객체 전달
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      devices[index].platformName.isNotEmpty
                          ? devices[index].platformName
                          : "Unnamed Device",
                    ),
                  ),
                  CupertinoButton(
                    child: Text('연결'),
                    onPressed: () {
                      connectToDevice(devices[index]); // 디바이스 연결
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
