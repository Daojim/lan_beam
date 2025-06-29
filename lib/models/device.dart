enum DeviceStatus { available, busy }

class Device {
  // Fields in Dart, Attributes in Java
  final String name;
  final String ipAddress;
  final DeviceStatus status;

  //Constructor
  Device({required this.name, required this.ipAddress, required this.status});
}
