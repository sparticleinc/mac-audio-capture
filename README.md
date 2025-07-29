# 🎵 Audio Capture

[![Node.js](https://img.shields.io/badge/Node.js-16+-green.svg)](https://nodejs.org/)
[![macOS](https://img.shields.io/badge/macOS-14.4+-blue.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-5.3+-orange.svg)](https://swift.org/)

A Node.js module based on Swift and CoreAudio for capturing Mac system audio streams. Solves the technical challenge of Node.js being unable to directly access macOS system speaker audio streams.

[中文版本](README_zh.md) | English Version

## ✨ Features

- 🎯 **System-level Capture**: Uses CoreAudio Process Tap technology to capture audio output from all applications
- ⚡ **High Performance**: Swift native code provides near-C language performance
- 🔧 **Easy API**: Provides clean JavaScript interface with Promise and event-driven support
- 🎵 **Real-time Processing**: Supports real-time audio data processing and format conversion
- 📁 **Multi-format Output**: Supports WAV format audio file output
- 🛡️ **Error Handling**: Comprehensive error handling and state management
- 📊 **Detailed Logging**: Provides detailed debugging and status logs

## 🚀 Quick Start

### Installation

```bash
# Install from GitHub
npm install git+https://github.com/sparticleinc/mac-audio-capture.git

# Or clone repository and install locally
git clone https://github.com/sparticleinc/mac-audio-capture.git
cd mac-audio-capture
npm install
```

### Basic Usage

```javascript
const AudioCapture = require('./lib');

async function captureAudio() {
    // Create audio capture instance
    const capture = new AudioCapture({
        sampleRate: 48000,
        channelCount: 2
    });
    
    // Listen to events
    capture.on('started', () => console.log('🎙️ Started capturing'));
    capture.on('stopped', () => console.log('🛑 Stopped capturing'));
    capture.on('error', (error) => console.error('❌ Error:', error.message));
    
    try {
        // Record 5 seconds of audio
        const filePath = await capture.record(5000, 'output.wav');
        console.log('✅ Recording completed:', filePath);
    } catch (error) {
        console.error('Recording failed:', error.message);
    }
}

captureAudio();
```

### Advanced Usage

```javascript
const AudioCapture = require('./lib');

async function advancedCapture() {
    const capture = new AudioCapture();
    
    // Configure audio capture
    await capture.configure({
        sampleRate: 44100,
        channelCount: 1,
        logPath: './logs/audio.log'
    });
    
    // Start capture
    await capture.startCapture({ interval: 100 });
    
    // Real-time audio data processing
    capture.on('data', (audioData) => {
        console.log(`📊 Received ${audioData.length} audio segments`);
        // Process audio data here
    });
    
    // Record for 3 seconds
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    // Stop capture
    await capture.stopCapture();
    
    // Save as WAV file
    const filePath = await capture.saveToWav('advanced-output.wav');
    console.log('File saved:', filePath);
}
```

## 📖 API Documentation

### AudioCapture Class

#### Constructor

```javascript
new AudioCapture(options?: AudioCaptureConfig)
```

**Parameters:**
- `options` (optional): Configuration options
  - `sampleRate`: Sample rate (default: 48000)
  - `channelCount`: Number of channels (default: 2)
  - `logPath`: Log file path

#### Methods

##### configure(options)
Configure audio capture

```javascript
await capture.configure({
    sampleRate: 44100,
    channelCount: 1,
    logPath: './audio.log'
});
```

##### startCapture(options)
Start audio capture

```javascript
await capture.startCapture({ interval: 100 });
```

##### stopCapture()
Stop audio capture

```javascript
await capture.stopCapture();
```

##### record(durationMs, outputPath)
Record audio for specified duration

```javascript
const filePath = await capture.record(5000, 'output.wav');
```

##### saveToWav(outputPath, audioData)
Save audio data as WAV file

```javascript
const filePath = await capture.saveToWav('output.wav');
```

##### getAudioData()
Get current audio data

```javascript
const audioData = capture.getAudioData();
```

##### clearBuffer()
Clear audio buffer

```javascript
capture.clearBuffer();
```

#### Events

- `configured`: Triggered when configuration is complete
- `started`: Triggered when capture starts
- `stopped`: Triggered when capture stops
- `data`: Triggered when audio data is received
- `saved`: Triggered when file save is complete
- `error`: Triggered when an error occurs

## 🛠️ Development

### Requirements

- Node.js 16+
- macOS 14.4+
- Swift 5.3+
- Xcode Command Line Tools

### Install Dependencies

```bash
npm install
```

### Build

```bash
# Development build
npm run dev

# Production build
npm run build
```

### Test

```bash
npm test
```

### Run Examples

```bash
npm run example
```

### Code Formatting

```bash
npm run format
npm run lint
```

## 🏗️ Technical Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Node.js App   │    │   NAPI Binding  │    │  Swift Module   │
│                 │◄──►│                 │◄──►│                 │
│  JavaScript API │    │  C++ Interface  │    │  CoreAudio API  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │  Audio Buffer   │    │  Process Tap    │
                       │                 │    │                 │
                       │  Base64 Data    │    │  System Audio   │
                       └─────────────────┘    └─────────────────┘
```

### Core Technologies

1. **CoreAudio Process Tap**: System-level audio capture
2. **Aggregate Device**: Virtual audio device management
3. **NAPI (Node-API)**: Cross-language binding
4. **Event-Driven Architecture**: Event-driven architecture
5. **Real-time Audio Processing**: Real-time audio processing

## 📝 License

MIT License - see [LICENSE](LICENSE) file for details

## 🤝 Contributing

Issues and Pull Requests are welcome!

### Contributing Guidelines

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

If you encounter issues or have suggestions, please:

1. Check the [Issues](https://github.com/sparticleinc/mac-audio-capture/issues) page
2. Create a new Issue
3. Contact the maintainer

## ⚠️ Important Usage Notice

### System Audio Recording Permission Required

**Before using this module, you must manually enable system audio recording permission for your application:**

1. **Open System Preferences** > **Privacy & Security** > **Screen Recording & System Audio Recording**
2. **Find your application** in the list
3. **Enable "System Audio Recording Only"** for your app
4. **Restart your application** after granting permission

**Note**: This module requires system audio recording permission to capture system audio streams. Without proper permission, the module may run but will not capture actual system audio data.

### Permission Setup Steps:

1. **Navigate to System Preferences**:
   - Open System Preferences (or System Settings on newer macOS versions)
   - Go to Privacy & Security
   - Find "Screen Recording & System Audio Recording"

2. **Enable Permission for Your App**:
   - Locate your application in the list
   - Check the box for "System Audio Recording Only"
   - If your app is not listed, click the "+" button to add it

3. **Restart Your Application**:
   - Close your application completely
   - Reopen your application
   - Test audio capture functionality

### Troubleshooting Permission Issues

If you encounter issues with audio capture:

1. **Verify Permission Settings**:
   - Ensure your app has "System Audio Recording Only" permission
   - Check that no other apps are using system audio recording
   - Restart your application after permission changes

2. **Common Issues**:
   - If no audio is captured, check permission settings
   - If permission option is not visible, update macOS to latest version
   - If app is not in permission list, manually add it using the "+" button

3. **Alternative Permission Locations**:
   - On some macOS versions: System Preferences > Security & Privacy > Privacy > Microphone
   - Look for "System Audio" option in microphone settings

### Build Issues
If build fails, make sure:
- Xcode Command Line Tools installed: `xcode-select --install`
- Swift version >= 5.3: `swift --version`
- Node.js version >= 16: `node --version`

## 📋 TODO List

### High Priority
- [ ] **Implement accurate permission checking** - Add proper system audio recording permission validation
- [ ] **Add permission status detection** - Real-time permission status monitoring
- [ ] **Improve error handling** - Better error messages for permission-related issues

### Medium Priority
- [ ] **Add audio format validation** - Validate audio format compatibility
- [ ] **Implement audio quality settings** - Configurable audio quality options
- [ ] **Add audio device selection** - Allow users to select specific audio devices
- [ ] **Implement audio effects** - Basic audio processing features
- [ ] **Add streaming support** - Real-time audio streaming capabilities

## 🙏 Acknowledgments

- [CoreAudio](https://developer.apple.com/documentation/coreaudio) - Apple's audio framework
- [NAPI](https://nodejs.org/api/n-api.html) - Node.js native API
- [Swift NAPI Bindings](https://github.com/LinusU/swift-napi-bindings) - Swift and NAPI binding library

## 🎯 Project Support

This project is supported by [Subtitles](https://subtitles.felo.me/) - an AI-powered subtitle generation platform that helps creators and developers easily add captions to their videos and audio content. 

**Why Subtitles?**
- 🤖 **AI-Powered**: Advanced speech recognition technology for accurate transcriptions
- ⚡ **Fast Processing**: Quick turnaround times for your media files
- 🌍 **Multi-language Support**: Supports multiple languages and dialects
- 🎬 **Video & Audio**: Works with both video and audio files
- 📱 **Easy Integration**: Simple API and user-friendly interface

**Perfect for Audio Capture Users**: If you're using this audio capture module for content creation, podcasting, or video production, [Subtitles](https://subtitles.felo.me/) can help you automatically generate accurate captions from your captured audio files.

[Try Subtitles Now →](https://subtitles.felo.me/)

---

**Note**: This module only supports macOS systems and requires appropriate audio permissions. 