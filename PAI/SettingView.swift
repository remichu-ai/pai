import SwiftUI

struct SettingView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var serverUrl: String
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
                sessionConfig.turnDetection.language = ["en", "vi"] // Default languages
            } else {
                // Remove "auto" if it's in the mix with other languages
                sessionConfig.turnDetection.language.removeAll { $0 == "auto" }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
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
                    
                    // Language auto-detection toggle
                    Toggle("Auto-detect Language", isOn: Binding(
                        get: { isAutoDetectEnabled },
                        set: { toggleAutoDetect($0) }
                    ))
                    
                    // Language selection (shown only if auto-detect is off)
                    if !isAutoDetectEnabled {
                        NavigationLink(destination: LanguageSelectionView(
                            selectedLanguages: Binding(
                                get: { sessionConfig.turnDetection.language },
                                set: { sessionConfig.turnDetection.language = $0 }
                            ),
                            languageDict: languageDict.filter { $0.key != "auto" } // Filter out auto from selection
                        )) {
                            HStack {
                                Text("Languages")
                                Spacer()
                                Text(sessionConfig.turnDetection.language
                                    .filter { $0 != "auto" }
                                    .compactMap { getLanguageName(for: $0) }
                                    .joined(separator: ", "))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        }
                    }
                    
                    Toggle("Factor Prefix Padding", isOn: $sessionConfig.turnDetection.factorPrefixPaddingInTruncate)
                }
                
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
                        Text("af_heart").tag("af_heart")
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
                    
                    HStack {
                        // Label on the left
                        Text("Interrupt Token:")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        // Text input box on the right
                        TextField("Enter token", text: $sessionConfig.userInterruptToken)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.default)
                    }
                    
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
                    // Toggle for "text" modality
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
                    
                    // Toggle for "audio" modality
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
                
                
                Section(header: Text("Tool Call Thinking")) {
                    Toggle("Tool Call Thinking", isOn: $sessionConfig.toolCallThinking)
                    TextField("Tool Call Thinking Token", value: $sessionConfig.toolCallThinkingToken, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                }
                
                
                Section(header: Text("Video Stream")) {
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
