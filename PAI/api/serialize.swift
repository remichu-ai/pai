import Foundation

func serialize<T: Encodable>(_ object: T) -> String? {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted  // Optional: makes the JSON easier to read
    do {
        let jsonData = try encoder.encode(object)
        return String(data: jsonData, encoding: .utf8)
    } catch {
        print("Failed to encode object: \(error)")
        return nil
    }
}
