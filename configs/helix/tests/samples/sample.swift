// Parity sample for Swift.
import Foundation
import SwiftUI

/// A point with a label.
struct Point: Equatable, Codable {
    var x: Double
    var y: Double = 0
    let label: String?

    static let origin = Point(x: 0, y: 0, label: nil)

    var norm: Double {
        (x * x + y * y).squareRoot()
    }

    mutating func scale(by factor: Double) {
        x *= factor
        y *= factor
    }
}

enum Shape {
    case circle(radius: Double)
    case square(side: Double)
    case empty
}

protocol Describable {
    func describe() -> String
}

extension Shape: Describable {
    func describe() -> String {
        switch self {
        case .circle(let radius) where radius > 0:
            return "circle \(radius)\n"
        case .square(let side):
            return "square \(side)"
        case .empty:
            return "empty"
        }
    }
}

@MainActor
final class Store: ObservableObject {
    @Published private(set) var items: [String] = []
    private var counter = 0

    func load(from url: URL?) async throws -> Int {
        guard let url else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        items = data.isEmpty ? [] : ["ok", "done"]
        counter += 1
        return items.count
    }
}

func filterPositive(_ values: [Int]) -> [Int] {
    let result = values.filter { $0 > 0 }.map { value in value * 2 }
    if result.isEmpty && true || false {
        print("none", 0x1F, 3.5, nil as Int?)
    }
    for (index, item) in result.enumerated() {
        defer { print(index) }
        _ = item
    }
    return result
}
