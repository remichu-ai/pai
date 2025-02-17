import SwiftUI

struct SettingView: View {
    @Binding var serverUrl: String
    @Binding var sessionConfig: SessionConfig
    
    var body: some View {
        Form {
            Section(header: Text("Server URL")) {
                TextField("Server URL", text: $serverUrl)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
            }
            
            Section(header: Text("Session Config")) {
                TextField("Instructions", text: $sessionConfig.instructions)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Picker("Voice", selection: Binding(
                    get: { sessionConfig.voice ?? "" },
                    set: { sessionConfig.voice = $0.isEmpty ? nil : $0 }
                )) {
                    Text("None").tag("" as String?)
                    Text("Voice 1").tag("voice1")
                    Text("Voice 2").tag("voice2")
                }
                
                Picker("Input Audio Format", selection: Binding(
                    get: { sessionConfig.inputAudioFormat ?? "" },
                    set: { sessionConfig.inputAudioFormat = $0.isEmpty ? nil : $0 }
                )) {
                    Text("None").tag("" as String?)
                    Text("Format 1").tag("format1")
                    Text("Format 2").tag("format2")
                }
                
                Picker("Output Audio Format", selection: Binding(
                    get: { sessionConfig.outputAudioFormat ?? "" },
                    set: { sessionConfig.outputAudioFormat = $0.isEmpty ? nil : $0 }
                )) {
                    Text("None").tag("" as String?)
                    Text("Format 1").tag("format1")
                    Text("Format 2").tag("format2")
                }
                
                TextField("Model", text: Binding(
                    get: { sessionConfig.model ?? "" },
                    set: { sessionConfig.model = $0.isEmpty ? nil : $0 }
                ))
                
                TextField("User Interrupt Token", text: $sessionConfig.userInterruptToken)
                
                Picker("Tool Instruction Position", selection: $sessionConfig.toolInstructionPosition) {
                    Text("Prefix").tag("prefix")
                    Text("Postfix").tag("postfix")
                }
                
                Picker("Tool Schema Position", selection: $sessionConfig.toolSchemaPosition) {
                    Text("Prefix").tag("prefix")
                    Text("Postfix").tag("postfix")
                }
            }
            
            Section(header: Text("Modalities")) {
                ForEach($sessionConfig.modalities, id: \.self) { $modality in
                    Picker("Modality", selection: $modality) {
                        Text("Text").tag("text")
                        Text("Audio").tag("audio")
                    }
                }
                Button("Add Modality") {
                    sessionConfig.modalities.append("text")
                }
            }
            
            Section(header: Text("Tools")) {
                ForEach($sessionConfig.tools, id: \.self) { $tool in
                    TextField("Tool", text: $tool)
                }
                Button("Add Tool") {
                    sessionConfig.tools.append("")
                }
            }
            
            Section(header: Text("Tool Choice")) {
                Picker("Tool Choice", selection: $sessionConfig.toolChoice) {
                    Text("Auto").tag("auto")
                    Text("Tool 1").tag("tool1")
                    Text("Tool 2").tag("tool2")
                }
            }
            
            Section(header: Text("Temperature")) {
                Slider(value: $sessionConfig.temperature, in: 0.1...1.2, step: 0.1) {
                    Text("Temperature")
                }
                Text("Value: \(sessionConfig.temperature, specifier: "%.1f")")
            }
            
            Section(header: Text("Max Response Output Tokens")) {
                TextField("Max Response Output Tokens", text: $sessionConfig.maxResponseOutputTokens)
                    .keyboardType(.numberPad)
            }
            
            Section(header: Text("Streaming Transcription")) {
                Toggle("Streaming Transcription", isOn: $sessionConfig.streamingTranscription)
            }
            
            Section(header: Text("Sample Rates")) {
                TextField("Input Sample Rate", value: $sessionConfig.inputSampleRate, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                TextField("Output Sample Rate", value: $sessionConfig.outputSampleRate, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
            }
            
            Section(header: Text("Tool Call Thinking")) {
                Toggle("Tool Call Thinking", isOn: $sessionConfig.toolCallThinking)
                TextField("Tool Call Thinking Token", value: $sessionConfig.toolCallThinkingToken, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
            }
            
            Section(header: Text("Turn Detection")) {
                Slider(value: $sessionConfig.turnDetection.threshold, in: 0.0...1.0, step: 0.1) {
                    Text("Threshold")
                }
                Text("Value: \(sessionConfig.turnDetection.threshold, specifier: "%.1f")")
                
                TextField("Prefix Padding (ms)", value: $sessionConfig.turnDetection.prefixPaddingMs, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                TextField("Silence Duration (ms)", value: $sessionConfig.turnDetection.silenceDurationMs, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                Toggle("Create Response", isOn: $sessionConfig.turnDetection.createResponse)
            }
            
            Section(header: Text("Video Stream")) {
                Toggle("Video Stream", isOn: $sessionConfig.video.videoStream)
                Picker("Max Resolution", selection: $sessionConfig.video.videoMaxResolution) {
                    Text("240p").tag("240p")
                    Text("360p").tag("360p")
                    Text("480p").tag("480p")
                    Text("540p").tag("540p")
                    Text("720p").tag("720p")
                    Text("900p").tag("900p")
                    Text("1080p").tag("1080p")
                    Text("None").tag(nil as String?)
                }
            }
        }
    }
}

// Preview Provider
struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        // Use a constant binding for the preview
        SettingView(
            serverUrl: .constant("https://10.10.10.10:3111"),
            sessionConfig: .constant(SessionConfig())
        )
    }
}
