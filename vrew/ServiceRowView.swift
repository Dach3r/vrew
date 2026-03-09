import SwiftUI

struct ServiceRowView: View {

    let service: BrewService
    @ObservedObject var serviceManager: BrewServiceManager

    @State private var isHovered = false
    @State private var actionInFlight = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(service.status.color.opacity(0.15))
                    .frame(width: 24, height: 24)
                Image(systemName: service.status.systemImage)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(service.status.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(service.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(statusSubtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer()

            if isHovered || actionInFlight {
                actionButtons
                    .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .trailing)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.primary.opacity(0.06) : Color.clear)
                .padding(.horizontal, 6)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .disabled(actionInFlight || serviceManager.isLoading)
        .opacity(actionInFlight ? 0.55 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: actionInFlight)
    }

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 6) {
            switch service.status {
            case .started:
                iconButton(icon: "stop.fill",       color: .red,   help: "Stop")    { perform { self.serviceManager.stop(self.service) } }
                iconButton(icon: "arrow.clockwise", color: .blue,  help: "Restart") { perform { self.serviceManager.restart(self.service) } }
            case .stopped, .unknown:
                iconButton(icon: "play.fill",       color: .green, help: "Start")   { perform { self.serviceManager.start(self.service) } }
            case .error:
                iconButton(icon: "arrow.clockwise", color: .blue,  help: "Restart") { perform { self.serviceManager.restart(self.service) } }
                iconButton(icon: "stop.fill",       color: .red,   help: "Stop")    { perform { self.serviceManager.stop(self.service) } }
            }
        }
    }

    private func iconButton(icon: String, color: Color, help tooltip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.14))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .help("\(tooltip) \(service.name)")
    }

    private var statusSubtitle: String {
        var parts: [String] = [service.status.label]
        if !service.user.isEmpty { parts.append("(\(service.user))") }
        return parts.joined(separator: " ")
    }

    private func perform(_ block: @escaping () -> Void) {
        withAnimation { actionInFlight = true }
        block()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { actionInFlight = false }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()
        VStack(spacing: 0) {
            let mgr = BrewServiceManager()
            ServiceRowView(service: BrewService(name: "postgresql@14", status: .started, user: "david"), serviceManager: mgr)
            Divider().opacity(0.3).padding(.leading, 42)
            ServiceRowView(service: BrewService(name: "redis",         status: .started, user: "david"), serviceManager: mgr)
            Divider().opacity(0.3).padding(.leading, 42)
            ServiceRowView(service: BrewService(name: "mysql",         status: .stopped),                serviceManager: mgr)
            Divider().opacity(0.3).padding(.leading, 42)
            ServiceRowView(service: BrewService(name: "nginx",         status: .error),                  serviceManager: mgr)
        }
        .frame(width: 320)
    }
}
