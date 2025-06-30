# LAN File Transfer App Design
Version: 0.1 (Draft)
Last Updated: 2025-06-28
## 1. Problem Statement
As a student, I bring my laptop to class and whenever I want to code on my desktop, I find it a problem to transfer between the two. I want to create an easier way for me to transfer my coding work.

## 2. Target Users
So far the target user is just me, but maybe I could make this app more robust to make it handle file transferring for everyone that has this problem.

## 3. Core Features
- File transfer between devices (desktop/laptop, with Android support as well)
- Discover other devices on the same Wi-Fi network
- Pick and send files
- Accept or reject incoming transfers
- Save received files

## 4. User Flows

**Sender Flow**
1. Open the app
2. See list of nearby devices on the same Wi-Fi
3. Select a device to send to
4. Choose a file from local storage
5. Send the file
6. See transfer progress / confirmation

**Receiver Flow**
1. Open the app
2. App is listening for requests
3. Incoming request is shown (who is sending, file info)
4. Accept or reject the request
5. If accepted, file is saved locally
6. See confirmation / progress

## 5. Screens
- **Device Discovery Screen**: shows available devices on LAN
- **File Picker Screen**: choose a file to send
- **Incoming Request Dialog**: displays sender info, accept/reject buttons
- **Transfer Progress Screen**: shows progress bar, transfer status
- **Settings Screen (optional)**: set device name, default save folder

## 6. Data Model

### Device
Represents a discovered device on the local network

- name: String - the device's name (e.g. "Jimmy-PC")
- ipAddress: String - the LAN IP address (e.g. "192.168.1.15")
- status: enum { available, busy } – indicates if the device is currently able to receive a file

### FileInfo
Represents a file to be transferred.
- fileName: String – the name of the file
- fileSizeBytes: int – raw file size in bytes (for precision)
- fileType: String – e.g. ".jpg", ".zip"
- filePath: String – local path on the device

*Note:* 
- UI will show human-readable size (e.g. "5.7 MB") by formatting fileSizeBytes.

### TransferSession
Represents an active file transfer between devices.

- direction: enum { sending, receiving } – indicates role
- file: FileInfo – the file being transferred
- progress: double (0.0 – 1.0) – transfer progress
- status: enum { idle, connecting, transferring, completed, failed }
- peerDevice: Device – the other device in the transfer

### AppSettings
User-configurable settings.

- localDeviceName: String – how this device identifies itself
- defaultSaveFolder: String – path to save received files

### AppState
Represents the entire current state of the app.

- discoveredDevices: `List<Device>`– devices found on LAN
- selectedFile: FileInfo? – file selected to send
- activeTransfer: TransferSession? – current transfer session
- settings: AppSettings – user preferences
- isListening: bool – whether the app is listening for incoming requests

## 7. Networking Protocol
- **UDP Discovery**
  - Broadcast "hello" messages with device name and IP
  - Listen and respond to discovery requests

- **TCP Transfer**
  - Sender opens TCP connection to receiver
  - Sends file metadata (name, size)
  - Receiver responds with accept/reject
  - Sender streams file data in chunks
  - Receiver saves file

## 8. Tech Stack
- **Language**: Dart
- **Framework**: Flutter
- **Networking**: dart:io for UDP and TCP sockets
- **State Management**: Provider or Riverpod
- **UI Design**: Flutter Material Design (cross-platform)
- **Platforms**: Windows (initial), Android (next), optionally MacOS/iOS later

## 9. Testing Plan
- Start with Windows-to-Windows transfers on local Wi-Fi
- Then Windows-to-Android transfers
- Test with different file sizes (small text files, large images, code projects)
- Test accept/reject flows
- Simulate multiple devices on same network

## 10. Packaging Plan
- **Windows**: Build .exe or installer with Flutter desktop support
- **Android**: Build .apk file for sideloading or Play Store (future)
- **Distribution**: Host builds on GitHub Releases with clear install instructions
- **Optional**: Demo video showcasing usage and key features

## 11. Planned Flutter Project Structure

- /lib
  - main.dart – App entry point
  - /models – data classes for Device, FileInfo, TransferSession, etc.
  - /screens – UI pages and dialogs
  - /services – networking and file transfer logic
  - /state – app state management (Provider or Riverpod)

## 12. Networking Protocol Design

### Discovery Phase (UDP)
- Devices broadcast "hello" packets on a fixed port
- Message includes:
  - deviceName
  - ipAddress
  - status (available/busy)
- Listening devices respond with same info
- Result: Both devices build a list of peers on the LAN

### Transfer Phase (TCP)
- Sender establishes TCP connection to receiver
- Sender sends file metadata:
  - fileName
  - fileSizeBytes
  - fileType
- Receiver responds with accept/reject
- If accepted:
  - Sender streams file in chunks
  - Receiver writes to file
  - Both track progress
- If rejected:
  - Connection closed

### Ports
- UDP Discovery Port: [your chosen port number]
- TCP Transfer Port: [your chosen port number]

### Example UDP Discovery Message

```json
{
  "deviceName": "Jimmy-PC",
  "ipAddress": "192.168.1.15",
  "status": "available"
}
```

### Example TCP Metadata Message

```json
{
  "fileName": "example.zip",
  "fileSizeBytes": 5982345,
  "fileType": ".zip"
}
```
