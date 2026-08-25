import Foundation
import Combine
import Darwin

@MainActor
public final class PerformanceMonitor: ObservableObject {
    @Published public var memoryUsageMB: Double = 0.0
    @Published public var formattedMemory: String = "0 MB"

    private var timer: AnyCancellable?

    public init() {
        updateMemory()
        timer = Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateMemory()
            }
    }

    public func updateMemory() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024.0 / 1024.0
            self.memoryUsageMB = usedMB
            if usedMB < 1000 {
                self.formattedMemory = String(format: "%.1f MB", usedMB)
            } else {
                self.formattedMemory = String(format: "%.2f GB", usedMB / 1024.0)
            }
        }
    }
}
