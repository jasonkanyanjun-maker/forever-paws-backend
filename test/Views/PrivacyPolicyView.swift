//
//  PrivacyPolicyView.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Privacy Policy")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Last updated: \(formattedDate)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Introduction
                    PolicySection(title: "Introduction") {
                        Text("Forever Paws is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.")
                    }
                    
                    // Information We Collect
                    PolicySection(title: "Information We Collect") {
                        VStack(alignment: .leading, spacing: 12) {
                            PolicySubsection(title: "Personal Information") {
                                Text("• Account information (email, display name)\n• Profile photos and pet information\n• Photos and videos you upload\n• Letters and memories you create")
                            }
                            
                            PolicySubsection(title: "Usage Information") {
                                Text("• App usage analytics\n• Device information\n• Location data (if enabled)\n• Crash reports and error logs")
                            }
                        }
                    }
                    
                    // How We Use Your Information
                    PolicySection(title: "How We Use Your Information") {
                        Text("We use your information to:\n\n• Provide and maintain our services\n• Create personalized experiences\n• Generate holographic projections and videos\n• Send notifications and updates\n• Improve our app and services\n• Ensure security and prevent fraud")
                    }
                    
                    // Information Sharing
                    PolicySection(title: "Information Sharing") {
                        Text("We do not sell, trade, or rent your personal information to third parties. We may share your information only in the following circumstances:\n\n• With your explicit consent\n• To comply with legal obligations\n• To protect our rights and safety\n• With service providers who assist us in operating our app")
                    }
                    
                    // Data Security
                    PolicySection(title: "Data Security") {
                        Text("We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. This includes:\n\n• Encryption of data in transit and at rest\n• Regular security audits\n• Access controls and authentication\n• Secure cloud storage with Supabase")
                    }
                    
                    // Your Rights
                    PolicySection(title: "Your Rights") {
                        Text("You have the right to:\n\n• Access your personal information\n• Correct inaccurate information\n• Delete your account and data\n• Export your data\n• Opt-out of certain data collection\n• Control notification preferences")
                    }
                    
                    // Data Retention
                    PolicySection(title: "Data Retention") {
                        Text("We retain your personal information for as long as necessary to provide our services and fulfill the purposes outlined in this policy. You may delete your account at any time, which will remove your personal information from our systems.")
                    }
                    
                    // Children's Privacy
                    PolicySection(title: "Children's Privacy") {
                        Text("Our app is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.")
                    }
                    
                    // Changes to This Policy
                    PolicySection(title: "Changes to This Policy") {
                        Text("We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the \"Last updated\" date.")
                    }
                    
                    // Contact Information
                    PolicySection(title: "Contact Us") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("If you have any questions about this Privacy Policy, please contact us:")
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Email: privacy@foreverpaws.com")
                                    .foregroundColor(.blue)
                                
                                Text("Address: Forever Paws Inc.\n123 Pet Street\nAnimal City, AC 12345")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
}

struct PolicySection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            content
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(2)
        }
    }
}

struct PolicySubsection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            content
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(1)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}