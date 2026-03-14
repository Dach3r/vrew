import SwiftUI

private enum ServiceFilter: String, CaseIterable {
    case all      = "All"
    case running  = "Running"
    case stopped  = "Stopped"
}

struct MenuBarView: View {

    @ObservedObject var serviceManager: BrewServiceManager
    let onQuit: () -> Void

    @State private var searchText: String = ""
    @State private var selectedTab: ServiceFilter = .all

    private var filteredServices: [BrewService] {
        let byTab: [BrewService]
        switch selectedTab {
        case .all:     byTab = serviceManager.services
        case .running: byTab = serviceManager.services.filter { $0.status == .started }
        case .stopped: byTab = serviceManager.services.filter { $0.status != .started }
        }
        if searchText.isEmpty { return byTab }
        return byTab.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private func count(for tab: ServiceFilter) -> Int {
        switch tab {
        case .all:     return serviceManager.services.count
        case .running: return serviceManager.services.filter { $0.status == .started }.count
        case .stopped: return serviceManager.services.filter { $0.status != .started }.count
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.top, 4)

            Divider()
                .opacity(0.3)
                .padding(.horizontal, 12)

            if !serviceManager.services.isEmpty {
                filterBar
            }

            if serviceManager.isLoading && serviceManager.services.isEmpty {
                loadingView
            } else if serviceManager.services.isEmpty {
                emptyView
            } else if filteredServices.isEmpty {
                noMatchesView
            } else {
                serviceListView
            }

            Spacer(minLength: 0)

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
        .frame(width: 320, height: 500)
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

    private var filterBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                TextField("Filter services…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 7))

            Picker("Filter", selection: $selectedTab) {
                ForEach(ServiceFilter.allCases, id: \.self) { tab in
                    Text("\(tab.rawValue) (\(count(for: tab)))")
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var serviceListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(filteredServices) { service in
                    ServiceRowView(service: service, serviceManager: serviceManager)
                    if service != filteredServices.last {
                        Divider()
                            .opacity(0.25)
                            .padding(.leading, 42)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .layoutPriority(1)
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

    private var noMatchesView: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("No matching services")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(height: 80)
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

    @State private var showQuitConfirmation = false

    private var footerView: some View {
        HStack {
            Spacer()

            Button {
                showQuitConfirmation = true
            } label: {
                Label("Quit", systemImage: "xmark.circle")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .help("Quit Vrew")
            .alert("Quit Vrew?", isPresented: $showQuitConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Quit", role: .destructive, action: onQuit)
            } message: {
                Text("Are you sure you want to quit Vrew?")
            }
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
