import SwiftUI
import UIKit
import LiveKit

enum GlobalSelectionMode: String, CaseIterable {
    case custom = "Custom"
    case enableAll = "Enable All"
    case disableAll = "Disable All"
}

struct ToolSettingView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var room: Room
    @Binding var tools: [String]
    
    // Initially nil – once the tools are fetched, we set it.
    @State private var availableTools: [String]? = nil
    @State private var selectedTools: Set<String> = []
    @State private var customSelectedTools: Set<String> = []
    
    @State private var globalSelectionMode: GlobalSelectionMode = .custom
    
    var body: some View {
        NavigationView {
            Group {
                if let availableTools = availableTools {
                    Form {
                        Section(header: Text("Global Selection")) {
                            Picker("Selection Mode", selection: $globalSelectionMode) {
                                ForEach(GlobalSelectionMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .onChange(of: globalSelectionMode) { newValue in
                                switch newValue {
                                case .enableAll:
                                    selectedTools = Set(availableTools)
                                case .disableAll:
                                    selectedTools = []
                                case .custom:
                                    selectedTools = customSelectedTools
                                }
                            }
                        }
                        
                        Section(header: Text("Available Tools")) {
                            ForEach(availableTools, id: \.self) { tool in
                                Toggle(isOn: bindingForTool(tool)) {
                                    Text(tool)
                                }
                                .disabled(globalSelectionMode != .custom)
                            }
                        }
                    }
                } else {
                    // While waiting for the tools to load, show a loading indicator.
                    ProgressView("Loading tools...")
                }
            }
            .navigationBarTitle("Tool Settings", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                Task {
                    do {
                        let result = try await setToolList(room: room, toolList: Array(selectedTools))
                        switch result {
                        case .success(let message):
                            print("Tool list set successfully: \(message)")
                            tools = Array(selectedTools)
                            presentationMode.wrappedValue.dismiss()
                        case .failure(let error):
                            print("Failed to set tool list: \(error)")
                        }
                    } catch {
                        print("Error setting tool list: \(error)")
                    }
                }
            })
            .task {
                // Fetch the available tools as early as possible.
                do {
                    let fetched = try await getToolList(room: room)
                    availableTools = fetched.allTools
                    // Initialize the custom and selected tools with the active tools from the backend.
                    customSelectedTools = Set(fetched.activeTools)
                    selectedTools = customSelectedTools
                } catch {
                    print("Failed to fetch tools: \(error)")
                }
            }
        }
    }
    
    private func bindingForTool(_ tool: String) -> Binding<Bool> {
        Binding<Bool>(
            get: { selectedTools.contains(tool) },
            set: { newValue in
                if globalSelectionMode == .custom {
                    if newValue {
                        selectedTools.insert(tool)
                    } else {
                        selectedTools.remove(tool)
                    }
                    customSelectedTools = selectedTools
                }
            }
        )
    }
}
