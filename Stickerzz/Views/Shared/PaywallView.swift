import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 0) {
                    hero
                    features
                        .padding(.top, 32)
                    cta
                        .padding(.top, 32)
                        .padding(.bottom, 48)
                }
            }
            .ignoresSafeArea(edges: .top)
            .background(Color(.systemGroupedBackground))

            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
            }
            .padding(.top, 56)
            .padding(.trailing, 20)
        }
        .onChange(of: purchases.isPro) { _, isPro in
            if isPro { dismiss() }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#C5B9E0") ?? .purple, Color(hex: "#A8D5E2") ?? .blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 16) {
                Text("✨🌿💧🧘‍♀️\n🏃‍♀️🌙☀️🫧")
                    .font(.system(size: 36))
                    .multilineTextAlignment(.center)
                    .padding(.top, 72)

                VStack(spacing: 6) {
                    Text("Stickerzz Pro")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Every habit, no limits.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.bottom, 36)
            }
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }

    // MARK: - Features

    private var features: some View {
        VStack(spacing: 0) {
            featureRow(
                icon: "list.bullet",
                color: Color(hex: "#C5B9E0") ?? .purple,
                title: "Unlimited routines",
                subtitle: "Free plan: 1 routine"
            )
            Divider().padding(.leading, 60)
            featureRow(
                icon: "sparkles",
                color: Color(hex: "#F5D5A0") ?? .orange,
                title: "Unlimited habits",
                subtitle: "Free plan: 3 per routine, 5 standalone"
            )
            Divider().padding(.leading, 60)
            featureRow(
                icon: "flame.fill",
                color: Color(hex: "#F2C6D0") ?? .pink,
                title: "Streak tracking, always on",
                subtitle: "Never lose your history"
            )
            Divider().padding(.leading, 60)
            featureRow(
                icon: "heart.fill",
                color: Color(hex: "#B5D5C5") ?? .green,
                title: "One-time purchase",
                subtitle: "No subscription, ever"
            )
        }
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray5), lineWidth: 0.5))
        .padding(.horizontal, 20)
    }

    private func featureRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(color, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - CTA

    private var cta: some View {
        VStack(spacing: 14) {
            Button {
                Task { try? await purchases.purchase() }
            } label: {
                ZStack {
                    if purchases.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(ctaLabel)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#C5B9E0") ?? .purple, Color(hex: "#A8D5E2") ?? .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16)
                )
            }
            .disabled(purchases.isLoading || purchases.product == nil)
            .padding(.horizontal, 20)

            Button {
                Task { await purchases.restorePurchases() }
            } label: {
                Text("Restore purchase")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var ctaLabel: String {
        if let product = purchases.product {
            return "Unlock Pro — \(product.displayPrice)"
        }
        return "Unlock Pro"
    }
}
