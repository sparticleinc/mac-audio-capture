import Foundation
import AudioToolbox

// MARK: - Error Handling

enum CoreAudioError: Error, LocalizedError {
    case invalidPropertyData(AudioObjectPropertyAddress, OSStatus)
    case invalidPropertyDataSize(AudioObjectPropertyAddress, OSStatus)
    case invalidProcessIdentifier(pid_t)
    case requiresSystemObject
    
    var errorDescription: String? {
        switch self {
        case .invalidPropertyData(let address, let status):
            return "Error reading data for \(address): \(status)"
        case .invalidPropertyDataSize(let address, let status):
            return "Error reading data size for \(address): \(status)"
        case .invalidProcessIdentifier(let pid):
            return "Invalid process identifier: \(pid)"
        case .requiresSystemObject:
            return "Only supported for the system object."
        }
    }
}

// MARK: - Constants

extension AudioObjectID {
    /// Convenience for `kAudioObjectSystemObject`.
    static let system = AudioObjectID(kAudioObjectSystemObject)
    /// Convenience for `kAudioObjectUnknown`.
    static let unknown = kAudioObjectUnknown

    /// `true` if this object has the value of `kAudioObjectUnknown`.
    var isUnknown: Bool { self == .unknown }

    /// `false` if this object has the value of `kAudioObjectUnknown`.
    var isValid: Bool { !isUnknown }
}

// MARK: - Concrete Property Helpers

extension AudioObjectID {
    /// Reads the value for `kAudioHardwarePropertyDefaultSystemOutputDevice`.
    static func readDefaultSystemOutputDevice() throws -> AudioDeviceID {
        try AudioDeviceID.system.readDefaultSystemOutputDevice()
    }

    static func readProcessList() throws -> [AudioObjectID] {
        try AudioObjectID.system.readProcessList()
    }

    /// Reads `kAudioHardwarePropertyTranslatePIDToProcessObject` for the specific pid.
    static func translatePIDToProcessObjectID(pid: pid_t) throws -> AudioObjectID {
        try AudioDeviceID.system.translatePIDToProcessObjectID(pid: pid)
    }

    /// Reads `kAudioHardwarePropertyProcessObjectList`.
    func readProcessList() throws -> [AudioObjectID] {
        try requireSystemObject()

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyProcessObjectList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0

        var err = AudioObjectGetPropertyDataSize(self, &address, 0, nil, &dataSize)

        guard err == noErr else { throw CoreAudioError.invalidPropertyDataSize(address, err) }

        var value = [AudioObjectID](repeating: .unknown, count: Int(dataSize) / MemoryLayout<AudioObjectID>.size)

        err = AudioObjectGetPropertyData(self, &address, 0, nil, &dataSize, &value)

        guard err == noErr else { throw CoreAudioError.invalidPropertyData(address, err) }

        return value
    }

    /// Reads `kAudioHardwarePropertyTranslatePIDToProcessObject` for the specific pid, should only be called on the system object.
    func translatePIDToProcessObjectID(pid: pid_t) throws -> AudioObjectID {
        try requireSystemObject()

        let processObject = try read(
            kAudioHardwarePropertyTranslatePIDToProcessObject,
            defaultValue: AudioObjectID.unknown,
            qualifier: pid
        )

        guard processObject.isValid else {
            throw CoreAudioError.invalidProcessIdentifier(pid)
        }

        return processObject
    }

    func readProcessBundleID() -> String? {
        if let result = try? readString(kAudioProcessPropertyBundleID) {
            result.isEmpty ? nil : result
        } else {
            nil
        }
    }

    func readProcessIsRunning() -> Bool {
        (try? readBool(kAudioProcessPropertyIsRunning)) ?? false
    }

    /*
     public var kAudioProcessPropertyPID: AudioObjectPropertySelector { get }

     public var kAudioProcessPropertyBundleID: AudioObjectPropertySelector { get }

     public var kAudioProcessPropertyDevices: AudioObjectPropertySelector { get }

     public var kAudioProcessPropertyIsRunning: AudioObjectPropertySelector { get }

     public var kAudioProcessPropertyIsRunningInput: AudioObjectPropertySelector { get }

     public var kAudioProcessPropertyIsRunningOutput: AudioObjectPropertySelector { get }
     */

    /// Reads the value for `kAudioHardwarePropertyDefaultSystemOutputDevice`, should only be called on the system object.
    func readDefaultSystemOutputDevice() throws -> AudioDeviceID {
        try requireSystemObject()

        return try read(kAudioHardwarePropertyDefaultSystemOutputDevice, defaultValue: AudioDeviceID.unknown)
    }

    /// Reads the value for `kAudioDevicePropertyDeviceUID` for the device represented by this audio object ID.
    func readDeviceUID() throws -> String { try readString(kAudioDevicePropertyDeviceUID) }

    /// Reads the value for `kAudioTapPropertyFormat` for the device represented by this audio object ID.
    func readAudioTapStreamBasicDescription() throws -> AudioStreamBasicDescription {
        try read(kAudioTapPropertyFormat, defaultValue: AudioStreamBasicDescription())
    }

    private func requireSystemObject() throws {
        if self != .system { throw CoreAudioError.requiresSystemObject }
    }
}

// MARK: - Generic Property Access

extension AudioObjectID {
    func read<T, Q>(_ selector: AudioObjectPropertySelector,
                    scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
                    element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain,
                    defaultValue: T,
                    qualifier: Q) throws -> T
    {
        try read(AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element), defaultValue: defaultValue, qualifier: qualifier)
    }

    func read<T>(_ selector: AudioObjectPropertySelector,
                    scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
                    element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain,
                    defaultValue: T) throws -> T
    {
        try read(AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element), defaultValue: defaultValue)
    }

    func read<T, Q>(_ address: AudioObjectPropertyAddress, defaultValue: T, qualifier: Q) throws -> T {
        var inQualifier = qualifier
        let qualifierSize = UInt32(MemoryLayout<Q>.size(ofValue: qualifier))
        return try withUnsafeMutablePointer(to: &inQualifier) { qualifierPtr in
            try read(address, defaultValue: defaultValue, inQualifierSize: qualifierSize, inQualifierData: qualifierPtr)
        }
    }

    func read<T>(_ address: AudioObjectPropertyAddress, defaultValue: T) throws -> T {
        try read(address, defaultValue: defaultValue, inQualifierSize: 0, inQualifierData: nil)
    }

    func readString(_ selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal, element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain) throws -> String {
        try read(AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element), defaultValue: "" as CFString) as String
    }

    func readBool(_ selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal, element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain) throws -> Bool {
        let value: Int = try read(AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element), defaultValue: 0)
        return value == 1
    }

    private func read<T>(_ inAddress: AudioObjectPropertyAddress, defaultValue: T, inQualifierSize: UInt32 = 0, inQualifierData: UnsafeRawPointer? = nil) throws -> T {
        var address = inAddress

        var dataSize: UInt32 = 0

        var err = AudioObjectGetPropertyDataSize(self, &address, inQualifierSize, inQualifierData, &dataSize)

        guard err == noErr else {
            throw CoreAudioError.invalidPropertyDataSize(inAddress, err)
        }

        var value: T = defaultValue
        err = withUnsafeMutablePointer(to: &value) { ptr in
            AudioObjectGetPropertyData(self, &address, inQualifierSize, inQualifierData, &dataSize, ptr)
        }

        guard err == noErr else {
            throw CoreAudioError.invalidPropertyData(inAddress, err)
        }

        return value
    }
}

// MARK: - Debugging Helpers

private extension UInt32 {
    var fourCharString: String {
        String(cString: [
            UInt8((self >> 24) & 0xFF),
            UInt8((self >> 16) & 0xFF),
            UInt8((self >> 8) & 0xFF),
            UInt8(self & 0xFF),
            0
        ])
    }
}

extension AudioObjectPropertyAddress: @retroactive CustomStringConvertible {
    public var description: String {
        let elementDescription = mElement == kAudioObjectPropertyElementMain ? "main" : mElement.fourCharString
        return "\(mSelector.fourCharString)/\(mScope.fourCharString)/\(elementDescription)"
    }
}

extension URL {
    static var applicationSupport: URL {
        do {
            let appSupport = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let subdir = appSupport.appending(path: "AudioCap", directoryHint: .isDirectory)
            if !FileManager.default.fileExists(atPath: subdir.path) {
                try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)
            }
            return subdir
        } catch {
            assertionFailure("Failed to get application support directory: \(error)")

            return FileManager.default.temporaryDirectory
        }
    }
}

