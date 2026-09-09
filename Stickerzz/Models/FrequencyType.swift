enum FrequencyType: String, CaseIterable {
    case daily
    case weekly
    case specificDays

    var label: String {
        switch self {
        case .daily: "Daily"
        case .weekly: "Times per week"
        case .specificDays: "Specific days"
        }
    }
}
