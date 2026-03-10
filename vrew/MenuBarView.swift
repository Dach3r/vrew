import SwiftUI

struct MenuBarView: View {

    @ObservedObject var serviceManager: BrewServiceManager
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.top, 4)

            Divider()
                .opacity(0.3)
                .padding(.horizontal, 12)

            if serviceManager.isLoading && serviceManager.services.isEmpty {
                loadingView
            } else if serviceManager.services.isEmpty {
                emptyView
            } else {
                serviceListView
            }

            if let feedback = serviceManager.actionFeedback {
                feedbackBanner(message: feedback, isError: false)
            } else if let error = serviceManager.lastError {
                feedbackBanner(message: error, isError: true)
            }

            Divider()
                .opacity(0.3)
                .padding(.horizontal, 12)

            footerView
        }
        .frame(width: 320)
        .background(.clear)
        .onAppear { serviceManager.refresh() }
    }

    private var headerView: some View {
        HStack(spacing: 8) {
            Image(systemName: "mug.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.brown)

            Text("Vrew")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()

            let runningCount = serviceManager.services.filter { $0.status == .started }.count
            if runningCount > 0 {
                Text("\(runningCount) running")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.green.opacity(0.18))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
            }

            Button {
                serviceManager.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 26, height: 26)
                    .background(.primary.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(serviceManager.isLoading)
            .rotationEffect(serviceManager.isLoading ? .degrees(360) : .zero)
            .animation(
                serviceManager.isLoading
                    ? .linear(duration: 1).repeatForever(autoreverses: false)
                    : .default,
                value: serviceManager.isLoading
            )
            .help("Refresh")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var serviceListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(serviceManager.services) { service in
                    ServiceRowView(service: service, serviceManager: serviceManager)
                    if service != serviceManager.services.last {
                        Divider()
                            .opacity(0.25)
                            .padding(.leading, 42)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: 340)
    }

    private var loadingView: some View {
        VStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text("Loading services…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("No services found")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Make sure Homebrew is installed.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
    }

    private func feedbackBanner(message: String, isError: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(isError ? .orange : .green)
            Text(message)
                .font(.caption)
                .lineLimit(2)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isError ? Color.orange.opacity(0.08) : Color.green.opacity(0.08))
    }

    private var footerView: some View {
        HStack {
            Spacer()

            Button(action: onQuit) {
                Label("Quit", systemImage: "xmark.circle")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .help("Quit Vrew")
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        MenuBarView(serviceManager: {
            let m = BrewServiceManager()
            m.services = [
                BrewService(name: "postgresql@14", status: .started, user: "david"),
                BrewService(name: "redis",         status: .started, user: "david"),
                BrewService(name: "mysql",         status: .stopped),
                BrewService(name: "nginx",         status: .error),
            ]
            return m
        }(), onQuit: {})
    }
}
