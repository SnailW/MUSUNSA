#include <Arduino.h>
#include <AudioTools.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <Adafruit_NeoPixel.h>
#include <BluetoothA2DPSink.h>

#define LED_PIN 16
#define LED_COUNT 30

I2SStream i2s;
BluetoothA2DPSink a2dp_sink(i2s);
BLECharacteristic *pCharacteristic;
Adafruit_NeoPixel strip = Adafruit_NeoPixel(LED_COUNT, LED_PIN, NEO_GRB + NEO_KHZ800);

// BLE 서비스 및 특성 정의, UUID는 추후 변경 예정
#define SERVICE_UUID "12345678-1234-5678-1234-56789abcdef0"
#define CHARACTERISTIC_UUID "12345678-1234-5678-1234-56789abcdef1"

// 프로토타입
void processCommand(String command);
void setColor(int r, int g, int b);
void setBright(int bright);

bool deviceConnected = false;

// BLE 콜백 클래스 정의
class MyServerCallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
        deviceConnected = true;
    }
    void onDisconnect(BLEServer* pServer) {
        deviceConnected = false;
    }
};

// BLE 데이터 수신 콜백 클래스
class MyCallbacks : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
        String command = pCharacteristic->getValue().c_str();
        processCommand(command); // processCommand 호출
    }
};

char title[160] = {"Undefined"};

void avrc_metadata_callback(uint8_t id, const uint8_t *text) {
  Serial.printf("==> AVRC metadata rsp: attribute id 0x%x, %s\n", id, text);
  if (id == ESP_AVRC_MD_ATTR_TITLE) {
    strncpy(title, (const char *)text, 160);
    pCharacteristic->setValue(title);
  }
}

void setup() {
    Serial.begin(115200);
    auto cfg = i2s.defaultConfig();
    cfg.pin_bck = 14;
    cfg.pin_ws = 15;
    cfg.pin_data = 22;
    i2s.begin(cfg);

    // Bluetooth A2DP Sink 초기화
    // start a2dp in ESP_BT_MODE_BTDM mode
    a2dp_sink.set_default_bt_mode(ESP_BT_MODE_BTDM);
    a2dp_sink.set_avrc_metadata_callback(avrc_metadata_callback);
    a2dp_sink.start("MUSUNSA"); // A2DP 이름 설정

    // BLE 초기화
    BLEDevice::init("MUSUNSA"); // BLE 이름 설정
    BLEServer *pServer = BLEDevice::createServer();
    BLEService *pService = pServer->createService(SERVICE_UUID); // 서비스 생성
    // 특성을 서비스에서 생성
    pCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR // 또는 PROPERTY_WRITE_WITH_RESPONSE
    );

    pCharacteristic->setValue(title);
    pServer->setCallbacks(new MyServerCallbacks()); // 연결 콜백 설정
    pCharacteristic->setCallbacks(new MyCallbacks()); // 콜백 설정
    pService->start(); // 서비스 시작
    // 추후 필요하면 사용
    // BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    // pAdvertising->addServiceUUID(SERVICE_UUID);
    // pAdvertising->setScanResponse(true);
    // pAdvertising->setMinPreferred(0x06); // functions that help with iPhone connections issue
    // pAdvertising->setMinPreferred(0x12);
    pServer->getAdvertising()->start(); // 광고 시작

    strip.begin();
    for (int i = 0; i < strip.numPixels(); i++) {
        strip.setPixelColor(i, strip.Color(255, 115, 23));
    }
    strip.setBrightness(64); // 테스트를 위한 밝기, 테스트 이후 0으로 설정
    strip.show();

  Serial.println("The device started");
}

void loop() {
    delay(100);
}

// 색상 설정
void setColor(int r, int g, int b) {
    for (int i = 0; i < strip.numPixels(); i++) {
        strip.setPixelColor(i, strip.Color(r, g, b));
    }
    strip.show();
    Serial.printf("color : %d %d %d\n",r,g,b);
    strip.show();
}

// 밝기 설정
void setBright(int bright) {
    strip.setBrightness(bright);
    strip.show();
    Serial.print("bright : ");
    Serial.println(bright);
    strip.show();
}

// 명령어 처리
void processCommand(String command) {
    if (command.startsWith("COLOR")) {
        // COMMAND 예: "COLOR 255 0 0"
        int r = command.substring(6, command.indexOf(' ', 6)).toInt();
        int g = command.substring(command.indexOf(' ', 6) + 1, command.lastIndexOf(' ')).toInt();
        int b = command.substring(command.lastIndexOf(' ') + 1).toInt();
        setColor(r, g, b);
    }
    else if(command.startsWith("BRIGHT")){
      // COMMAND 예: "BRIGHT 64"
        int bright = command.substring(7).toInt();
        setBright(bright);
    }
}