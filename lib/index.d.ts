import { EventEmitter } from 'events';

export interface AudioCaptureConfig {
    sampleRate?: number;
    channelCount?: number;
    logPath?: string;
}

export interface CaptureOptions {
    interval?: number;
}

export interface WavHeaderOptions {
    sampleRate: number;
    numChannels: number;
    bitDepth: number;
    dataLength: number;
}

export declare class AudioCapture extends EventEmitter {
    constructor(options?: AudioCaptureConfig);
    
    config: AudioCaptureConfig;
    isRecording: boolean;
    audioBuffer: string[];
    isConfigured: boolean;
    
    configure(options?: AudioCaptureConfig): Promise<boolean>;
    startCapture(options?: CaptureOptions): Promise<void>;
    stopCapture(): Promise<void>;
    getAudioData(): string[];
    clearBuffer(): void;
    saveToWav(outputPath: string, audioData?: string[]): Promise<string>;
    record(durationMs?: number, outputPath?: string): Promise<string>;
    
    // 事件
    on(event: 'configured', listener: (config: AudioCaptureConfig) => void): this;
    on(event: 'started', listener: () => void): this;
    on(event: 'stopped', listener: (audioBuffer: string[]) => void): this;
    on(event: 'data', listener: (data: string[]) => void): this;
    on(event: 'saved', listener: (filePath: string) => void): this;
    on(event: 'error', listener: (error: Error) => void): this;
    
    emit(event: 'configured', config: AudioCaptureConfig): boolean;
    emit(event: 'started'): boolean;
    emit(event: 'stopped', audioBuffer: string[]): boolean;
    emit(event: 'data', data: string[]): boolean;
    emit(event: 'saved', filePath: string): boolean;
    emit(event: 'error', error: Error): boolean;
}

export default AudioCapture; 