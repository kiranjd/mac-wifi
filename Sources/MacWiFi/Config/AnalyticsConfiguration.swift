import Foundation

enum AnalyticsConfiguration {
    static let siteURL = URL(string: "https://macwifi.live")!
    static let checkoutURL = URL(string: "https://kiranjd8.lemonsqueezy.com/checkout/buy/dc36a9dc-bba2-46af-9426-f1c41120c477")!

    #if DEBUG
    static let ga4MeasurementId = "G-0DWSJTXQ65"
    static let ga4MeasurementAPISecret = "xUNJVjrRTLq-eiwjSHrCrA"
    #else
    static let ga4MeasurementId = "G-0DWSJTXQ65"
    static let ga4MeasurementAPISecret = "xUNJVjrRTLq-eiwjSHrCrA"
    #endif
}
