import SwiftUI

/// 3x3 grid overlay for selecting exposure metering zone
/// Appears over the camera preview when toggled on
struct MeteringGridOverlay: View {
    @Binding var selectedZone: MeteringZone
    let onZoneSelected: (MeteringZone) -> Void

    var body: some View {
        GeometryReader { geo in
            let cellWidth = geo.size.width / 3
            let cellHeight = geo.size.height / 3

            ZStack {
                // Grid lines
                GridLines()

                // Tappable zone cells
                VStack(spacing: 0) {
                    ForEach(0..<3) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<3) { col in
                                let zone = zoneFor(row: row, col: col)
                                ZoneCell(
                                    zone: zone,
                                    isSelected: selectedZone == zone,
                                    width: cellWidth,
                                    height: cellHeight
                                ) {
                                    selectedZone = zone
                                    onZoneSelected(zone)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /// Get MeteringZone for grid position
    private func zoneFor(row: Int, col: Int) -> MeteringZone {
        let index = row * 3 + col + 1
        return MeteringZone(rawValue: index) ?? .center
    }
}

/// Grid lines drawn between cells
struct GridLines: View {
    var body: some View {
        GeometryReader { geo in
            let thirdWidth = geo.size.width / 3
            let thirdHeight = geo.size.height / 3

            Path { path in
                // Vertical lines
                path.move(to: CGPoint(x: thirdWidth, y: 0))
                path.addLine(to: CGPoint(x: thirdWidth, y: geo.size.height))

                path.move(to: CGPoint(x: thirdWidth * 2, y: 0))
                path.addLine(to: CGPoint(x: thirdWidth * 2, y: geo.size.height))

                // Horizontal lines
                path.move(to: CGPoint(x: 0, y: thirdHeight))
                path.addLine(to: CGPoint(x: geo.size.width, y: thirdHeight))

                path.move(to: CGPoint(x: 0, y: thirdHeight * 2))
                path.addLine(to: CGPoint(x: geo.size.width, y: thirdHeight * 2))
            }
            .stroke(Color.white.opacity(0.4), lineWidth: 1)
        }
    }
}

/// Individual tappable zone cell
struct ZoneCell: View {
    let zone: MeteringZone
    let isSelected: Bool
    let width: CGFloat
    let height: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Selection highlight
                if isSelected {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.15))
                        .padding(4)

                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white, lineWidth: 2)
                        .padding(4)
                }

                // Zone indicator (subtle, only shown when selected)
                if isSelected {
                    Text(zone.shortLabel)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: width, height: height)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        MeteringGridOverlay(
            selectedZone: .constant(.center),
            onZoneSelected: { _ in }
        )
        .padding(40)
    }
}
