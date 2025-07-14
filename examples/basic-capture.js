const AudioCapture = require('../lib');

async function basicCaptureExample() {
    console.log('🎵 Mac System Audio Capture Example');
    console.log('===================================');
    
    // Create audio capture instance
    const capture = new AudioCapture({
        sampleRate: 48000,
        channelCount: 2,
        logPath: './logs/audio_capture.log'
    });
    
    // Listen to events
    capture.on('configured', (config) => {
        console.log('✅ Configuration completed:', config);
    });
    
    capture.on('started', () => {
        console.log('🎙️  Starting audio capture...');
    });
    
    capture.on('data', (data) => {
        console.log(`📊 Received ${data.length} audio data segments`);
    });
    
    capture.on('stopped', (audioBuffer) => {
        console.log(`🛑 Capture stopped, collected ${audioBuffer.length} audio segments`);
    });
    
    capture.on('saved', (filePath) => {
        console.log(`💾 Audio file saved: ${filePath}`);
    });
    
    capture.on('error', (error) => {
        console.error('❌ Error:', error.message);
    });
    
    try {
        // Method 1: Simple recording
        console.log('\n📝 Method 1: Simple 5-second recording');
        const filePath = await capture.record(5000, 'examples/output-1.wav');
        console.log(`✅ Recording completed: ${filePath}`);
        
        // Method 2: Manual control recording
        console.log('\n📝 Method 2: Manual control recording');
        await capture.startCapture({ interval: 100 });
        
        // Record for 3 seconds
        await new Promise(resolve => setTimeout(resolve, 3000));
        
        await capture.stopCapture();
        const filePath2 = await capture.saveToWav('examples/output-2.wav');
        console.log(`✅ Manual recording completed: ${filePath2}`);
        
        // Method 3: Real-time audio data processing
        console.log('\n📝 Method 3: Real-time audio data processing');
        await capture.startCapture({ interval: 50 });
        
        let dataCount = 0;
        capture.on('data', (data) => {
            dataCount += data.length;
            console.log(`📊 Real-time data: Total ${dataCount} segments`);
        });
        
        // Record for 2 seconds
        await new Promise(resolve => setTimeout(resolve, 2000));
        await capture.stopCapture();
        
        console.log('\n🎉 All examples completed!');
        
    } catch (error) {
        console.error('❌ Example execution failed:', error.message);
    }
}

// Run example
if (require.main === module) {
    basicCaptureExample().catch(console.error);
}

module.exports = basicCaptureExample; 