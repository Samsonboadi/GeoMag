import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


class BleMagService {
final _ble = FlutterReactiveBle();
// Replace with your device's advertised service/char UUIDs
final Uuid magService = Uuid.parse("00001820-0000-1000-8000-00805f9b34fb");
final Uuid magChar = Uuid.parse("00002a5b-0000-1000-8000-00805f9b34fb");


Stream<List<int>> scanForMag() {
return _ble.scanForDevices(withServices: [magService]).map((d) => d.manufacturerData);
}


// Connect + notify
Stream<List<int>> subscribeToMag({required String deviceId}) {
final char = QualifiedCharacteristic(serviceId: magService, characteristicId: magChar, deviceId: deviceId);
return _ble.subscribeToCharacteristic(char);
}
}