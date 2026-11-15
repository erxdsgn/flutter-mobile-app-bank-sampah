class FaqItem {
  final String question;
  final String answer;
  final String? relatedArticle;
  
  FaqItem({
    required this.question,
    required this.answer,
    this.relatedArticle,
  });
}

class FaqCategory {
  final String title;
  final List<FaqItem> items;

  FaqCategory({
    required this.title,
    required this.items,
  });
}