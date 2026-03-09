import Foundation
import Combine

enum ActionResult {
    case success(String)
    case failure(String)
}

@MainActor
final class BrewServiceManager: ObservableObject {

    @Published var services: [BrewService] = []
    @Published var isLoading: Bool = false
    @Published var lastError: String? = nil
    @Published var actionFeedback: String? = nil

    private var brewPath: String {
        let paths = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
        return paths.first { FileManager.default.fileExists(atPath: $0) } ?? "/opt/homebrew/bin/brew"
    }

    func refresh() {
        isLoading = true
        lastError = nil

        Task {
            let result = await runBrewCommand(args: ["services", "list"])
            switch result {
            case .success(let output):
                self.services = parseServices(from: output)
            case .failure(let err):
                self.lastError = err
            }
            self.isLoading = false
        }
    }

    func start(_ service: BrewService) {
        runAction("start", on: service)
    }

    func stop(_ service: BrewService) {
        runAction("stop", on: service)
    }

    func restart(_ service: BrewService) {
        runAction("restart", on: service)
    }

    private func runAction(_ action: String, on service: BrewService) {
        isLoading = true
        actionFeedback = nil

        Task {
            let result = await runBrewCommand(args: ["services", action, service.name])
            switch result {
            case .success:
                self.actionFeedback = "\(service.name) \(action)ed ✓"
                try? await Task.sleep(nanoseconds: 600_000_000)
                self.refresh()
            case .failure(let err):
                self.lastError = err
                self.isLoading = false
            }
        }
    }

    private func runBrewCommand(args: [String]) async -> ActionResult {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self else { return }

                let process = Process()
                process.executableURL = URL(fileURLWithPath: self.brewPath)
                process.arguments = args

                var env = ProcessInfo.processInfo.environment
                env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
                process.environment = env

                let outPipe = Pipe()
                let errPipe = Pipe()
                process.standardOutput = outPipe
                process.standardError  = errPipe

                do {
                    try process.run()
                    process.waitUntilExit()

                    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
                    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                    let output  = String(data: outData, encoding: .utf8) ?? ""
                    let errOut  = String(data: errData, encoding: .utf8) ?? ""

                    if process.terminationStatus == 0 {
                        continuation.resume(returning: .success(output))
                    } else {
                        let message = errOut.isEmpty ? "Unknown error (exit \(process.terminationStatus))" : errOut
                        continuation.resume(returning: .failure(message))
                    }
                } catch {
                    continuation.resume(returning: .failure(error.localizedDescription))
                }
            }
        }
    }

    private func parseServices(from output: String) -> [BrewService] {
        let lines = output.components(separatedBy: "\n")
        return lines
            .dropFirst() // skip header row
            .compactMap { BrewService(rawLine: $0) }
            .sorted {
                if $0.status == $1.status { return $0.name < $1.name }
                if $0.status == .started  { return true  }
                if $1.status == .started  { return false }
                return $0.name < $1.name
            }
    }
}
