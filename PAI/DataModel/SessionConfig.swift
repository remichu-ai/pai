import Foundation

struct SessionConfig: Codable {
    var modalities: [String] = ["text", "audio"]
    var instructions: String = ""
    var voice: String?
    var inputAudioFormat: String?
    var outputAudioFormat: String?
    var inputAudioTranscription: String?
    var turnDetection: TurnDetectionConfig = TurnDetectionConfig()
    var tools: [String] = []
    var toolChoice: String = "auto"
    var temperature: Double = 0.4
    var maxResponseOutputTokens: String = "inf"
    var video: VideoStreamSetting = VideoStreamSetting()
    var model: String?
    var streamingTranscription: Bool = true
    var userInterruptToken: String = " <user_interrupt>"
    var inputSampleRate: Int = 24000
    var outputSampleRate: Int = 24000
    var toolCallThinking: Bool = true
    var toolCallThinkingToken: Int = 200
    var toolInstructionPosition: String = "prefix"
    var toolSchemaPosition: String = "prefix"
    
    enum CodingKeys: String, CodingKey {
        case modalities
        case instructions
        case voice
        case inputAudioFormat = "input_audio_format"
        case outputAudioFormat = "output_audio_format"
        case inputAudioTranscription = "input_audio_transcription"
        case turnDetection = "turn_detection"
        case tools
        case toolChoice = "tool_choice"
        case temperature
        case maxResponseOutputTokens = "max_response_output_tokens"
        case video
        case model
        case streamingTranscription = "streaming_transcription"
        case userInterruptToken = "user_interrupt_token"
        case inputSampleRate = "input_sample_rate"
        case outputSampleRate = "output_sample_rate"
        case toolCallThinking = "tool_call_thinking"
        case toolCallThinkingToken = "tool_call_thinking_token"
        case toolInstructionPosition = "tool_instruction_position"
        case toolSchemaPosition = "tool_schema_position"
    }
}
