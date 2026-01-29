import 'package:flutter/material.dart';
import '../services/device_integrity_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// 기기 무결성 경고 다이얼로그
///
/// 루팅/탈옥된 기기에서 앱 사용 시 보안 위험을 사용자에게 알립니다.
///
/// **디자인 철학**
/// - 경고하되 차단하지 않음: 사용자 선택권 존중
/// - 투명한 위험 정보 제공: 감지된 위험 요소 명확히 표시
/// - 교육적 접근: 왜 위험한지 설명
///
/// **사용 예시**
/// ```dart
/// final result = await deviceIntegrityService.checkDeviceIntegrity();
/// if (result.isCompromised && mounted) {
///   showDialog(
///     context: context,
///     builder: (context) => IntegrityWarningDialog(result: result),
///   );
/// }
/// ```
class IntegrityWarningDialog extends StatelessWidget {
  final DeviceIntegrityResult result;

  const IntegrityWarningDialog({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final isRooted = result.status == DeviceIntegrityStatus.rooted;
    final isJailbroken = result.status == DeviceIntegrityStatus.jailbroken;
    final riskColor = _getRiskColor(result.riskLevel);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            color: riskColor,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getTitle(isRooted, isJailbroken),
              style: AppTypography.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 위험도 표시
            _buildRiskIndicator(context, result.riskLevel),
            const SizedBox(height: 16),

            // 경고 메시지
            Text(
              _getWarningMessage(isRooted, isJailbroken),
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // 감지된 위험 요소 목록
            if (result.details.isNotEmpty) ...[
              Text(
                '감지된 위험 요소:',
                style: AppTypography.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: riskColor,
                ),
              ),
              const SizedBox(height: 8),
              ...result.details.map(
                (threat) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 6,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          threat,
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 보안 권장사항
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: riskColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security_rounded,
                        size: 16,
                        color: riskColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '보안 권장사항',
                        style: AppTypography.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 큰 금액의 암호화폐는 하드웨어 지갑에 보관하세요\n'
                    '• 앱 사용 후 반드시 로그아웃하세요\n'
                    '• 출처 불명의 앱 설치를 피하세요\n'
                    '• 정기적으로 기기 보안 상태를 점검하세요',
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            '앱 종료',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ButtonStyle(
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return AppColors.surfaceLight;
              }
              if (states.contains(WidgetState.pressed)) {
                return riskColor.withValues(alpha: 0.9);
              }
              if (states.contains(WidgetState.hovered)) {
                return riskColor.withValues(alpha: 0.8);
              }
              return riskColor;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return AppColors.textDisabled;
              }
              return Colors.white;
            }),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return Colors.white.withValues(alpha: 0.16);
              }
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)) {
                return Colors.white.withValues(alpha: 0.1);
              }
              return null;
            }),
          ),
          child: const Text('위험 감수하고 계속'),
        ),
      ],
    );
  }

  /// 위험도 표시 인디케이터
  Widget _buildRiskIndicator(BuildContext context, double riskLevel) {
    final percentage = (riskLevel * 100).toInt();
    final riskColor = _getRiskColor(riskLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '위험도',
              style: AppTypography.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '$percentage%',
              style: AppTypography.textTheme.labelLarge?.copyWith(
                color: riskColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: riskLevel,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(
              riskColor,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  /// 다이얼로그 제목 생성
  String _getTitle(bool isRooted, bool isJailbroken) {
    if (isRooted) {
      return '루팅된 기기 감지';
    } else if (isJailbroken) {
      return '탈옥된 기기 감지';
    } else {
      return '보안 경고';
    }
  }

  /// 경고 메시지 생성
  String _getWarningMessage(bool isRooted, bool isJailbroken) {
    if (isRooted) {
      return '현재 기기가 루팅되어 있습니다. 루팅된 기기에서는 악성 앱이 '
          '프라이빗 키에 접근할 수 있어 자산 손실 위험이 있습니다.\n\n'
          '가능하면 정상 기기에서 지갑을 사용하시고, 이 기기에서 계속 사용하실 경우 '
          '보안에 각별히 유의해 주세요.';
    } else if (isJailbroken) {
      return '현재 기기가 탈옥되어 있습니다. 탈옥된 기기에서는 악성 앱이 '
          '프라이빗 키에 접근할 수 있어 자산 손실 위험이 있습니다.\n\n'
          '가능하면 정상 기기에서 지갑을 사용하시고, 이 기기에서 계속 사용하실 경우 '
          '보안에 각별히 유의해 주세요.';
    } else {
      return '기기 무결성 검사 중 이상 징후가 감지되었습니다. '
          '보안에 주의해 주세요.';
    }
  }

  /// 위험도에 따른 색상 반환
  Color _getRiskColor(double riskLevel) {
    if (riskLevel >= 0.8) {
      return Colors.red.shade600;
    } else if (riskLevel >= 0.5) {
      return Colors.orange.shade600;
    } else if (riskLevel >= 0.3) {
      return Colors.yellow.shade700;
    } else {
      return Colors.blue.shade600;
    }
  }
}

/// 간단한 경고 다이얼로그를 표시하는 헬퍼 함수
///
/// 사용 예시:
/// ```dart
/// final shouldContinue = await showIntegrityWarning(context, result);
/// if (shouldContinue == true) {
///   // 사용자가 위험을 감수하고 계속 사용하기로 함
/// } else {
///   // 앱 종료 또는 다른 조치
/// }
/// ```
Future<bool?> showIntegrityWarning(
  BuildContext context,
  DeviceIntegrityResult result,
) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // 뒤로가기로 닫기 방지
    builder: (context) => IntegrityWarningDialog(result: result),
  );
}
