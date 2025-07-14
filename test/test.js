const MacAudioCapture = require('../lib/index');
const fs = require('fs');
const path = require('path');

class AudioCaptureTest {
    constructor() {
        this.testResults = [];
        this.capture = null;
    }

    async runAllTests() {
        console.log('🧪 Starting Audio Capture Tests');
        console.log('===============================');
        
        try {
            await this.testConfiguration();
            await this.testInstanceCreation();
            await this.testEventEmitters();
            await this.testAudioProcessing();
            await this.testErrorHandling();
            
            this.printResults();
        } catch (error) {
            console.error('❌ Test execution failed:', error.message);
        }
    }

    async testConfiguration() {
        console.log('\n📋 Test 1: Configuration');
        
        try {
            this.capture = new MacAudioCapture({
                sampleRate: 44100,
                channelCount: 1,
                logPath: './test/test.log'
            });
            
            const result = await this.capture.configure({
                sampleRate: 48000,
                channelCount: 2
            });
            
            this.assert(result === true, 'Configuration should succeed');
            this.assert(this.capture.config.sampleRate === 48000, 'Sample rate should be set correctly');
            this.assert(this.capture.config.channelCount === 2, 'Channel count should be set correctly');
            this.assert(this.capture.isConfigured === true, 'Configuration status should be true');
            
            console.log('✅ Configuration test passed');
        } catch (error) {
            this.fail('Configuration test failed: ' + error.message);
        }
    }

    async testInstanceCreation() {
        console.log('\n📋 Test 2: Instance Creation');
        
        try {
            const capture1 = new MacAudioCapture();
            this.assert(capture1.isRecording === false, 'New instance should not be recording');
            this.assert(capture1.audioBuffer.length === 0, 'Audio buffer should be empty');
            this.assert(capture1.isConfigured === false, 'New instance should not be configured');
            
            const capture2 = new MacAudioCapture({
                sampleRate: 22050,
                channelCount: 1
            });
            this.assert(capture2.config.sampleRate === 22050, 'Constructor should accept configuration');
            this.assert(capture2.config.channelCount === 1, 'Constructor should set channel count');
            
            console.log('✅ Instance creation test passed');
        } catch (error) {
            this.fail('Instance creation test failed: ' + error.message);
        }
    }

    async testEventEmitters() {
        console.log('\n📋 Test 3: Event Emitters');
        
        try {
            const capture = new MacAudioCapture();
            let eventCount = 0;
            
            capture.on('configured', () => eventCount++);
            capture.on('started', () => eventCount++);
            capture.on('stopped', () => eventCount++);
            capture.on('error', () => eventCount++);
            
            await capture.configure();
            this.assert(eventCount === 1, 'configured event should be triggered');
            
            console.log('✅ Event emitters test passed');
        } catch (error) {
            this.fail('Event emitters test failed: ' + error.message);
        }
    }

    async testAudioProcessing() {
        console.log('\n📋 Test 4: Audio Data Processing');
        
        try {
            const capture = new MacAudioCapture();
            
            // Test empty data processing
            const emptyData = capture.getAudioData();
            this.assert(Array.isArray(emptyData), 'getAudioData should return array');
            this.assert(emptyData.length === 0, 'Empty buffer should return empty array');
            
            // Test buffer clearing
            capture.clearBuffer();
            this.assert(capture.audioBuffer.length === 0, 'clearBuffer should clear buffer');
            
            console.log('✅ Audio data processing test passed');
        } catch (error) {
            this.fail('Audio data processing test failed: ' + error.message);
        }
    }

    async testErrorHandling() {
        console.log('\n📋 Test 5: Error Handling');
        
        try {
            const capture = new MacAudioCapture();
            
            // Test duplicate stop
            try {
                await capture.stopCapture();
                this.fail('Should throw error when not recording');
            } catch (error) {
                this.assert(error.message.includes('No audio capture in progress'), 'Should throw correct error message');
            }
            
            // Test duplicate start
            await capture.startCapture();
            try {
                await capture.startCapture();
                this.fail('Should throw error when already recording');
            } catch (error) {
                this.assert(error.message.includes('Audio capture is already running'), 'Should throw correct error message');
            }
            
            await capture.stopCapture();
            console.log('✅ Error handling test passed');
        } catch (error) {
            this.fail('Error handling test failed: ' + error.message);
        }
    }

    assert(condition, message) {
        if (!condition) {
            this.fail(message);
        } else {
            this.pass(message);
        }
    }

    pass(message) {
        this.testResults.push({ status: 'PASS', message });
    }

    fail(message) {
        this.testResults.push({ status: 'FAIL', message });
        console.error(`❌ ${message}`);
    }

    printResults() {
        console.log('\n📊 Test Results Summary');
        console.log('=======================');
        
        const passed = this.testResults.filter(r => r.status === 'PASS').length;
        const failed = this.testResults.filter(r => r.status === 'FAIL').length;
        const total = this.testResults.length;
        
        console.log(`✅ Passed: ${passed}`);
        console.log(`❌ Failed: ${failed}`);
        console.log(`📊 Total: ${total}`);
        
        if (failed === 0) {
            console.log('\n🎉 All tests passed!');
        } else {
            console.log('\n⚠️  Some tests failed, please check the error messages above');
        }
    }
}

// Run tests
if (require.main === module) {
    const test = new AudioCaptureTest();
    test.runAllTests().catch(console.error);
}

module.exports = AudioCaptureTest; 