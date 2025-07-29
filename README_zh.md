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

## ⚠️ 重要使用说明

### 系统音频录制权限要求

**在使用此模块之前，您必须手动为您的应用程序启用系统音频录制权限：**

1. **打开系统偏好设置** > **隐私与安全性** > **录屏与系统录音**
2. **在列表中找到您的应用程序**
3. **为您的应用启用"仅系统录音"**
4. **授予权限后重启您的应用程序**

**注意**: 此模块需要系统音频录制权限来捕获系统音频流。没有适当的权限，模块可能会运行但不会捕获实际的系统音频数据。

### 权限设置步骤：

1. **导航到系统偏好设置**：
   - 打开系统偏好设置（或更新版本macOS上的系统设置）
   - 转到隐私与安全性
   - 找到"录屏与系统录音"

2. **为您的应用启用权限**：
   - 在列表中找到您的应用程序
   - 勾选"仅系统录音"选项
   - 如果您的应用未列出，点击"+"按钮添加

3. **重启您的应用程序**：
   - 完全关闭您的应用程序
   - 重新打开您的应用程序
   - 测试音频捕获功能

### 权限问题故障排除

如果您遇到音频捕获问题：

1. **验证权限设置**：
   - 确保您的应用有"仅系统录音"权限
   - 检查没有其他应用正在使用系统音频录制
   - 权限更改后重启您的应用程序

2. **常见问题**：
   - 如果没有捕获到音频，检查权限设置
   - 如果权限选项不可见，请更新macOS到最新版本
   - 如果应用不在权限列表中，使用"+"按钮手动添加

3. **替代权限位置**：
   - 在某些macOS版本上：系统偏好设置 > 安全性与隐私 > 隐私 > 麦克风
   - 在麦克风设置中查找"系统音频"选项

### 构建问题
如果构建失败，请确保：
- 已安装 Xcode Command Line Tools: `xcode-select --install`
- Swift 版本 >= 5.3: `swift --version`
- Node.js 版本 >= 16: `node --version`

## 📋 待办事项列表

### 高优先级
- [ ] **实现准确的权限检查** - 添加适当的系统音频录制权限验证
- [ ] **添加权限状态检测** - 实时权限状态监控
- [ ] **改进错误处理** - 权限相关问题的更好错误消息

### 中优先级
- [ ] **添加音频格式验证** - 验证音频格式兼容性
- [ ] **实现音频质量设置** - 可配置的音频质量选项
- [ ] **添加音频设备选择** - 允许用户选择特定的音频设备
- [ ] **实现音频效果** - 基本音频处理功能
- [ ] **添加流媒体支持** - 实时音频流媒体功能

## 🙏 致谢

- [CoreAudio](https://developer.apple.com/documentation/coreaudio) - Apple的音频框架
- [NAPI](https://nodejs.org/api/n-api.html) - Node.js原生API
- [Swift NAPI Bindings](https://github.com/LinusU/swift-napi-bindings) - Swift与NAPI的绑定库

## 🎯 项目支持

本项目由 [Subtitles](https://subtitles.felo.me/) 提供支持 - 一个AI驱动的字幕生成平台，帮助创作者和开发者轻松为视频和音频内容添加字幕。

**为什么选择 Subtitles？**
- 🤖 **AI驱动**: 先进的语音识别技术，提供准确的转录
- ⚡ **快速处理**: 为您的媒体文件提供快速周转时间
- 🌍 **多语言支持**: 支持多种语言和方言
- 🎬 **视频和音频**: 适用于视频和音频文件
- 📱 **易于集成**: 简单的API和用户友好的界面

**音频捕获用户的完美选择**: 如果您正在使用此音频捕获模块进行内容创作、播客或视频制作，[Subtitles](https://subtitles.felo.me/) 可以帮助您从捕获的音频文件自动生成准确的字幕。

[立即试用 Subtitles →](https://subtitles.felo.me/)

---

**注意**: 此模块仅支持 macOS 系统，需要适当的音频权限。