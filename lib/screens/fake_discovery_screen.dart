import '../models/device.dart';

class FakeDiscoveryScreen {
  static final List<Device> _sampleDevices = [
    Device(
      name: 'Jimmy-Desktop',
      ipAddress: '192.168.1.101',
      status: DeviceStatus.available,
    ),
    Device(
      name: 'Lenovo-Laptop',
      ipAddress: '192.168.1.102',
      status: DeviceStatus.busy,
    ),
    Device(
      name: 'Android-Phone',
      ipAddress: '192.168.1.103',
      status: DeviceStatus.available,
    ),
  ];

  static int _index = 0;

  static Device? getNextDevice() {
    if (_index >= _sampleDevices.length) return null;
    return _sampleDevices[_index++];
  }

  static void reset() {
    _index = 0;
  }
}
