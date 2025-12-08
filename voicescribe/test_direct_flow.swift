import Foundation

// Test direct file usage
let token = "mock_jwt_token"

print("Testing direct file functionality...")

// Read the corrected file
if let path = "/Users/adriantucicovenco/Proiecte/voicescribe/elixir_voicescribe_backend/lib/elixir_whisper_flow_backend/transcription/transcribe_gen_server_fixed.ex",
   let data = try? Data(contentsOf: path) {
    print("Successfully read file with \(data.count) bytes")
        
        // Start Docker container
        let process = Process()
        let pipe = Pipe()
        
        // Set up docker command
        dockerTask.arguments = [
            "compose", "up", "-d",
            "--build"
        ]
        dockerTask.standardOutput = pipe
        dockerTask.standardInput = nil
        
        do {
            try process.run(dockerTask)
            print("Docker container started successfully")
        } catch {
            print("Failed to start Docker container: \(error)")
        }
    } else {
    print("Failed to read file: \(error)")
    }

exit(0)
