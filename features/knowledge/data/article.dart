/// A knowledge base article from GET /knowledge/articles.
class Article {
  const Article({
    required this.id,
    required this.title,
    required this.category,
    required this.excerpt,
    required this.content,
    required this.author,
    required this.createdAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: '${json['id']}',
        title: (json['title'] ?? '') as String,
        category: (json['category'] ?? '') as String,
        excerpt: (json['excerpt'] ?? '') as String,
        content: (json['content'] ?? '') as String,
        author: (json['author'] ?? '') as String,
        // The website shows `new Date(created_at).toLocaleDateString()` (zone-less → local).
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  final String id;
  final String title;
  final String category;
  final String excerpt;
  final String content;
  final String author;
  final DateTime createdAt;
}
