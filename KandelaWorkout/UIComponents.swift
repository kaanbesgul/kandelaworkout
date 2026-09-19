import SwiftUI

// MARK: - Card

private struct CardBackground: ViewModifier {
    let padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 6)
    }
}

extension View {
    func cardStyle(padding: CGFloat = 18) -> some View {
        modifier(CardBackground(padding: padding))
    }
}

// MARK: - Region badge

struct RegionBadge: View {
    let region: MuscleGroup?
    var size: CGFloat = 46

    var body: some View {
        ZStack {
            if let region {
                Circle()
                    .fill(region.tint.gradient)
                    .shadow(color: region.tint.opacity(0.35), radius: 6, x: 0, y: 3)
                Image(systemName: region.icon)
                    .font(.system(size: size * 0.40, weight: .semibold))
                    .foregroundStyle(.white)
            } else {
                Circle()
                    .strokeBorder(
                        Color.secondary.opacity(0.35),
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                    )
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: size * 0.34, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Step header

struct StepHeader: View {
    let number: Int
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Text("\(number)")
                .font(.caption2.weight(.heavy))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.accentColor.gradient))
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Stats

struct StatTile: View {
    let value: String
    let label: String
    var tint: Color = .accentColor

    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(tint)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MetricPill: View {
    let icon: String
    let text: String
    var tint: Color = .secondary

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(tint.opacity(0.13)))
    }
}

// MARK: - Program tag

struct ProgramTag: View {
    let program: WorkoutProgram

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: program.icon)
                .font(.system(size: 9, weight: .bold))
            Text(program.rawValue)
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Capsule().fill(program.tint.gradient))
    }
}

// MARK: - Picker chip

struct PickerChip: View {
    let title: String
    let isPlaceholder: Bool
    var tint: Color = .accentColor

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .lineLimit(1)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isPlaceholder ? Color.secondary : tint)

            Spacer(minLength: 4)

            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(Circle().fill(tint.opacity(0.13)))
        }
        .padding(.leading, 14)
        .padding(.trailing, 7)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color(.tertiarySystemFill))
        )
    }
}

// MARK: - Flow layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widestRow: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            widestRow = max(widestRow, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }

        let resolvedWidth: CGFloat
        if let proposedWidth = proposal.width, proposedWidth.isFinite {
            resolvedWidth = proposedWidth
        } else {
            resolvedWidth = widestRow
        }

        return CGSize(width: resolvedWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Formatting

extension Date {
    var trDayMonth: String {
        formatted(.dateTime.day().month(.wide).locale(Locale(identifier: "tr_TR")))
    }

    var trDayMonthWeekday: String {
        formatted(.dateTime.day().month(.wide).weekday(.wide).locale(Locale(identifier: "tr_TR")))
    }

    var trTime: String {
        formatted(.dateTime.hour().minute().locale(Locale(identifier: "tr_TR")))
    }
}

func formattedWeight(_ value: Double) -> String {
    value.formatted(.number.precision(.fractionLength(0...1)))
}
