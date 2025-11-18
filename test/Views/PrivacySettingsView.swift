import SwiftUI

struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var dataCollectionEnabled = true
    @State private var analyticsEnabled = true
    @State private var crashReportingEnabled = true
    @State private var personalizedAdsEnabled = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Data Collection") {
                    Toggle("Allow Data Collection", isOn: $dataCollectionEnabled)
                    Toggle("Analytics", isOn: $analyticsEnabled)
                    Toggle("Crash Reporting", isOn: $crashReportingEnabled)
                }
                
                Section("Advertising") {
                    Toggle("Personalized Ads", isOn: $personalizedAdsEnabled)
                }
                
                Section("Privacy Actions") {
                    Button("View Privacy Policy") {
                        if let url = URL(string: "https://foreverpaws.com/privacy") {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    Button("Request Data Export") {
                        // TODO: Implement data export
                    }
                    .foregroundColor(.blue)
                    
                    Button("Delete My Data") {
                        // TODO: Implement data deletion
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Privacy Settings")
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

#Preview {
    PrivacySettingsView()
}