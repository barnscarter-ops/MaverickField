import SwiftUI

struct JobHistoryView: View {
    var onLoad: ((SavedJob) -> Void)? = nil

    @State private var jobs: [SavedJob] = []
    @State private var jobToDelete: SavedJob? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0a0d14").ignoresSafeArea()

                if jobs.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "folder")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "#252d40"))
                        Text("No saved jobs")
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(hex: "#5a6275"))
                        Text("Save a chat conversation from the Chat tab")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#3d4557"))
                    }
                } else {
                    List {
                        ForEach(jobs) { job in
                            JobRow(job: job)
                                .listRowBackground(Color(hex: "#0e1320"))
                                .listRowSeparatorTint(Color(hex: "#1c2436"))
                                .onTapGesture {
                                    onLoad?(job)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        jobToDelete = job
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Job History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "#0e1320"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear { reload() }
        .confirmationDialog("Delete this job?", isPresented: Binding(
            get: { jobToDelete != nil },
            set: { if !$0 { jobToDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let j = jobToDelete { delete(j) }
            }
            Button("Cancel", role: .cancel) { jobToDelete = nil }
        }
    }

    private func reload() {
        jobs = PersistenceManager.shared.loadJobs()
    }

    private func delete(_ job: SavedJob) {
        PersistenceManager.shared.deleteJob(id: job.id)
        jobToDelete = nil
        reload()
    }
}

struct JobRow: View {
    let job: SavedJob

    private static let df: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(modeColor(job.mode))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(job.label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#e8ebf2"))
                HStack(spacing: 8) {
                    Text(job.mode.label)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(modeColor(job.mode))
                    Text("·")
                        .foregroundColor(Color(hex: "#3d4557"))
                    Text("\(job.messages.count) messages")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#5a6275"))
                    Text("·")
                        .foregroundColor(Color(hex: "#3d4557"))
                    Text(Self.df.string(from: job.savedAt))
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#5a6275"))
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#3d4557"))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }

    private func modeColor(_ m: WorkflowMode) -> Color {
        switch m {
        case .agent: return .purple
        case .ops:   return .green
        }
    }
}
