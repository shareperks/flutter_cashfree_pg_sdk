import AppTrackingTransparency
import Flutter
import UIKit

/// Presents Apple's system ATT dialog once the scene is active, on both
/// iPhone and iPad. Tracking SDKs must wait for [requestIfNeeded] before
/// collecting advertising identifiers.
final class AttCoordinator {
  static let shared = AttCoordinator()

  private let channelName = "in.shareperks.app/att"
  private var started = false
  private var completedStatus: ATTrackingManager.AuthorizationStatus?
  private var waiters: [(ATTrackingManager.AuthorizationStatus) -> Void] = []
  private var delayWorkItem: DispatchWorkItem?

  private init() {}

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }
      switch call.method {
      case "requestTrackingAuthorization":
        self.requestIfNeeded { status in
          result(self.statusName(status))
        }
      case "getTrackingAuthorizationStatus":
        result(self.statusName(ATTrackingManager.trackingAuthorizationStatus))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func sceneDidBecomeActive() {
    requestIfNeeded()
  }

  func requestIfNeeded(completion: ((ATTrackingManager.AuthorizationStatus) -> Void)? = nil) {
    if let completion {
      if let completedStatus {
        completion(completedStatus)
        return
      }
      waiters.append(completion)
    }

    let current = ATTrackingManager.trackingAuthorizationStatus
    NSLog("[att] scene active. ATT status = \(statusName(current))")

    if current != .notDetermined {
      finish(current)
      return
    }

    guard !started else { return }
    started = true

    // The system dialog is dropped if presented before the window is key and
    // the scene is UIApplicationStateActive — a common iPad miss.
    let work = DispatchWorkItem { [weak self] in
      self?.presentRequest()
    }
    delayWorkItem = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
  }

  private func presentRequest() {
    let current = ATTrackingManager.trackingAuthorizationStatus
    let state = UIApplication.shared.applicationState
    NSLog(
      "[att] Requesting ATT authorization. applicationState=\(state.rawValue) status=\(statusName(current))"
    )

    if current != .notDetermined {
      finish(current)
      return
    }

    guard isSceneReadyToPresent() else {
      NSLog("[att] App/scene not active; will retry when scene becomes active")
      started = false
      return
    }

    ATTrackingManager.requestTrackingAuthorization { [weak self] status in
      DispatchQueue.main.async {
        guard let self else { return }
        NSLog("[att] ATT completion = \(self.statusName(status))")
        if status == .notDetermined {
          NSLog("[att] Completion still notDetermined; will retry on next active")
          self.started = false
          return
        }
        self.finish(status)
      }
    }
  }

  private func isSceneReadyToPresent() -> Bool {
    guard UIApplication.shared.applicationState == .active else { return false }
    return UIApplication.shared.connectedScenes.contains {
      $0.activationState == .foregroundActive
    }
  }

  private func finish(_ status: ATTrackingManager.AuthorizationStatus) {
    completedStatus = status
    started = true
    delayWorkItem?.cancel()
    delayWorkItem = nil
    let waiters = self.waiters
    self.waiters.removeAll()
    waiters.forEach { $0(status) }
  }

  private func statusName(_ status: ATTrackingManager.AuthorizationStatus) -> String {
    switch status {
    case .notDetermined: return "notDetermined"
    case .restricted: return "restricted"
    case .denied: return "denied"
    case .authorized: return "authorized"
    @unknown default: return "unknown"
    }
  }
}
