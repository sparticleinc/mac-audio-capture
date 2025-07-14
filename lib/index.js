const { configure, startCapture, stopCapture, getAudioData } = require('../.build/release/audio.node');
const fs = require('fs');
const path = require('path');
const { EventEmitter } = require('events');

/**
 * Mac System Audio Capture
 * Uses Swift and CoreAudio technology to capture Mac system audio streams
 */
class AudioCapture extends EventEmitter {
    constructor(options = {}) {
        super();
        
        this.config = {
            sampleRate: 48000,
            channelCount: 2,
            logPath: path.join(process.cwd(), 'audio_capture.log'),
            ...options
        };
        
        this.isRecording = false;
        this.audioBuffer = [];
        this.captureInterval = null;
        this.isConfigured = false;
    }

    /**
     * Configure audio capture
     * @param {Object} options Configuration options
     * @returns {Promise<boolean>} Whether configuration was successful
     */
    async configure(options = {}) {
        try {
            const mergedConfig = { ...this.config, ...options };
            
            // Ensure log directory exists
            const logDir = path.dirname(mergedConfig.logPath);
            if (!fs.existsSync(logDir)) {
                fs.mkdirSync(logDir, { recursive: true });
            }
            
            configure(mergedConfig);
            this.config = mergedConfig;
            this.isConfigured = true;
            
            this.emit('configured', mergedConfig);
            return true;
        } catch (error) {
            this.emit('error', new Error(`Configuration failed: ${error.message}`));
            return false;
        }
    }

    /**
     * Start audio capture
     * @param {Object} options Capture options
     * @returns {Promise<void>}
     */
    async startCapture(options = {}) {
        if (!this.isConfigured) {
            await this.configure();
        }
        
        if (this.isRecording) {
            throw new Error('Audio capture is already running');
        }

        try {
            startCapture();
            this.isRecording = true;
            this.audioBuffer = [];
            
            // Start periodic audio data collection
            this.captureInterval = setInterval(() => {
                try {
                    const data = getAudioData();
                    if (data && data.length > 0) {
                        this.audioBuffer.push(...data);
                        this.emit('data', data);
                    }
                } catch (error) {
                    this.emit('error', new Error(`Failed to get audio data: ${error.message}`));
                }
            }, options.interval || 200);
            
            this.emit('started');
        } catch (error) {
            this.emit('error', new Error(`Failed to start capture: ${error.message}`));
            throw error;
        }
    }

    /**
     * Stop audio capture
     * @returns {Promise<void>}
     */
    async stopCapture() {
        if (!this.isRecording) {
            throw new Error('No audio capture in progress');
        }

        try {
            if (this.captureInterval) {
                clearInterval(this.captureInterval);
                this.captureInterval = null;
            }
            
            stopCapture();
            this.isRecording = false;
            
            this.emit('stopped', this.audioBuffer);
        } catch (error) {
            this.emit('error', new Error(`Failed to stop capture: ${error.message}`));
            throw error;
        }
    }

    /**
     * Get current audio data
     * @returns {Array<string>} Base64 encoded audio data array
     */
    getAudioData() {
        return [...this.audioBuffer];
    }

    /**
     * Clear audio buffer
     */
    clearBuffer() {
        this.audioBuffer = [];
    }

    /**
     * Save audio data as WAV file
     * @param {string} outputPath Output file path
     * @param {Array<string>} audioData Audio data (optional, defaults to current buffer)
     * @returns {Promise<string>} Saved file path
     */
    async saveToWav(outputPath, audioData = null) {
        const data = audioData || this.audioBuffer;
        
        if (!data || data.length === 0) {
            throw new Error('No audio data to save');
        }

        try {
            const float32Array = this._base64StringsToFloat32Array(data);
            const int16Array = this._float32ToInt16(float32Array);
            const wavHeader = this._createWavHeader({
                sampleRate: this.config.sampleRate,
                numChannels: this.config.channelCount,
                bitDepth: 16,
                dataLength: int16Array.length * 2,
            });

            const wavData = Buffer.concat([
                wavHeader,
                Buffer.from(int16Array.buffer),
            ]);

            // Ensure output directory exists
            const outputDir = path.dirname(outputPath);
            if (!fs.existsSync(outputDir)) {
                fs.mkdirSync(outputDir, { recursive: true });
            }

            fs.writeFileSync(outputPath, wavData);
            this.emit('saved', outputPath);
            return outputPath;
        } catch (error) {
            this.emit('error', new Error(`Failed to save WAV file: ${error.message}`));
            throw error;
        }
    }

    /**
     * Record audio for specified duration
     * @param {number} durationMs Recording duration (milliseconds)
     * @param {string} outputPath Output file path
     * @returns {Promise<string>} Saved file path
     */
    async record(durationMs = 5000, outputPath = 'output.wav') {
        return new Promise(async (resolve, reject) => {
            try {
                await this.startCapture();
                
                setTimeout(async () => {
                    try {
                        await this.stopCapture();
                        const filePath = await this.saveToWav(outputPath);
                        resolve(filePath);
                    } catch (error) {
                        reject(error);
                    }
                }, durationMs);
            } catch (error) {
                reject(error);
            }
        });
    }

    // Private methods
    _base64StringsToFloat32Array(base64Strings) {
        if (!Array.isArray(base64Strings) || base64Strings.length === 0) {
            throw new Error('Invalid audio data');
        }

        const buffers = base64Strings.map(str => {
            if (typeof str !== 'string') {
                throw new Error('Invalid Base64 string');
            }
            return Buffer.from(str, 'base64');
        });
        
        const mergedBuffer = Buffer.concat(buffers);

        if (mergedBuffer.length % 4 !== 0) {
            throw new Error('Data length is not a multiple of Float32');
        }

        return new Float32Array(mergedBuffer.buffer);
    }

    _float32ToInt16(float32Array) {
        const int16Array = new Int16Array(float32Array.length);
        for (let i = 0; i < float32Array.length; i++) {
            int16Array[i] = Math.max(-32768, Math.min(32767, float32Array[i] * 32767));
        }
        return int16Array;
    }

    _createWavHeader(options) {
        const { sampleRate, numChannels, bitDepth, dataLength } = options;
        const byteRate = (sampleRate * numChannels * bitDepth) / 8;
        const blockAlign = (numChannels * bitDepth) / 8;
        const buffer = Buffer.alloc(44);

        buffer.write('RIFF', 0);
        buffer.writeUInt32LE(36 + dataLength, 4);
        buffer.write('WAVE', 8);
        buffer.write('fmt ', 12);
        buffer.writeUInt32LE(16, 16);
        buffer.writeUInt16LE(1, 20);
        buffer.writeUInt16LE(numChannels, 22);
        buffer.writeUInt32LE(sampleRate, 24);
        buffer.writeUInt32LE(byteRate, 28);
        buffer.writeUInt16LE(blockAlign, 32);
        buffer.writeUInt16LE(bitDepth, 34);
        buffer.write('data', 36);
        buffer.writeUInt32LE(dataLength, 40);

        return buffer;
    }
}

module.exports = AudioCapture; 