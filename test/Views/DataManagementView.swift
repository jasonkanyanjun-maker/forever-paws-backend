import SwiftUI

struct DataManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userProfileService = UserProfileService()
    
    @State private var isExporting = false
    @State private var showingDeleteAlert = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Export Data") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Export Your Data")
                            .font(.headline)
                        Text("Download a copy of all your data including pet profiles, photos, and videos.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Export Data") {
                        exportData()
                    }
                    .disabled(isExporting)
                }
                
                Section("Delete Data") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Delete All Data")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text("Permanently delete all your data. This action cannot be undone.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Delete All Data") {
                        showingDeleteAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Data Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete All Data", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("Are you sure you want to delete all your data? This action cannot be undone.")
            }
            .alert("Data Management", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        
        Task {
            // TODO: Implement data export
            await MainActor.run {
                alertMessage = "Data export will be sent to your email"
                showingAlert = true
                isExporting = false
            }
        }
    }
    
    private func deleteAllData() {
        Task {
            // TODO: Implement data deletion
            await MainActor.run {
                alertMessage = "All data has been deleted"
                showingAlert = true
            }
        }
    }
}

#Preview {
    DataManagementView()
}