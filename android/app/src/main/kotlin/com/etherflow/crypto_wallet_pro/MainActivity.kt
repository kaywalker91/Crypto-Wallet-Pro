package com.etherflow.crypto_wallet_pro

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.etherflow.crypto_wallet_pro/security"
    private var isProtectionEnabled = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableProtection" -> {
                    enableScreenshotProtection()
                    result.success(true)
                }
                "disableProtection" -> {
                    disableScreenshotProtection()
                    result.success(true)
                }
                "isProtectionEnabled" -> {
                    result.success(isProtectionEnabled)
                }
                "checkRootStatus" -> {
                    val rootCheckResult = checkRootStatus()
                    result.success(rootCheckResult)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Enable screenshot and screen recording protection.
     *
     * Sets FLAG_SECURE on the window, which:
     * - Prevents screenshots (system screenshot and third-party apps)
     * - Prevents screen recording
     * - Hides content in Recent Apps screen
     *
     * Security Note: This is the most secure option on Android.
     * No known bypasses on non-rooted devices.
     */
    private fun enableScreenshotProtection() {
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
        isProtectionEnabled = true
    }

    /**
     * Disable screenshot protection.
     *
     * Clears FLAG_SECURE from the window.
     * Call this when leaving sensitive screens.
     */
    private fun disableScreenshotProtection() {
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        isProtectionEnabled = false
    }

    /**
     * 루팅 상태 종합 검사 (Defense-in-Depth)
     *
     * RootBeer 라이브러리 스타일의 다층 검사를 수행합니다:
     * - Layer 1: su 바이너리 존재 여부
     * - Layer 2: Superuser/Magisk 앱 패키지 감지
     * - Layer 3: 빌드 태그 검사 (test-keys)
     * - Layer 4: 위험 경로 접근 가능 여부
     * - Layer 5: SELinux 상태
     *
     * @return Map<String, Any> {
     *   "isRooted": Boolean,
     *   "threats": List<String>,
     *   "riskLevel": Double
     * }
     */
    private fun checkRootStatus(): Map<String, Any> {
        val threats = mutableListOf<String>()
        var riskScore = 0.0

        // Layer 1: su 바이너리 검사 (가장 명확한 루팅 신호)
        if (checkForSuBinary()) {
            threats.add("su 바이너리 발견 (루팅 도구)")
            riskScore += 0.4
        }

        // Layer 2: Superuser 앱 패키지 검사
        val rootApps = checkForRootApps()
        if (rootApps.isNotEmpty()) {
            threats.add("루팅 관련 앱 감지: ${rootApps.joinToString(", ")}")
            riskScore += 0.3
        }

        // Layer 3: 빌드 태그 검사 (test-keys = 비공식 빌드)
        if (checkBuildTags()) {
            threats.add("비공식 빌드 (test-keys) 감지")
            riskScore += 0.2
        }

        // Layer 4: 위험 경로 쓰기 가능 여부
        if (checkDangerousProperties()) {
            threats.add("시스템 디렉토리 쓰기 권한 감지")
            riskScore += 0.15
        }

        // Layer 5: SELinux 상태 (Permissive = 위험)
        if (checkSELinuxStatus()) {
            threats.add("SELinux Permissive 모드 감지")
            riskScore += 0.15
        }

        return mapOf(
            "isRooted" to (riskScore >= 0.3), // 30% 이상 위험도면 루팅으로 판단
            "threats" to threats,
            "riskLevel" to minOf(riskScore, 1.0)
        )
    }

    /**
     * su 바이너리 존재 여부 검사
     *
     * 루팅된 기기에서 사용하는 su 바이너리를 여러 경로에서 탐색합니다.
     * Magisk, SuperSU 등 대부분의 루팅 도구가 이 파일들을 설치합니다.
     */
    private fun checkForSuBinary(): Boolean {
        val paths = arrayOf(
            "/system/bin/su",
            "/system/xbin/su",
            "/system/sbin/su",
            "/sbin/su",
            "/su/bin/su",
            "/magisk/.core/bin/su",
            "/system/usr/we-need-root/su",
            "/system/app/Superuser.apk",
            "/data/local/su",
            "/data/local/bin/su",
            "/data/local/xbin/su"
        )

        return paths.any { path ->
            try {
                val file = File(path)
                file.exists() && file.canExecute()
            } catch (e: Exception) {
                false
            }
        }
    }

    /**
     * 루팅 관련 앱 패키지 검사
     *
     * Superuser, Magisk, KingRoot 등 루팅 관리 앱을 탐지합니다.
     */
    private fun checkForRootApps(): List<String> {
        val rootPackages = arrayOf(
            "com.noshufou.android.su",           // Superuser
            "com.noshufou.android.su.elite",     // Superuser Elite
            "eu.chainfire.supersu",              // SuperSU
            "com.koushikdutta.superuser",        // Koush Superuser
            "com.thirdparty.superuser",          // Third-party Superuser
            "com.yellowes.su",                   // YellowSU
            "com.topjohnwu.magisk",              // Magisk Manager
            "com.kingroot.kinguser",             // KingRoot
            "com.kingo.root",                    // KingoRoot
            "com.smedialink.oneclickroot",       // OneClickRoot
            "com.zhiqupk.root.global",           // Root Master
            "com.alephzain.framaroot"            // Framaroot
        )

        val detectedApps = mutableListOf<String>()
        val pm = packageManager

        for (packageName in rootPackages) {
            try {
                pm.getPackageInfo(packageName, 0)
                detectedApps.add(packageName.split(".").last())
            } catch (e: Exception) {
                // 패키지 없음 (정상)
            }
        }

        return detectedApps
    }

    /**
     * 빌드 태그 검사
     *
     * test-keys로 서명된 빌드는 비공식 ROM이므로 위험 신호입니다.
     * 공식 ROM은 release-keys로 서명됩니다.
     */
    private fun checkBuildTags(): Boolean {
        return try {
            val buildTags = Build.TAGS
            buildTags != null && buildTags.contains("test-keys")
        } catch (e: Exception) {
            false
        }
    }

    /**
     * 위험한 시스템 속성 검사
     *
     * 읽기 전용이어야 할 시스템 디렉토리에 쓰기 권한이 있는지 확인합니다.
     * 정상 기기에서는 불가능한 작업입니다.
     */
    private fun checkDangerousProperties(): Boolean {
        val dangerousPaths = arrayOf(
            "/system",
            "/system/bin",
            "/system/sbin",
            "/system/xbin",
            "/vendor/bin",
            "/sbin"
        )

        return dangerousPaths.any { path ->
            try {
                val file = File(path)
                file.canWrite()
            } catch (e: Exception) {
                false
            }
        }
    }

    /**
     * SELinux 상태 검사
     *
     * Permissive 모드는 보안 정책이 비활성화된 상태로,
     * 루팅 도구들이 자주 사용합니다.
     */
    private fun checkSELinuxStatus(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec("getenforce")
            val result = process.inputStream.bufferedReader().readText().trim()
            result.equals("Permissive", ignoreCase = true)
        } catch (e: Exception) {
            false
        }
    }
}
