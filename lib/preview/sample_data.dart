import '../models/item_category.dart';

/// 꾸미기 미리보기와 `--dart-define=USE_SAMPLE_DATA=true` 전용 문구.
/// 실제 사용자 저장소 기본값은 비어 있다.
class PreviewSample {
  static const itemTitles = ['따뜻한 차 한 잔', '10분 스트레칭', '오늘의 한 줄 쓰기'];

  static const previewItems = [
    (
      title: '물 한 잔 마시기',
      category: ItemCategory.todo,
      done: true,
      repeatsDaily: true,
      pageId: 'inbox',
    ),
    (
      title: '책 10쪽 읽기',
      category: ItemCategory.study,
      done: true,
      repeatsDaily: false,
      pageId: 'sample-study',
    ),
    (
      title: '30분 집중하기',
      category: ItemCategory.study,
      done: false,
      repeatsDaily: false,
      pageId: 'sample-study',
    ),
    (
      title: '가볍게 산책하기',
      category: ItemCategory.routine,
      done: false,
      repeatsDaily: true,
      pageId: 'inbox',
    ),
  ];
}
