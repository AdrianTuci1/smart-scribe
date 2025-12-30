// AudioWorkletProcessor to handle audio processing on a separate thread
// This avoids main thread blocking and issues with ScriptProcessorNode

interface AudioWorkletProcessor {
    readonly port: MessagePort;
    process(inputs: Float32Array[][], outputs: Float32Array[][], parameters: Record<string, Float32Array>): boolean;
}

declare var AudioWorkletProcessor: {
    prototype: AudioWorkletProcessor;
    new(options?: any): AudioWorkletProcessor;
};

declare function registerProcessor(name: string, processorCtor: (new (options?: any) => AudioWorkletProcessor)): void;

class AudioProcessor extends AudioWorkletProcessor {
    private _bufferSize: number;
    private _buffer: Float32Array;
    private _initBuffer: boolean;

    constructor() {
        super();
        this._bufferSize = 4096;
        this._buffer = new Float32Array(this._bufferSize);
        this._initBuffer = true;
    }

    process(inputs: Float32Array[][], outputs: Float32Array[][], parameters: Record<string, Float32Array>): boolean {
        const input = inputs[0];
        const output = outputs[0];

        // If no input, keep processor alive
        if (!input || !input.length) return true;

        const inputChannel = input[0];

        // Post the raw float32 buffer to the main thread for processing (downsampling)
        // We could move downsampling here, but typically AudioWorklet should just pass data
        // efficiently. However, to fully offload, we should implement downsampling here.
        // For now, mirroring previous behavior: pass data to main thread, but doing it via port
        // is much more efficient than ScriptProcessor.

        // Better approach matching "ScriptProcessor" replacement:
        // Just forward the buffer. The main thread logic handles downsampling.
        // However, AudioWorklet chunks are 128 frames. ScriptProcessor was 4096.
        // We should buffer 4096 frames here then send.

        // Note: 'this.port.postMessage' transfers data.

        // Simple buffering implementation to match previous buffer size likely expected by main thread logic
        // or just send what we have. 128 frames is small (2.9ms at 44.1kHz).
        // Let's send raw 128 frames and let Main Thread accumulate?
        // Or accumulate here. Accumulating here reduces messaging overhead.

        // Let's implement accumulation to 4096 frames before sending, similar to ScriptProcessor
        // But actually, we can just send the raw inputChannel which is 128 samples.
        // The Main Service downsampler logic 'downsampleBuffer' iterates over input.
        // It maintains state 'offsetResult' etc? No, the previous `downsampleBuffer` was stateless (linear interpolation of whole buffer).
        // If we pass small chunks, the linear interpolation might have artifacts at boundaries if not careful.
        // But for 16khz speech, simple decimation is usually "okay".
        // A better approach is to perform downsampling HERE in the worklet if possible.

        // Given the constraints and the previous stateless implementation:
        // We will buffer here to create larger chunks similar to ScriptProcessor to minimize boundary artifacts
        // and message overhead.

        // Actually, looking at the previous 'downsampleBuffer', it calculates 'newLength' based on input buffer length.
        // It resets offsetResult/offsetBuffer each call. This implies it treats each buffer as standalone.
        // So passing 128 length buffers will work, just more frequently.
        // Let's just pass the data through.

        // Check if we need to copy to avoid detachment issues if transfer list is used?
        // AudioWorklet inputs are reused. We must copy if we want to send it.
        const chunk = new Float32Array(inputChannel);
        this.port.postMessage({ event: 'audio_chunk', data: chunk }, [chunk.buffer]);

        return true; // Keep processor alive
    }
}

registerProcessor('audio-processor', AudioProcessor);
