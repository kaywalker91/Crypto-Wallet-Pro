import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var isProtectionEnabled = false
    private var blurEffectView: UIVisualEffectView?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let securityChannel = FlutterMethodChannel(
            name: "com.etherflow.crypto_wallet_pro/security",
            binaryMessenger: controller.binaryMessenger
        )

        securityChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard let self = self else {
                result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate not available", details: nil))
                return
            }

            switch call.method {
            case "enableProtection":
                self.enableScreenshotProtection()
                result(true)
            case "disableProtection":
                self.disableScreenshotProtection()
                result(true)
            case "isProtectionEnabled":
                result(self.isProtectionEnabled)
            case "checkJailbreakStatus":
                let jailbreakResult = self.checkJailbreakStatus()
                result(jailbreakResult)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    /**
     * Enable screenshot protection for iOS.
     *
     * iOS doesn't have a direct equivalent to Android's FLAG_SECURE.
     * This implementation uses a blur overlay when the app enters background state,
     * which prevents sensitive content from appearing in:
     * - App Switcher (Recent Apps)
     * - Screenshot notifications
     *
     * Security Notes:
     * - Cannot prevent screenshots while app is in foreground (iOS limitation)
     * - Can only hide content in app switcher snapshot
     * - Consider implementing screenshot detection for additional security
     */
    private func enableScreenshotProtection() {
        isProtectionEnabled = true

        // Register for background state notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    /**
     * Disable screenshot protection.
     *
     * Removes observers and clears blur overlay.
     */
    private func disableScreenshotProtection() {
        isProtectionEnabled = false

        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        removeBlurOverlay()
    }

    /**
     * Called when app enters background.
     *
     * Applies a blur effect to hide sensitive content in app switcher.
     * This snapshot is taken immediately after this method returns.
     */
    @objc private func applicationDidEnterBackground() {
        guard isProtectionEnabled else { return }
        applyBlurOverlay()
    }

    /**
     * Called when app returns to foreground.
     *
     * Removes the blur overlay to restore normal view.
     */
    @objc private func applicationWillEnterForeground() {
        guard isProtectionEnabled else { return }
        removeBlurOverlay()
    }

    /**
     * Applies a blur effect over the entire window.
     *
     * Uses UIBlurEffect with .systemMaterial for a native iOS appearance.
     * Alternative: Use a solid color overlay for complete hiding.
     */
    private func applyBlurOverlay() {
        guard let window = window, blurEffectView == nil else { return }

        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = window.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.tag = 9999 // Tag for easy identification

        window.addSubview(blurView)
        blurEffectView = blurView
    }

    /**
     * Removes the blur overlay.
     */
    private func removeBlurOverlay() {
        blurEffectView?.removeFromSuperview()
        blurEffectView = nil
    }

    // MARK: - Jailbreak Detection

    /**
     * 탈옥 상태 종합 검사 (Defense-in-Depth)
     *
     * 다층 검사를 수행하여 iOS 탈옥을 탐지합니다:
     * - Layer 1: 탈옥 앱 존재 여부 (Cydia, Sileo, Zebra)
     * - Layer 2: 탈옥 파일 경로 접근 가능 여부
     * - Layer 3: 샌드박스 무결성 검사 (fork 호출 가능 여부)
     * - Layer 4: 심볼릭 링크 검사
     * - Layer 5: 동적 라이브러리 검사
     *
     * - Returns: Dictionary with keys:
     *   - "isJailbroken": Bool
     *   - "threats": [String]
     *   - "riskLevel": Double
     */
    private func checkJailbreakStatus() -> [String: Any] {
        var threats: [String] = []
        var riskScore: Double = 0.0

        // Layer 1: 탈옥 앱 존재 여부 (가장 명확한 탈옥 신호)
        if checkForJailbreakApps() {
            threats.append("탈옥 앱 발견 (Cydia, Sileo 등)")
            riskScore += 0.4
        }

        // Layer 2: 탈옥 파일 경로 접근 가능 여부
        let jailbreakPaths = checkForJailbreakPaths()
        if !jailbreakPaths.isEmpty {
            threats.append("탈옥 관련 파일 경로 접근 가능: \(jailbreakPaths.joined(separator: ", "))")
            riskScore += 0.3
        }

        // Layer 3: 샌드박스 무결성 검사 (fork 가능 = 탈옥)
        if checkForkAbility() {
            threats.append("샌드박스 무결성 손상 (fork 호출 가능)")
            riskScore += 0.25
        }

        // Layer 4: 심볼릭 링크 검사
        if checkSymbolicLinks() {
            threats.append("비정상적인 심볼릭 링크 감지")
            riskScore += 0.15
        }

        // Layer 5: 동적 라이브러리 검사
        let suspiciousLibs = checkDynamicLibraries()
        if !suspiciousLibs.isEmpty {
            threats.append("의심스러운 동적 라이브러리: \(suspiciousLibs.joined(separator: ", "))")
            riskScore += 0.2
        }

        return [
            "isJailbroken": riskScore >= 0.3, // 30% 이상 위험도면 탈옥으로 판단
            "threats": threats,
            "riskLevel": min(riskScore, 1.0)
        ]
    }

    /**
     * 탈옥 앱 존재 여부 검사
     *
     * Cydia, Sileo, Zebra 등 주요 탈옥 패키지 관리자를 탐지합니다.
     */
    private func checkForJailbreakApps() -> Bool {
        let jailbreakApps = [
            "/Applications/Cydia.app",
            "/Applications/Sileo.app",
            "/Applications/Zebra.app",
            "/Applications/blackra1n.app",
            "/Applications/FakeCarrier.app",
            "/Applications/Icy.app",
            "/Applications/IntelliScreen.app",
            "/Applications/MxTube.app",
            "/Applications/RockApp.app",
            "/Applications/SBSettings.app",
            "/Applications/WinterBoard.app"
        ]

        return jailbreakApps.contains { FileManager.default.fileExists(atPath: $0) }
    }

    /**
     * 탈옥 파일 경로 접근 가능 여부 검사
     *
     * 정상 iOS 기기에서는 접근할 수 없는 경로들을 확인합니다.
     * 샌드박스가 정상이면 이 경로들에 접근할 수 없습니다.
     */
    private func checkForJailbreakPaths() -> [String] {
        let jailbreakPaths = [
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/stash",
            "/private/var/tmp/cydia.log",
            "/var/lib/cydia",
            "/usr/sbin/sshd",
            "/usr/bin/sshd",
            "/usr/libexec/ssh-keysign",
            "/bin/bash",
            "/bin/sh",
            "/etc/apt",
            "/etc/ssh/sshd_config",
            "/Library/MobileSubstrate/MobileSubstrate.dylib"
        ]

        var detectedPaths: [String] = []

        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                // 경로 이름을 짧게 표시 (마지막 컴포넌트만)
                if let lastComponent = path.components(separatedBy: "/").last {
                    detectedPaths.append(lastComponent)
                }
            }
        }

        return detectedPaths
    }

    /**
     * fork() 호출 가능 여부 검사 (샌드박스 무결성)
     *
     * 정상 iOS 앱은 샌드박스 내에서 fork()를 호출할 수 없습니다.
     * 탈옥된 기기에서는 샌드박스가 손상되어 fork()가 성공합니다.
     *
     * 주의: 실제로 fork()를 실행하지 않고, 심볼 존재 여부만 확인합니다.
     * (실제 fork 호출은 앱 크래시를 유발할 수 있음)
     */
    private func checkForkAbility() -> Bool {
        // iOS 17+ 시뮬레이터 또는 정상 기기에서는 fork 심볼이 없어야 함
        // dlsym을 통해 심볼 존재 여부만 확인
        #if targetEnvironment(simulator)
        return false
        #else
        // 정상 기기에서는 fork 심볼을 찾을 수 없어야 함
        // 탈옥 기기에서는 찾을 수 있음
        let forkPtr = dlsym(RTLD_DEFAULT, "fork")
        return forkPtr != nil
        #endif
    }

    /**
     * 심볼릭 링크 검사
     *
     * 정상 iOS 시스템과 다른 심볼릭 링크 구조를 감지합니다.
     * 탈옥 도구들은 시스템 무결성을 위해 심볼릭 링크를 수정합니다.
     */
    private func checkSymbolicLinks() -> Bool {
        let suspiciousLinks = [
            "/Applications",
            "/Library/Ringtones",
            "/Library/Wallpaper",
            "/usr/arm-apple-darwin9",
            "/usr/include",
            "/usr/libexec",
            "/usr/share"
        ]

        for link in suspiciousLinks {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: link)
                if attributes[.type] as? FileAttributeType == .typeSymbolicLink {
                    return true
                }
            } catch {
                // 접근 불가 (정상)
                continue
            }
        }

        return false
    }

    /**
     * 동적 라이브러리 검사
     *
     * 탈옥 환경에서 주입되는 의심스러운 동적 라이브러리를 탐지합니다.
     * MobileSubstrate, Substitute 등 탈옥 트윅 프레임워크를 찾습니다.
     */
    private func checkDynamicLibraries() -> [String] {
        let suspiciousLibraries = [
            "MobileSubstrate",
            "SubstrateLoader",
            "SubstrateInserter",
            "CydiaSubstrate",
            "Substitute",
            "TweakInject"
        ]

        var detectedLibs: [String] = []
        var imageCount: UInt32 = 0

        // 로드된 모든 이미지(라이브러리) 검사
        imageCount = _dyld_image_count()
        for i in 0..<imageCount {
            if let imageName = _dyld_get_image_name(i) {
                let name = String(cString: imageName)

                for suspiciousLib in suspiciousLibraries {
                    if name.lowercased().contains(suspiciousLib.lowercased()) {
                        detectedLibs.append(suspiciousLib)
                        break
                    }
                }
            }
        }

        return detectedLibs
    }
}
