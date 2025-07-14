import NAPI
import Foundation
import AVFoundation
import OSLog

// MARK: - Global State Management
/// Global audio capture manager
private final class AudioCaptureManager {
    static let shared = AudioCaptureManager()
    
    private init() {}
    
    var audioTap: SystemAudioTap?
    var audioRecorder: SystemAudioRecorder?
    
    private lazy var audioFileURL: URL = {
        let filename = "system_audio_\(Int(Date.now.timeIntervalSinceReferenceDate))"
        return URL.applicationSupport.appendingPathComponent(filename, conformingTo: .wav)
    }()
    
    func getAudioFileURL() -> URL {
        return audioFileURL
    }
    
    func reset() {
        audioTap = nil
        audioRecorder = nil
    }
}

// MARK: - Logging
private let logger = Logger(subsystem: kAppSubsystem, category: "AudioCapture")

// MARK: - Public API Functions
/// Configure audio capture parameters
/// - Parameter options: Configuration options dictionary
/// - Throws: AudioCaptureError Configuration error
func configure(options: [String: Any]) throws {
    logger.info("🎵 Configuring audio capture system")
    
    var config = AudioCaptureConfig()
    
    // Parse configuration parameters
    if let sampleRate = options["sampleRate"] as? Double {
        config.sampleRate = sampleRate
        logger.info("📊 Setting sample rate: \(sampleRate) Hz")
    }
    
    if let channelCount = options["channelCount"] as? UInt32 {
        config.channelCount = channelCount
        logger.info("🎧 Setting channel count: \(channelCount)")
    }
    
    if let logPath = options["logPath"] as? String {
        config.logFileURL = URL(fileURLWithPath: logPath)
        logger.info("📝 Setting log path: \(logPath)")
    }
    
    do {
        try configureAudioCapture(config: config)
        logger.info("✅ Audio capture configuration completed")
    } catch {
        let errorMessage = error.localizedDescription
        logger.error("❌ Configuration failed: \(errorMessage)")
        throw error
    }
}

/// Start audio capture
/// - Throws: AudioCaptureError Capture error
func startCapture() throws {
    logger.info("🎙️  Starting audio capture")
    
    let manager = AudioCaptureManager.shared
    
    // Check if already running
    guard manager.audioTap == nil || !manager.audioTap!.activated else {
        let errorMessage = "Audio capture is already running"
        logger.warning("⚠️  \(errorMessage)")
        throw AudioCaptureError.invalidConfiguration
    }
    
    do {
        // Create and activate audio Tap
        if manager.audioTap == nil {
            logger.info("🔧 Creating SystemAudioTap instance")
            manager.audioTap = SystemAudioTap()
            logger.info("⚡ Activating SystemAudioTap")
            manager.audioTap?.activate()
        }
        
        // Check Tap status
        if let errorMessage = manager.audioTap?.errorMessage {
            logger.error("❌ Tap error: \(errorMessage)")
            throw AudioCaptureError.tapNotAvailable
        }
        
        // Create recorder
        if manager.audioRecorder == nil, let tap = manager.audioTap {
            logger.info("🎵 Creating SystemAudioRecorder instance")
            manager.audioRecorder = SystemAudioRecorder(
                fileURL: manager.getAudioFileURL(), 
                tap: tap
            )
        }
        
        guard let recorder = manager.audioRecorder else {
            logger.error("❌ Recorder not initialized")
            throw AudioCaptureError.invalidConfiguration
        }
        
        // Start recording
        try recorder.start()
        logger.info("✅ Audio capture started")
        
    } catch {
        logger.error("❌ Recording failed: \(error.localizedDescription)")
        throw error
    }
}

/// Stop audio capture
/// - Throws: AudioCaptureError Stop error
func stopCapture() throws {
    logger.info("🛑 Stopping audio capture")
    
    let manager = AudioCaptureManager.shared
    
    guard let recorder = manager.audioRecorder, recorder.isRecording else {
        let errorMessage = "No audio capture in progress"
        logger.warning("⚠️  \(errorMessage)")
        throw AudioCaptureError.invalidConfiguration
    }
    
    recorder.stop()
    logger.info("✅ Audio capture stopped")
}

/// Get audio data
/// - Returns: Base64 encoded audio data array
/// - Throws: AudioCaptureError Data retrieval error
func getAudioData() throws -> [String] {
    let manager = AudioCaptureManager.shared
    
    guard let recorder = manager.audioRecorder else {
        let errorMessage = "Recorder not initialized when trying to get audio data"
        logger.warning("⚠️  \(errorMessage)")
        throw AudioCaptureError.invalidConfiguration
    }
    
    if let data = recorder.getAudioData() {
        logger.debug("📊 Retrieved \(data.count) audio data segments")
        return data
    } else {
        logger.debug("📊 No audio data available")
        return []
    }
}

@_cdecl("_init_callbacks")
func initCallbacks(env: OpaquePointer, exports: OpaquePointer) -> OpaquePointer? {
    logger.info("Initializing callback module")
    return initModule(env, exports, [
        .function("configure", { try configure(options: [:]) }),
        .function("startCapture", startCapture),
        .function("stopCapture", stopCapture),
        .function("getAudioData", getAudioData)
    ])
}

