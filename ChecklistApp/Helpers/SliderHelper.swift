import Foundation

func sliderLabel(for value: Double) -> String {
    switch value {
    case 0.0: return "0/8"
    case 0.125: return "1/8"
    case 0.25: return "1/4"
    case 0.375: return "3/8"
    case 0.5: return "1/2"
    case 0.625: return "5/8"
    case 0.75: return "3/4"
    case 0.875: return "7/8"
    case 1.0: return "8/8"
    default: return ""
    }
}
