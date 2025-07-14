# 🎵 Audio Capture

[![Node.js](https://img.shields.io/badge/Node.js-16+-green.svg)](https://nodejs.org/)
[![macOS](https://img.shields.io/badge/macOS-14.4+-blue.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-5.3+-orange.svg)](https://swift.org/)

一个基于Swift和CoreAudio的Node.js模块，用于捕获Mac系统音频流。解决了Node.js无法直接获取macOS系统扬声器音频流的技术难题。

[English Version](README.md) | 中文版本

## ✨ 特性

- 🎯 **系统级捕获**: 使用CoreAudio Process Tap技术捕获所有应用程序的音频输出
- ⚡ **高性能**: Swift原生代码提供接近C语言的性能表现
- 🔧 **易用API**: 提供简洁的JavaScript接口，支持Promise和事件驱动
- 🎵 **实时处理**: 支持实时音频数据处理和格式转换
- 📁 **多格式输出**: 支持WAV格式音频文件输出
- 🛡️ **错误处理**: 完善的错误处理和状态管理
- 📊 **详细日志**: 提供详细的调试和状态日志

## 🚀 快速开始

### 安装

```bash
# 从GitHub安装
npm install git+https://github.com/sparticleinc/mac-audio-capture.git

# 或者克隆仓库后本地安装
git clone https://github.com/sparticleinc/mac-audio-capture.git
cd mac-audio-capture
npm install
```

### 基本使用

```javascript
const AudioCapture = require('./lib');

async function captureAudio() {
    // 创建音频捕获器
    const capture = new AudioCapture({
        sampleRate: 48000,
        channelCount: 2
    });
    
    // 监听事件
    capture.on('started', () => console.log('🎙️ 开始捕获'));
    capture.on('stopped', () => console.log('🛑 停止捕获'));
    capture.on('error', (error) => console.error('❌ 错误:', error.message));
    
    try {
        // 录制5秒音频
        const filePath = await capture.record(5000, 'output.wav');
        console.log('✅ 录制完成:', filePath);
    } catch (error) {
        console.error('录制失败:', error.message);
    }
}

captureAudio();
```

### 高级使用

```javascript
const AudioCapture = require('./lib');

async function advancedCapture() {
    const capture = new AudioCapture();
    
    // 配置音频捕获
    await capture.configure({
        sampleRate: 44100,
        channelCount: 1,
        logPath: './logs/audio.log'
    });
    
    // 开始捕获
    await capture.startCapture({ interval: 100 });
    
    // 实时处理音频数据
    capture.on('data', (audioData) => {
        console.log(`📊 接收到 ${audioData.length} 个音频片段`);
        // 在这里处理音频数据
    });
    
    // 录制3秒
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    // 停止捕获
    await capture.stopCapture();
    
    // 保存为WAV文件
    const filePath = await capture.saveToWav('advanced-output.wav');
    console.log('文件已保存:', filePath);
}
```

## 📖 API 文档

### AudioCapture 类

#### 构造函数

```javascript
new AudioCapture(options?: AudioCaptureConfig)
```

**参数:**
- `options` (可选): 配置选项
  - `sampleRate`: 采样率 (默认: 48000)
  - `channelCount`: 声道数 (默认: 2)
  - `logPath`: 日志文件路径

#### 方法

##### configure(options)
配置音频捕获器

```javascript
await capture.configure({
    sampleRate: 44100,
    channelCount: 1,
    logPath: './audio.log'
});
```

##### startCapture(options)
开始音频捕获

```javascript
await capture.startCapture({ interval: 100 });
```

##### stopCapture()
停止音频捕获

```javascript
await capture.stopCapture();
```

##### record(durationMs, outputPath)
录制指定时长的音频

```javascript
const filePath = await capture.record(5000, 'output.wav');
```

##### saveToWav(outputPath, audioData)
保存音频数据为WAV文件

```javascript
const filePath = await capture.saveToWav('output.wav');
```

##### getAudioData()
获取当前音频数据

```javascript
const audioData = capture.getAudioData();
```

##### clearBuffer()
清空音频缓冲区

```javascript
capture.clearBuffer();
```

#### 事件

- `configured`: 配置完成时触发
- `started`: 开始捕获时触发
- `stopped`: 停止捕获时触发
- `data`: 接收到音频数据时触发
- `saved`: 文件保存完成时触发
- `error`: 发生错误时触发

## 🛠️ 开发

### 环境要求

- Node.js 16+
- macOS 14.4+
- Swift 5.3+
- Xcode Command Line Tools

### 安装依赖

```bash
npm install
```

### 构建

```bash
# 开发构建
npm run dev

# 生产构建
npm run build
```

### 测试

```bash
npm test
```

### 运行示例

```bash
npm run example
```

### 代码格式化

```bash
npm run format
npm run lint
```

## 🏗️ 技术架构

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

### 核心技术

1. **CoreAudio Process Tap**: 系统级音频捕获
2. **Aggregate Device**: 虚拟音频设备管理
3. **NAPI (Node-API)**: 跨语言绑定
4. **Event-Driven Architecture**: 事件驱动架构
5. **Real-time Audio Processing**: 实时音频处理

## 📝 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 打开 Pull Request

## 📞 支持

如果您遇到问题或有建议，请：

1. 查看 [Issues](https://github.com/sparticleinc/mac-audio-capture/issues) 页面
2. 创建新的 Issue
3. 联系维护者

## 🔧 故障排除

### 权限问题
如果遇到音频权限问题，请确保：
- 在系统偏好设置中允许应用访问麦克风
- 在安全性与隐私中允许应用访问系统音频

### 构建问题
如果构建失败，请确保：
- 已安装 Xcode Command Line Tools: `xcode-select --install`
- Swift 版本 >= 5.3: `swift --version`
- Node.js 版本 >= 16: `node --version`

## 🙏 致谢

- [CoreAudio](https://developer.apple.com/documentation/coreaudio) - Apple的音频框架
- [NAPI](https://nodejs.org/api/n-api.html) - Node.js原生API
- [Swift NAPI Bindings](https://github.com/LinusU/swift-napi-bindings) - Swift与NAPI的绑定库

---

**注意**: 此模块仅支持 macOS 系统，需要适当的音频权限。