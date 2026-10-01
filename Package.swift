// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "KnowledgeCore", platforms: [.macOS("27.0")], products: [.library(name: "KnowledgeCore", targets: ["KnowledgeCore"])], targets: [.target(name: "KnowledgeCore", path: "Sources/Core"), .testTarget(name: "KnowledgeCoreTests", dependencies: ["KnowledgeCore"], path: "Tests/Core")])
