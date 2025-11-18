import Foundation

struct SupabaseConfig {
    static var url: String {
        let v = UserDefaults.standard.string(forKey: "supabase_url")?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (v?.isEmpty == false ? v! : "https://gjpiwsehobfupdpixnuf.supabase.co")
    }
    static var anonKey: String {
        let v = UserDefaults.standard.string(forKey: "supabase_anon_key")?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (v?.isEmpty == false ? v! : "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdqcGl3c2Vob2JmdXBkcGl4bnVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk2MjMyNzksImV4cCI6MjA3NTE5OTI3OX0.TLhHHhJ4g9uOE_Et2M_aiGv8-T30Wl9ARIAQMvhGzmw")
    }
    static func setURL(_ value: String) { UserDefaults.standard.set(value, forKey: "supabase_url") }
    static func setAnonKey(_ value: String) { UserDefaults.standard.set(value, forKey: "supabase_anon_key") }
}
