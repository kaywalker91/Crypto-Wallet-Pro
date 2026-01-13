/// 목업 데이터 모드 설정
///
/// true: 목업 데이터 사용 (API 호출 없이 기능 흐름 테스트 가능)
/// false: 실제 API 사용
class MockConfig {
  MockConfig._();

  /// 전역 목업 모드 플래그
  ///
  /// 개발 중 API 없이 기능 흐름 테스트 시 true로 설정
  static const bool useMockData = true;

  /// 각 기능별 세부 목업 설정 (useMockData가 false일 때만 적용)
  static const bool mockBalance = true;
  static const bool mockHistory = true;
  static const bool mockTransaction = true;
  static const bool mockNft = true;

  /// 목업 데이터 지연 시간 (ms) - 실제 API 응답 시간 시뮬레이션
  static const int mockDelayMs = 800;

  /// 목업 에러 시뮬레이션 (테스트 용도)
  static const bool simulateErrors = false;
  static const double errorProbability = 0.1; // 10% 확률로 에러 발생
}
