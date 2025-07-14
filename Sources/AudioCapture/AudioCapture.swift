import AudioToolbox
import AVFoundation
import AudioUnit
import CoreAudio
import OSLog

let kAppSubsystem = "com.sparticleinc.AudioCapture"

// Configuration structure
struct AudioCaptureConfig {
    var logFileURL: URL?
    var sampleRate: Double = 48000.0
    var channelCount: UInt32 = 2
}

// Global configuration
private var globalConfig = AudioCaptureConfig()

// Logging system
private let logger = Logger(subsystem: kAppSubsystem, category: "AudioCapture")

enum AudioCaptureError: Error {
    case createProcessTapFailed(OSStatus)
    case getStreamDescriptionFailed
    case createAggregateDeviceFailed(OSStatus)
    case createDeviceIOProcFailed(OSStatus)
    case startAudioDeviceFailed(OSStatus)
    case tapNotAvailable
    case streamFormatNotAvailable
    case createAudioFormatFailed
    case invalidConfiguration
    
    var localizedDescription: String {
        switch self {
        case .createProcessTapFailed(let status):
            return "System audio tap creation failed: \(status)"
        case .getStreamDescriptionFailed:
            return "Failed to get audio stream description"
        case .createAggregateDeviceFailed(let status):
            return "Failed to create aggregate device: \(status)"
        case .createDeviceIOProcFailed(let status):
            return "Failed to create device IO callback: \(status)"
        case .startAudioDeviceFailed(let status):
            return "Failed to start audio device: \(status)"
        case .tapNotAvailable:
            return "System audio data not available"
        case .streamFormatNotAvailable:
            return "Audio stream format not available"
        case .createAudioFormatFailed:
            return "Unable to create AVAudioFormat"
        case .invalidConfiguration:
            return "Invalid configuration parameters"
        }
    }
}

@Observable
final class SystemAudioTap {
    typealias InvalidationHandler = (SystemAudioTap) -> Void
    typealias AudioProcessingBlock = (_ inNow: UnsafePointer<AudioTimeStamp>, _ inInputData: UnsafePointer<AudioBufferList>, _ inInputTime: UnsafePointer<AudioTimeStamp>, _ outOutputData: UnsafeMutablePointer<AudioBufferList>, _ inOutputTime: UnsafePointer<AudioTimeStamp>) -> Void
    
    private(set) var errorMessage: String? = nil
    
    init() {}
    
    @ObservationIgnored
    fileprivate var processTapID: AudioObjectID = .unknown
    
    @ObservationIgnored
    fileprivate var aggregateDeviceID: AudioObjectID = .unknown
    
    @ObservationIgnored
    fileprivate var deviceProcID: AudioDeviceIOProcID?
    
    @ObservationIgnored
    private(set) var tapStreamDescription: AudioStreamBasicDescription?
    
    @ObservationIgnored
    private var invalidationHandler: InvalidationHandler?
    
    @ObservationIgnored
    private var processingBlock: AudioProcessingBlock?
    
    @ObservationIgnored
    private(set) var activated = false
    
    func activate() {
        guard !activated else { return }
        activated = true
        
        logger.info("Activating audio capture")
        
        self.errorMessage = nil
        
        do {
            try prepare()
        } catch {
            logger.error("Activation failed: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
        }
    }
    
    func invalidate() {
        guard activated else { return }
        defer { activated = false }
        
        invalidationHandler?(self)
        self.invalidationHandler = nil
        
        if aggregateDeviceID.isValid {
            var err = AudioDeviceStop(aggregateDeviceID, deviceProcID)
            if err != noErr { print("Failed to stop aggregate device: \(err)") }
            
            if let deviceProcID {
                err = AudioDeviceDestroyIOProcID(aggregateDeviceID, deviceProcID)
                if err != noErr { print("Failed to destroy device IO callback: \(err)") }
                self.deviceProcID = nil
            }
            
            err = AudioHardwareDestroyAggregateDevice(aggregateDeviceID)
            if err != noErr {
                print("Failed to destroy aggregate device: \(err)")
            }
            aggregateDeviceID = .unknown
        }
        
        if processTapID.isValid {
            let err = AudioHardwareDestroyProcessTap(processTapID)
            if err != noErr {
                print("Failed to destroy audio tap: \(err)")
            }
            processTapID = .unknown
        }
    }
    
    private func prepare() throws {
        errorMessage = nil
        
        let tapDescription = CATapDescription(stereoGlobalTapButExcludeProcesses: [])
        tapDescription.uuid = UUID()
        tapDescription.muteBehavior = .unmuted
        tapDescription.name = "AudioTap System Tap"
        tapDescription.isPrivate = true
        tapDescription.isExclusive = true
        
        var tapID = AudioObjectID.unknown
        var err = AudioHardwareCreateProcessTap(tapDescription, &tapID)
        
        guard err == noErr else {
            throw AudioCaptureError.createProcessTapFailed(err)
        }
        
        logger.info("Creating system audio tap: #\(tapID)")
        
        self.processTapID = tapID
        
        do {
            self.tapStreamDescription = try tapID.readAudioTapStreamBasicDescription()
        } catch {
            throw AudioCaptureError.getStreamDescriptionFailed
        }
        
        let tapUID = tapDescription.uuid.uuidString
        let tapConfig: [String: Any] = [
            kAudioSubTapUIDKey as String: tapUID,
            kAudioSubTapDriftCompensationKey as String: true
        ]
        
        let aggregateUID = UUID().uuidString
        let description: [String: Any] = [
            kAudioAggregateDeviceNameKey: "AudioCap System Audio Aggregate Device",
            kAudioAggregateDeviceUIDKey: aggregateUID,
            kAudioAggregateDeviceTapListKey: [tapConfig],
            kAudioAggregateDeviceTapAutoStartKey: false,
            kAudioAggregateDeviceIsPrivateKey: true
        ]
        
        self.aggregateDeviceID = AudioObjectID.unknown
        err = AudioHardwareCreateAggregateDevice(description as CFDictionary, &aggregateDeviceID)
        guard err == noErr else {
            throw AudioCaptureError.createAggregateDeviceFailed(err)
        }
        
        logger.info("Creating aggregate device: #\(self.aggregateDeviceID)")
        logger.info("System audio recording ready")
    }
    
    func run(with processingBlock: @escaping AudioProcessingBlock, invalidationHandler: @escaping InvalidationHandler) throws {
        assert(activated, "\(#function) called with inactive tap!")
        assert(self.invalidationHandler == nil, "\(#function) called with tap already active!")
        
        errorMessage = nil
        
        print("Starting system audio tap!")
        
        self.invalidationHandler = invalidationHandler
        self.processingBlock = processingBlock
        
        var err = AudioDeviceCreateIOProcIDWithBlock(&deviceProcID, aggregateDeviceID, nil) { [weak self] inNow, inInputData, inInputTime, outOutputData, inOutputTime in
            guard let self, let processingBlock = self.processingBlock else { return }
            processingBlock(inNow, inInputData, inInputTime, outOutputData, inOutputTime)
        }
        guard err == noErr else { throw AudioCaptureError.createDeviceIOProcFailed(err) }
        
        err = AudioDeviceStart(aggregateDeviceID, deviceProcID)
        guard err == noErr else { throw AudioCaptureError.startAudioDeviceFailed(err) }
    }
    
    deinit { invalidate() }
}

@Observable
final class SystemAudioRecorder {
    let fileURL: URL
    
    @ObservationIgnored
    private weak var _tap: SystemAudioTap?
    
    private(set) var isRecording = false
    
    private(set) var audioBuffer: [String] = []
    
    init(fileURL: URL, tap: SystemAudioTap) {
        self.fileURL = fileURL
        self._tap = tap
    }
    
    private var tap: SystemAudioTap {
        get throws {
            guard let _tap else { throw AudioCaptureError.tapNotAvailable }
            return _tap
        }
    }
    
    @ObservationIgnored
    private var audioFormat: AVAudioFormat?
    
    func start() throws {
        print("Starting recording")
        
        guard !isRecording else {
            print("Already recording")
            return
        }
        
        let tap = try tap
        
        if !tap.activated { tap.activate() }
        
        guard var streamDescription = tap.tapStreamDescription else {
            throw AudioCaptureError.streamFormatNotAvailable
        }
        
        let originalSampleRate = streamDescription.mSampleRate
        let originalChannels = streamDescription.mChannelsPerFrame
        
        print("Original audio format: Sample rate \(originalSampleRate)Hz, \(originalChannels) channels")
        
        if streamDescription.mSampleRate != globalConfig.sampleRate {
            print("Adjusting sample rate: \(streamDescription.mSampleRate) -> \(globalConfig.sampleRate)Hz")
            streamDescription.mSampleRate = globalConfig.sampleRate
        }
        
        if streamDescription.mChannelsPerFrame != globalConfig.channelCount {
            print("Adjusting channel count: \(streamDescription.mChannelsPerFrame) -> \(globalConfig.channelCount) channels")
            streamDescription.mChannelsPerFrame = globalConfig.channelCount
        }
        
        guard let format = AVAudioFormat(streamDescription: &streamDescription) else {
            print("Failed to create audio format")
            return
        }
        
        self.audioFormat = format
        
        print("Using audio format: \(format)")
        
        try tap.run(with: { [weak self] inNow, inInputData, inInputTime, outOutputData, inOutputTime in
            guard let self = self, let format = self.audioFormat else { return }
            
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, bufferListNoCopy: inInputData, deallocator: nil) else {
                print("Unable to create PCM buffer")
                return
            }
            self.audioBuffer.append(encodeBuffer(buffer))
        }, invalidationHandler: { [weak self] tap in
            guard let self else { return }
            handleInvalidation()
        })
        
        isRecording = true
    }
    
    func stop() {
        do {
            print(#function)
            
            guard isRecording else { return }
            
            isRecording = false
            
            try tap.invalidate()
        } catch {
            print("Stop failed: \(error)")
        }
    }
    
    private func handleInvalidation() {
        guard isRecording else { return }
        
        print(#function)
        print("Audio capture interrupted externally")
        isRecording = false
    }

    private func encodeBuffer(_ buffer: AVAudioPCMBuffer) -> String {
        let audioBuffer = buffer.audioBufferList.pointee.mBuffers
        
        if let audioDataReference = audioBuffer.mData {
            let bufferData = Data(bytes: audioDataReference,
                                count: Int(audioBuffer.mDataByteSize))
            
            return bufferData.base64EncodedString()
        }
        return ""
    }

    func getAudioData() -> [String]? {
        guard !self.audioBuffer.isEmpty else { 
            print("No audio data available")
            return [] 
        }
        
        let base64String = self.audioBuffer
        self.audioBuffer = []
        return base64String
    }
}

// Configuration function
func configureAudioCapture(config: AudioCaptureConfig) throws {
    guard config.sampleRate > 0 && config.channelCount > 0 else {
        throw AudioCaptureError.invalidConfiguration
    }
    
    globalConfig = config
} 
