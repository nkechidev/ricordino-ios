import Foundation

// Exists purely so NoteRepositoryTests can inject a fake — EntityDetectionService itself
// isn't designed to change, so production code only ever uses the concrete type directly.
protocol EntityDetecting {
    func detect(in text: String) async -> [DetectedEntity]
}

struct EntityDetectionService: EntityDetecting {
    func detect(in text: String) async -> [DetectedEntity] {
        guard !text.isEmpty else { return [] }

        let types: NSTextCheckingResult.CheckingType = [.date, .phoneNumber, .address]
        guard let detector = try? NSDataDetector(types: types.rawValue) else { return [] }

        let nsText = text as NSString
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))

        return matches.compactMap { match -> DetectedEntity? in
            let matchedText = nsText.substring(with: match.range)
            guard isPlausible(matchedText, match: match, in: nsText) else { return nil }

            switch match.resultType {
            case .date:
                return DetectedEntity(kind: .date, text: matchedText)
            case .phoneNumber:
                return DetectedEntity(kind: .phoneNumber, text: matchedText)
            case .address:
                return DetectedEntity(kind: .address, text: matchedText)
            default:
                return nil
            }
        }
    }

    // NSDataDetector has no confidence score (unlike ML Kit's TextClassifier), so false
    // positives on dense numeric/technical text (ingredient percentages, measurements) —
    // e.g. "0.4%" on a product label misread as a date fragment — need shape-based filtering
    // instead of a threshold.
    private func isPlausible(_ matchedText: String, match: NSTextCheckingResult, in nsText: NSString) -> Bool {
        guard matchedText.count >= Self.minimumMatchLength else { return false }

        let nextCharRange = NSRange(location: match.range.location + match.range.length, length: 1)
        if nextCharRange.location < nsText.length, nsText.substring(with: nextCharRange) == "%" {
            return false
        }

        if match.resultType == .date {
            let hasSeparator = matchedText.contains { "/-,".contains($0) }
            let hasMonthOrWeekday = Self.monthAndWeekdayNames.contains {
                matchedText.localizedCaseInsensitiveContains($0)
            }
            guard hasSeparator || hasMonthOrWeekday else { return false }
        }

        return true
    }

    private static let minimumMatchLength = 6
    private static let monthAndWeekdayNames = [
        "january", "february", "march", "april", "may", "june", "july",
        "august", "september", "october", "november", "december",
        "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
    ]
}
