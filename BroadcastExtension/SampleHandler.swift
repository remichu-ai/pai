//import LiveKit
//
//#if os(iOS)
//@available(macCatalyst 13.1, *)
//class SampleHandler: LKSampleHandler {
//    override var enableLogging: Bool { true }
//}
//#endif

import LiveKit

class SampleHandler: LKSampleHandler {
    // Enable logging to see broadcast state changes
    override var enableLogging: Bool { true }
    override var verboseLogging: Bool { true }
}
