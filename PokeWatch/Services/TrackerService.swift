import Foundation

protocol TrackerServicing {
    func fetchEntries() async throws -> [StockEntry]
}

struct TrackerService: TrackerServicing {
    var trackerURL: URL = URL(string: "https://s3.amazonaws.com/nowinstock.net/modules/trackers/us/1466v2.html")!

    func fetchEntries() async throws -> [StockEntry] {
        var request = URLRequest(url: trackerURL)
        request.setValue("https://www.nowinstock.net/", forHTTPHeaderField: "Referer")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw TrackerServiceError.badResponse
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw TrackerServiceError.unreadablePayload
        }

        return parse(html: html)
    }

    // MARK: - Parsing

    private func parse(html: String) -> [StockEntry] {
        // nowinstock trackers are simple HTML tables. We avoid heavy dependencies and parse with regular expressions.
        // The parser is intentionally flexible to tolerate class name or column order changes.
        let rowPattern = try? NSRegularExpression(pattern: "<tr[^>]*>(.*?)</tr>", options: [.caseInsensitive, .dotMatchesLineSeparators])
        let cellPattern = try? NSRegularExpression(pattern: "<t[dh]([^>]*)>(.*?)</t[dh]>", options: [.caseInsensitive, .dotMatchesLineSeparators])

        guard let rowPattern, let cellPattern else { return [] }

        let tableRows = matches(for: rowPattern, in: html)
            .filter { !$0.lowercased().contains("<th") } // ignore header rows

        return tableRows.compactMap { rowHTML in
            let cells = matchCells(for: cellPattern, in: rowHTML)
            guard !cells.isEmpty else { return nil }

            let storeText = cleanHTML(cells.first?.innerHTML ?? "")
            let statusCell = cells.dropFirst().first
            let statusText = cleanHTML(statusCell?.innerHTML ?? "")
            let statusClass = statusCell?.attributes ?? ""
            let lastUpdatedText = cleanHTML(cells.dropFirst(2).first?.innerHTML ?? "")
            let link = extractFirstLink(from: rowHTML)

            let status = StockStatus(rawText: statusText, cssClass: statusClass)
            let change = lastUpdatedText.isEmpty ? nil : lastUpdatedText

            return StockEntry(store: storeText, status: status, productURL: link, lastChangeText: change)
        }
    }

    private func matches(for regex: NSRegularExpression, in string: String) -> [String] {
        let range = NSRange(string.startIndex..<string.endIndex, in: string)
        return regex.matches(in: string, options: [], range: range).compactMap { result in
            guard result.numberOfRanges > 1, let range = Range(result.range(at: 1), in: string) else { return nil }
            return String(string[range])
        }
    }

    private struct Cell {
        let attributes: String
        let innerHTML: String
    }

    private func matchCells(for regex: NSRegularExpression, in string: String) -> [Cell] {
        let range = NSRange(string.startIndex..<string.endIndex, in: string)
        return regex.matches(in: string, options: [], range: range).compactMap { result in
            guard result.numberOfRanges > 2,
                  let attributesRange = Range(result.range(at: 1), in: string),
                  let innerRange = Range(result.range(at: 2), in: string) else {
                return nil
            }
            return Cell(attributes: String(string[attributesRange]), innerHTML: String(string[innerRange]))
        }
    }

    private func cleanHTML(_ html: String) -> String {
        var text = html.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        return text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func extractFirstLink(from html: String) -> URL? {
        let pattern = "href\\=\\\"([^\\\"]+)\\\""
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..<html.endIndex, in: html)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: html) else {
            return nil
        }

        let urlString = String(html[range])
        return URL(string: urlString)
    }
}

enum TrackerServiceError: Error {
    case badResponse
    case unreadablePayload
}
