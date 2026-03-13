import Foundation

struct CSVRow: Identifiable {
    let id = UUID()
    let values: [String]
}

struct CSVColumnMapping {
    var dateColumn: Int?
    var typeColumn: Int?
    var nameColumn: Int?
    var isinColumn: Int?
    var quantityColumn: Int?
    var priceColumn: Int?
    var amountColumn: Int?
    var currencyColumn: Int?
    var symbolColumn: Int?
}

struct ParsedCSVHolding: Identifiable {
    var id = UUID()
    var date: Date?
    var type: String
    var name: String
    var isin: String
    var symbol: String
    var quantity: Double
    var price: Double
    var amount: Double
    var currency: String
}

struct CSVImportService {

    static func parseCSV(from url: URL) throws -> (headers: [String], rows: [CSVRow]) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let content = try String(contentsOf: url, encoding: .utf8)
        return parseCSVString(content)
    }

    static func parseCSVString(_ content: String) -> (headers: [String], rows: [CSVRow]) {
        let lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard let headerLine = lines.first else {
            return ([], [])
        }

        let separator = detectSeparator(in: headerLine)
        let headers = parseLine(headerLine, separator: separator)

        var rows: [CSVRow] = []
        for line in lines.dropFirst() {
            let values = parseLine(line, separator: separator)
            if !values.isEmpty {
                rows.append(CSVRow(values: values))
            }
        }

        return (headers, rows)
    }

    static func detectSeparator(in line: String) -> Character {
        let semicolonCount = line.filter { $0 == ";" }.count
        let commaCount = line.filter { $0 == "," }.count
        let tabCount = line.filter { $0 == "\t" }.count

        if semicolonCount >= commaCount && semicolonCount >= tabCount {
            return ";"
        } else if tabCount >= commaCount {
            return "\t"
        }
        return ","
    }

    static func parseLine(_ line: String, separator: Character) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == separator && !inQuotes {
                fields.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current.trimmingCharacters(in: .whitespaces))

        return fields
    }

    static func detectTradeRepublicFormat(headers: [String]) -> CSVColumnMapping? {
        let normalizedHeaders = headers.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }

        let expectedHeaders = ["date", "type", "asset", "isin", "quantity", "price", "amount", "currency"]

        let matchCount = expectedHeaders.filter { expected in
            normalizedHeaders.contains { $0.contains(expected) }
        }.count

        guard matchCount >= 5 else { return nil }

        var mapping = CSVColumnMapping()

        for (index, header) in normalizedHeaders.enumerated() {
            if header.contains("date") || header.contains("datum") {
                mapping.dateColumn = index
            } else if header.contains("type") || header.contains("typ") || header.contains("art") {
                mapping.typeColumn = index
            } else if header.contains("asset") || header.contains("name") || header.contains("wertpapier") {
                mapping.nameColumn = index
            } else if header.contains("isin") {
                mapping.isinColumn = index
            } else if header.contains("quantity") || header.contains("anzahl") || header.contains("stück") {
                mapping.quantityColumn = index
            } else if header.contains("price") || header.contains("preis") || header.contains("kurs") {
                mapping.priceColumn = index
            } else if header.contains("amount") || header.contains("betrag") || header.contains("summe") {
                mapping.amountColumn = index
            } else if header.contains("currency") || header.contains("währung") {
                mapping.currencyColumn = index
            }
        }

        return mapping
    }

    static func autoDetectMapping(headers: [String]) -> CSVColumnMapping {
        if let tradeRepublic = detectTradeRepublicFormat(headers: headers) {
            return tradeRepublic
        }

        var mapping = CSVColumnMapping()
        let normalizedHeaders = headers.map { $0.lowercased() }

        for (index, header) in normalizedHeaders.enumerated() {
            if header.contains("date") || header.contains("datum") || header.contains("time") {
                if mapping.dateColumn == nil { mapping.dateColumn = index }
            }
            if header.contains("type") || header.contains("action") || header.contains("art") {
                if mapping.typeColumn == nil { mapping.typeColumn = index }
            }
            if header.contains("name") || header.contains("asset") || header.contains("description") ||
               header.contains("instrument") || header.contains("security") {
                if mapping.nameColumn == nil { mapping.nameColumn = index }
            }
            if header.contains("isin") {
                if mapping.isinColumn == nil { mapping.isinColumn = index }
            }
            if header.contains("symbol") || header.contains("ticker") {
                if mapping.symbolColumn == nil { mapping.symbolColumn = index }
            }
            if header.contains("quantity") || header.contains("qty") || header.contains("shares") ||
               header.contains("units") || header.contains("amount") && !header.contains("total") {
                if mapping.quantityColumn == nil { mapping.quantityColumn = index }
            }
            if header.contains("price") || header.contains("rate") || header.contains("kurs") {
                if mapping.priceColumn == nil { mapping.priceColumn = index }
            }
            if header.contains("total") || header.contains("value") || header.contains("betrag") {
                if mapping.amountColumn == nil { mapping.amountColumn = index }
            }
            if header.contains("currency") || header.contains("ccy") {
                if mapping.currencyColumn == nil { mapping.currencyColumn = index }
            }
        }

        return mapping
    }

    static func applyMapping(rows: [CSVRow], mapping: CSVColumnMapping) -> [ParsedCSVHolding] {
        var holdings: [ParsedCSVHolding] = []

        let dateFormatters: [DateFormatter] = {
            let formats = ["yyyy-MM-dd", "dd.MM.yyyy", "MM/dd/yyyy", "dd/MM/yyyy",
                           "yyyy-MM-dd'T'HH:mm:ss", "dd.MM.yyyy HH:mm"]
            return formats.map { format in
                let formatter = DateFormatter()
                formatter.dateFormat = format
                formatter.locale = Locale(identifier: "en_US_POSIX")
                return formatter
            }
        }()

        for row in rows {
            let values = row.values

            func safeGet(_ index: Int?) -> String {
                guard let idx = index, idx < values.count else { return "" }
                return values[idx]
            }

            let dateString = safeGet(mapping.dateColumn)
            var parsedDate: Date? = nil
            for formatter in dateFormatters {
                if let date = formatter.date(from: dateString) {
                    parsedDate = date
                    break
                }
            }

            let quantityString = safeGet(mapping.quantityColumn)
                .replacingOccurrences(of: ",", with: ".")
                .replacingOccurrences(of: " ", with: "")
            let priceString = safeGet(mapping.priceColumn)
                .replacingOccurrences(of: ",", with: ".")
                .replacingOccurrences(of: " ", with: "")
            let amountString = safeGet(mapping.amountColumn)
                .replacingOccurrences(of: ",", with: ".")
                .replacingOccurrences(of: " ", with: "")

            let holding = ParsedCSVHolding(
                date: parsedDate,
                type: safeGet(mapping.typeColumn),
                name: safeGet(mapping.nameColumn),
                isin: safeGet(mapping.isinColumn),
                symbol: safeGet(mapping.symbolColumn),
                quantity: abs(Double(quantityString) ?? 0),
                price: abs(Double(priceString) ?? 0),
                amount: abs(Double(amountString) ?? 0),
                currency: safeGet(mapping.currencyColumn).isEmpty ? "EUR" : safeGet(mapping.currencyColumn)
            )

            if !holding.name.isEmpty || !holding.isin.isEmpty {
                holdings.append(holding)
            }
        }

        return holdings
    }

    static func aggregateHoldings(_ holdings: [ParsedCSVHolding]) -> [ParsedCSVHolding] {
        var aggregated: [String: ParsedCSVHolding] = [:]

        for holding in holdings {
            let key = holding.isin.isEmpty ? holding.name : holding.isin

            if var existing = aggregated[key] {
                let isBuy = holding.type.lowercased().contains("buy") ||
                            holding.type.lowercased().contains("kauf") ||
                            holding.type.isEmpty

                if isBuy {
                    existing.quantity += holding.quantity
                } else {
                    existing.quantity -= holding.quantity
                }

                if holding.price > 0 {
                    existing.price = holding.price
                }

                aggregated[key] = existing
            } else {
                aggregated[key] = holding
            }
        }

        return Array(aggregated.values).filter { $0.quantity > 0 }
    }
}
