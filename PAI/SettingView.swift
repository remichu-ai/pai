import SwiftUI

struct SettingView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var serverUrl: String
    @Binding var authenticationUrl: String
    @Binding var sessionConfig: SessionConfig
    
    // Dictionary mapping language codes to full language names
    let languageDict: [String: String] = [
        "af": "Afrikaans",
        "am": "Amharic",
        "ar": "Arabic",
        "as": "Assamese",
        "az": "Azerbaijani",
        "ba": "Bashkir",
        "be": "Belarusian",
        "bg": "Bulgarian",
        "bn": "Bengali",
        "bo": "Tibetan",
        "br": "Breton",
        "bs": "Bosnian",
        "ca": "Catalan",
        "cs": "Czech",
        "cy": "Welsh",
        "da": "Danish",
        "de": "German",
        "el": "Greek",
        "en": "English",
        "es": "Spanish",
        "et": "Estonian",
        "eu": "Basque",
        "fa": "Persian",
        "fi": "Finnish",
        "fo": "Faroese",
        "fr": "French",
        "gl": "Galician",
        "gu": "Gujarati",
        "ha": "Hausa",
        "haw": "Hawaiian",
        "he": "Hebrew",
        "hi": "Hindi",
        "hr": "Croatian",
        "ht": "Haitian Creole",
        "hu": "Hungarian",
        "hy": "Armenian",
        "id": "Indonesian",
        "is": "Icelandic",
        "it": "Italian",
        "ja": "Japanese",
        "jw": "Javanese",
        "ka": "Georgian",
        "kk": "Kazakh",
        "km": "Khmer",
        "kn": "Kannada",
        "ko": "Korean",
        "la": "Latin",
        "lb": "Luxembourgish",
        "ln": "Lingala",
        "lo": "Lao",
        "lt": "Lithuanian",
        "lv": "Latvian",
        "mg": "Malagasy",
        "mi": "Māori",
        "mk": "Macedonian",
        "ml": "Malayalam",
        "mn": "Mongolian",
        "mr": "Marathi",
        "ms": "Malay",
        "mt": "Maltese",
        "my": "Burmese",
        "ne": "Nepali",
        "nl": "Dutch",
        "nn": "Norwegian Nynorsk",
        "no": "Norwegian",
        "oc": "Occitan",
        "pa": "Punjabi",
        "pl": "Polish",
        "ps": "Pashto",
        "pt": "Portuguese",
        "ro": "Romanian",
        "ru": "Russian",
        "sa": "Sanskrit",
        "sd": "Sindhi",
        "si": "Sinhala",
        "sk": "Slovak",
        "sl": "Slovenian",
        "sn": "Shona",
        "so": "Somali",
        "sq": "Albanian",
        "sr": "Serbian",
        "su": "Sundanese",
        "sv": "Swedish",
        "sw": "Swahili",
        "ta": "Tamil",
        "te": "Telugu",
        "tg": "Tajik",
        "th": "Thai",
        "tk": "Turkmen",
        "tl": "Tagalog",
        "tr": "Turkish",
        "tt": "Tatar",
        "uk": "Ukrainian",
        "ur": "Urdu",
        "uz": "Uzbek",
        "vi": "Vietnamese",
        "yi": "Yiddish",
        "yo": "Yoruba",
        "zh": "Chinese",
        "yue": "Cantonese",
        "auto": "Auto-detect"
    ]
    
    // Get language name from code
    func getLanguageName(for code: String) -> String {
        return languageDict[code] ?? code
    }
    
    // Get language code from name
    func getLanguageCode(for name: String) -> String? {
        return languageDict.first(where: { $0.value == name })?.key
    }
    
    // Check if auto-detect is enabled
    var isAutoDetectEnabled: Bool {
        return sessionConfig.turnDetection.language.contains("auto")
    }
    
    // Toggle auto detect
    func toggleAutoDetect(_ enable: Bool) {
        if enable {
            // Enable auto-detect by setting language to just ["auto"]
            sessionConfig.turnDetection.language = ["auto"]
        } else {
            // Disable auto-detect by setting default languages if no languages are selected
            if sessionConfig.turnDetection.language == ["auto"] {
                sessionConfig.turnDetection.language = ["en"] // Default languages
            } else {
                // Remove "auto" if it's in the mix with other languages
                sessionConfig.turnDetection.language.removeAll { $0 == "auto" }
            }
        }
    }
    var body: some View {
            NavigationView {
                Form {
                    
                    // SERVER URL
                    Section {
                        // Main Server
                        HStack {
                            Text("Main Server:")
                                .frame(width: 120, alignment: .leading)  // Adjust width as needed
                            TextField("http://100.123.119.59:7880", text: $serverUrl)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .keyboardType(.URL)
                        }
                        
                        // Authentication Server
                        HStack {
                            Text("Authentication:")
                                .frame(width: 120, alignment: .leading)
                            TextField("http://100.123.119.59:3111", text: $authenticationUrl)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .keyboardType(.URL)
                        }
                    } header: {
                        VStack(alignment: .leading) {
                            Text("Server URL")
                                .font(.headline)
                            Text("Connect to the server for processing your requests.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .textCase(nil)
                    
                    // TURN DETECTION
                    Section {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("Confidence Threshold")
                                Spacer()
                            }
                            Text("Higher values require more certainty to detect turns.")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Slider(value: $sessionConfig.turnDetection.threshold, in: 0.0...1.0, step: 0.1) {
                                Text("Threshold")
                            }
                            Text("Value: \(sessionConfig.turnDetection.threshold, specifier: "%.1f")")
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Prefix Padding (ms)")
                            Text("Amount of audio to keep before speech is detected.")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("Prefix Padding (ms)", value: $sessionConfig.turnDetection.prefixPaddingMs, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Silence Duration (ms)")
                            Text("Length of silence needed to consider speech complete.")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("Silence Duration (ms)", value: $sessionConfig.turnDetection.silenceDurationMs, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Toggle("Create Response", isOn: $sessionConfig.turnDetection.createResponse)
                            Text("Generate an AI response after detecting end of speech.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Toggle("Auto-detect Language", isOn: Binding(
                                get: { isAutoDetectEnabled },
                                set: { toggleAutoDetect($0) }
                            ))
                            Text("Automatically identify the language being spoken.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if !isAutoDetectEnabled {
                            NavigationLink(destination: LanguageSelectionView(
                                selectedLanguages: Binding(
                                    get: { sessionConfig.turnDetection.language },
                                    set: { sessionConfig.turnDetection.language = $0 }
                                ),
                                languageDict: languageDict.filter { $0.key != "auto" }
                            )) {
                                HStack {
                                    Text("Languages")
                                    Spacer()
                                    Text(
                                        sessionConfig.turnDetection.language
                                            .filter { $0 != "auto" }
                                            .compactMap { getLanguageName(for: $0) }
                                            .joined(separator: ", ")
                                    )
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Toggle("Factor Prefix Padding", isOn: $sessionConfig.turnDetection.factorPrefixPaddingInTruncate)
                            Text("Include prefix padding when processing audio.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } header: {
                        VStack(alignment: .leading) {
                            Text("Turn Detection")
                                .font(.headline)
                            Text("Turn detection determines when to stop recording and process your speech.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .textCase(nil)
                    
                    // SESSION CONFIG
                    Section {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Instructions")
                            Text("Guidance for how the AI should respond to you.")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("Instructions", text: $sessionConfig.instructions)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Voice")
                            Text("Voice used for audio responses.")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Picker("Voice", selection: Binding(
                                get: { sessionConfig.voice ?? "" },
                                set: { sessionConfig.voice = $0.isEmpty ? nil : $0 }
                            )) {
                                Text("None").tag("" as String?)
                                Text("af_heart").tag("af_heart")
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Model")
                            Text("AI model to use for responses. Leave blank for default.")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("Model", text: Binding(
                                get: { sessionConfig.model ?? "" },
                                set: { sessionConfig.model = $0.isEmpty ? nil : $0 }
                            ))
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Interrupt Token")
                            Text("Special token used in prompt to signal an interrupt by user.")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("Enter token", text: $sessionConfig.userInterruptToken)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Tool Instruction Position")
                            Text("Where tool instructions appear in prompts.")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Picker("", selection: $sessionConfig.toolInstructionPosition) {
                                Text("Prefix").tag("prefix")
                                Text("Postfix").tag("postfix")
                            }
                            .labelsHidden() // Hides the picker’s label so it won’t repeat
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Tool Schema Position")
                            Text("Where tool schemas appear in prompts.")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Picker("", selection: $sessionConfig.toolSchemaPosition) {
                                Text("Prefix").tag("prefix")
                                Text("Postfix").tag("postfix")
                            }
                        }
                    } header: {
                        VStack(alignment: .leading) {
                            Text("Session Config")
                                .font(.headline)
                            Text("Core settings that control how the AI interprets and responds.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .textCase(nil)
                    
                    // MODALITIES
                    Section {
                        VStack(alignment: .leading, spacing: 5) {
                            Toggle("Text", isOn: Binding(
                                get: { sessionConfig.modalities.contains("text") },
                                set: { isOn in
                                    if isOn {
                                        if !sessionConfig.modalities.contains("text") {
                                            sessionConfig.modalities.append("text")
                                        }
                                    } else {
                                        sessionConfig.modalities.removeAll { $0 == "text" }
                                    }
                                }
                            ))
                            Text("Enable text-based responses.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Toggle("Audio", isOn: Binding(
                                get: { sessionConfig.modalities.contains("audio") },
                                set: { isOn in
                                    if isOn {
                                        if !sessionConfig.modalities.contains("audio") {
                                            sessionConfig.modalities.append("audio")
                                        }
                                    } else {
                                        sessionConfig.modalities.removeAll { $0 == "audio" }
                                    }
                                }
                            ))
                            Text("Enable spoken responses.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } header: {
                        VStack(alignment: .leading) {
                            Text("Modalities")
                                .font(.headline)
                            Text("Ways the AI can communicate with you.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .textCase(nil)
                    
                    // TEMPERATURE
                    Section {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Higher values produce more varied responses.")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Slider(value: $sessionConfig.temperature, in: 0.1...1.2, step: 0.1) {
                                Text("Temperature")
                            }
                            Text("Value: \(sessionConfig.temperature, specifier: "%.1f")")
                        }
                    } header: {
                        VStack(alignment: .leading) {
                            Text("Temperature")
                                .font(.headline)
                            Text("Controls response creativity and randomness.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .textCase(nil)
                    
                    // MAX RESPONSE OUTPUT TOKENS
                    Section {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Set to 'inf' for unlimited length. Higher values allow longer responses.")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("Max Response Output Tokens", text: $sessionConfig.maxResponseOutputTokens)
                                .keyboardType(.numberPad)
                        }
                    } header: {
                        VStack(alignment: .leading) {
                            Text("Max Response Output Tokens")
                                .font(.headline)
                            Text("Limits the length of AI responses.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .textCase(nil)
                    
                    // TOOL CALL THINKING
                    Section {
                        VStack(alignment: .leading, spacing: 5) {
                            Toggle("Tool Call Thinking", isOn: $sessionConfig.toolCallThinking)
                            Text("Allow AI to use reasoning tools for better responses.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Thinking Token")
                            Text("Controls how much 'thinking' the AI can do before using a tool (higher = more thorough).")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("Tool Call Thinking Token", value: $sessionConfig.toolCallThinkingToken, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                        }
                    } header: {
                        VStack(alignment: .leading) {
                            Text("Tool Call Thinking")
                                .font(.headline)
                            Text("Enables AI to solve complex problems step-by-step.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .textCase(nil)
                    
                    // VIDEO STREAM
                    Section {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Higher resolution provides more detail but uses more data.")
                                .font(.caption)
                                .foregroundColor(.gray)
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
                    } header: {
                        VStack(alignment: .leading) {
                            Text("Video Stream")
                                .font(.headline)
                            Text("Configure video input settings.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .textCase(nil)
                }
                .navigationBarTitle("Settings", displayMode: .inline)
                .navigationBarItems(trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
}

// Language Selection View
struct LanguageSelectionView: View {
    @Binding var selectedLanguages: [String]
    let languageDict: [String: String]
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    
    // Sort languages by name for display
    var sortedLanguages: [(code: String, name: String)] {
        languageDict.sorted { $0.value < $1.value }
            .map { (code: $0.key, name: $0.value) }
    }
    
    // Filter languages based on search text
    var filteredLanguages: [(code: String, name: String)] {
        if searchText.isEmpty {
            return sortedLanguages
        } else {
            return sortedLanguages.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        VStack {
            // Search bar
            SearchBar(text: $searchText)
                .padding(.horizontal)
            
            List {
                ForEach(filteredLanguages, id: \.code) { language in
                    Button(action: {
                        if selectedLanguages.contains(language.code) {
                            selectedLanguages.removeAll { $0 == language.code }
                        } else {
                            selectedLanguages.append(language.code)
                        }
                    }) {
                        HStack {
                            Text(language.name)
                            Spacer()
                            if selectedLanguages.contains(language.code) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .navigationBarTitle("Select Languages", displayMode: .inline)
        .navigationBarItems(trailing: Button("Done") {
            presentationMode.wrappedValue.dismiss()
        })
    }
}

// SearchBar component
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search", text: $text)
                .disableAutocorrection(true)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

