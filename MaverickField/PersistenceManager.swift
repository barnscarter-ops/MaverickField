import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    private let indexKey = "mav_job_index"
    private func jobKey(_ id: String) -> String { "mav_job_\(id)" }

    func saveJob(_ job: SavedJob) {
        if let data = try? JSONEncoder().encode(job) {
            UserDefaults.standard.set(data, forKey: jobKey(job.id))
        }
        var index = loadIndex()
        index.removeAll { $0 == job.id }
        index.insert(job.id, at: 0)
        UserDefaults.standard.set(Array(index.prefix(20)), forKey: indexKey)
    }

    func loadJobs() -> [SavedJob] {
        loadIndex().compactMap { id in
            guard let data = UserDefaults.standard.data(forKey: jobKey(id)) else { return nil }
            return try? JSONDecoder().decode(SavedJob.self, from: data)
        }
    }

    func deleteJob(id: String) {
        UserDefaults.standard.removeObject(forKey: jobKey(id))
        var index = loadIndex()
        index.removeAll { $0 == id }
        UserDefaults.standard.set(index, forKey: indexKey)
    }

    private func loadIndex() -> [String] {
        UserDefaults.standard.array(forKey: indexKey) as? [String] ?? []
    }
}
