import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon and Info
                    VStack(spacing: 16) {
                        Image(systemName: "pawprint.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "E879F9"), Color(hex: "F472B6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Forever Paws")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Version \(appVersion) (\(buildNumber))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About Forever Paws")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("Forever Paws is a beautiful app designed to help you cherish and preserve memories of your beloved pets. Create AI-generated videos, manage photos, and keep your pet's legacy alive forever.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Links
                    VStack(spacing: 12) {
                        AboutLinkRow(
                            icon: "globe",
                            title: "Website",
                            subtitle: "Visit our website",
                            url: "https://foreverpaws.com"
                        )
                        
                        AboutLinkRow(
                            icon: "envelope",
                            title: "Contact Us",
                            subtitle: "Get in touch",
                            url: "mailto:support@foreverpaws.com"
                        )
                        
                        AboutLinkRow(
                            icon: "doc.text",
                            title: "Terms of Service",
                            subtitle: "Read our terms",
                            url: "https://foreverpaws.com/terms"
                        )
                        
                        AboutLinkRow(
                            icon: "hand.raised",
                            title: "Privacy Policy",
                            subtitle: "Read our privacy policy",
                            url: "https://foreverpaws.com/privacy"
                        )
                    }
                    
                    // Copyright
                    VStack(spacing: 8) {
                        Text("© 2024 Forever Paws")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Made with ❤️ for pet lovers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AboutLinkRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let url: String
    
    var body: some View {
        Button {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AboutView()
}