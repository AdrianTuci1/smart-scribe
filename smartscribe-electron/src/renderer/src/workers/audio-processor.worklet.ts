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
    private _chunkSize: number;
    private _buffer: Float32Array;
    private _bytesWritten: number;

    constructor() {
        super();
        this._chunkSize = 4096;
        this._buffer = new Float32Array(this._chunkSize);
        this._bytesWritten = 0;
    }

    process(inputs: Float32Array[][], outputs: Float32Array[][], parameters: Record<string, Float32Array>): boolean {
        const input = inputs[0];

        // If no input, keep processor alive
        if (!input || !input.length) return true;

        const inputChannel = input[0];

        // Append to buffer
        // Note: We assume inputChannel.length (usually 128) fits into remaining buffer space
        // because 4096 is a multiple of 128.
        if (this._bytesWritten + inputChannel.length <= this._chunkSize) {
            this._buffer.set(inputChannel, this._bytesWritten);
            this._bytesWritten += inputChannel.length;
        } else {
            // Handle edge case where it might overflow (unlikely with standard web audio API)
            const remaining = this._chunkSize - this._bytesWritten;
            this._buffer.set(inputChannel.subarray(0, remaining), this._bytesWritten);

            // Send full buffer
            this.flush();

            // Start new buffer with rest
            const rest = inputChannel.subarray(remaining);
            this._buffer.set(rest, 0);
            this._bytesWritten = rest.length;
        }

        // Check if full
        if (this._bytesWritten >= this._chunkSize) {
            this.flush();
        }

        return true; // Keep processor alive
    }

    private flush() {
        // Send chunk to main thread
        // We must slice/copy because the buffer is reused
        const chunk = this._buffer.slice(0, this._chunkSize);
        this.port.postMessage({ event: 'audio_chunk', data: chunk }, [chunk.buffer]);
        this._bytesWritten = 0;
    }
}

registerProcessor('audio-processor', AudioProcessor);
