import 'package:flutter/material.dart';
import '../services/device_integrity_service.dart';

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
    final theme = Theme.of(context);
    final isRooted = result.status == DeviceIntegrityStatus.rooted;
    final isJailbroken = result.status == DeviceIntegrityStatus.jailbroken;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: theme.colorScheme.surface,
      title: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            color: _getRiskColor(result.riskLevel),
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getTitle(isRooted, isJailbroken),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
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
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // 감지된 위험 요소 목록
            if (result.details.isNotEmpty) ...[
              Text(
                '감지된 위험 요소:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getRiskColor(result.riskLevel),
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
                        color: theme.colorScheme.onSurface.withValues(alpha:0.6),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          threat,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha:0.7),
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
                color: _getRiskColor(result.riskLevel).withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getRiskColor(result.riskLevel).withValues(alpha:0.3),
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
                        color: _getRiskColor(result.riskLevel),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '보안 권장사항',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getRiskColor(result.riskLevel),
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
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha:0.7),
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
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            backgroundColor: _getRiskColor(result.riskLevel).withValues(alpha:0.1),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            '위험 감수하고 계속',
            style: TextStyle(
              color: _getRiskColor(result.riskLevel),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// 위험도 표시 인디케이터
  Widget _buildRiskIndicator(BuildContext context, double riskLevel) {
    final theme = Theme.of(context);
    final percentage = (riskLevel * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '위험도',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha:0.7),
              ),
            ),
            Text(
              '$percentage%',
              style: theme.textTheme.labelLarge?.copyWith(
                color: _getRiskColor(riskLevel),
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
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getRiskColor(riskLevel),
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
