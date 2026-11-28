import 'package:dio/dio.dart';

import '../l10n/l10n.dart';
import 'api_client.dart';

/// Une source que WinAI peut utiliser : un fichier de l'utilisateur, une
/// épreuve ou une formation à laquelle il a accès, ou ses erreurs de quiz.
/// Le serveur ne reçoit que ce couple (type, id) et contrôle l'accès.
class WinAISourceRef {
  final String type;
  final int id;
  final String title;
  final String? detail;
  const WinAISourceRef(
      {required this.type, required this.id, required this.title, this.detail});

  factory WinAISourceRef.fromJson(Map<String, dynamic> j) => WinAISourceRef(
        type: j['type'] as String? ?? 'document',
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: j['title'] as String? ?? '',
        detail: j['detail'] as String?,
      );

  /// Clé d'une sélection (deux types peuvent porter le même numéro).
  String get key => '$type:$id';

  Map<String, dynamic> toJson() => {'type': type, 'id': id};
}

/// Citation renvoyée avec une réponse appuyée sur des sources.
class WinAICitation {
  final String title;
  final int? page;
  const WinAICitation({required this.title, this.page});

  factory WinAICitation.fromJson(Map<String, dynamic> j) => WinAICitation(
        title: j['title'] as String? ?? '',
        page: (j['page'] as num?)?.toInt(),
      );
}

/// Fichier téléversé par l'utilisateur.
class WinAIDocument {
  final int id;
  final String title, fileName, status;
  final int sizeBytes;
  final String? error;
  const WinAIDocument({
    required this.id,
    required this.title,
    required this.fileName,
    required this.status,
    required this.sizeBytes,
    this.error,
  });

  bool get pending => status == 'pending';
  bool get ready => status == 'ready';
  bool get failed => status == 'failed';

  factory WinAIDocument.fromJson(Map<String, dynamic> j) => WinAIDocument(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: j['title'] as String? ?? '',
        fileName: j['fileName'] as String? ?? '',
        status: j['status'] as String? ?? 'pending',
        sizeBytes: (j['sizeBytes'] as num?)?.toInt() ?? 0,
        error: j['error'] as String?,
      );

  WinAISourceRef get ref =>
      WinAISourceRef(type: 'document', id: id, title: title, detail: fileName);
}

/// Usage et plafonds de l'abonnement (-1 : illimité).
class WinAISourceUsage {
  final int files, bytes, maxFiles, maxBytes, maxFileBytes, maxPerMessage;
  final List<String> acceptedTypes;
  const WinAISourceUsage({
    this.files = 0,
    this.bytes = 0,
    this.maxFiles = -1,
    this.maxBytes = -1,
    this.maxFileBytes = 25 * 1024 * 1024,
    this.maxPerMessage = 10,
    this.acceptedTypes = const [],
  });

  factory WinAISourceUsage.fromJson(Map<String, dynamic> j) => WinAISourceUsage(
        files: (j['files'] as num?)?.toInt() ?? 0,
        bytes: (j['bytes'] as num?)?.toInt() ?? 0,
        maxFiles: (j['maxFiles'] as num?)?.toInt() ?? -1,
        maxBytes: (j['maxBytes'] as num?)?.toInt() ?? -1,
        maxFileBytes: (j['maxFileBytes'] as num?)?.toInt() ?? 25 * 1024 * 1024,
        maxPerMessage: (j['maxSourcesPerMessage'] as num?)?.toInt() ?? 10,
        acceptedTypes:
            (j['acceptedTypes'] as List? ?? const []).whereType<String>().toList(),
      );
}

/// Ce que l'écran « Sources » affiche : les fichiers de l'utilisateur avec
/// leur état, et les contenus WinPlus qu'il peut cocher.
class WinAISourcesData {
  final WinAISourceUsage usage;
  final List<WinAIDocument> documents;
  final List<WinAISourceRef> exams, courses;
  final WinAISourceRef? quizMistakes;
  const WinAISourcesData({
    required this.usage,
    required this.documents,
    required this.exams,
    required this.courses,
    this.quizMistakes,
  });
}

/// Refus du serveur, avec un message prêt à afficher.
class WinAISourceException implements Exception {
  final String message;
  const WinAISourceException(this.message);
  @override
  String toString() => message;
}

class WinAISourcesService {
  WinAISourcesService._();
  static final WinAISourcesService instance = WinAISourcesService._();

  final _api = ApiClient.instance;

  static Map<String, dynamic> _data(Object? body) {
    final m = body is Map<String, dynamic> ? body : const <String, dynamic>{};
    final d = m['data'];
    return d is Map<String, dynamic> ? d : m;
  }

  static List<WinAISourceRef> _refs(Object? list) => (list as List? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(WinAISourceRef.fromJson)
      .toList();

  Never _fail(DioException e) {
    final body = e.response?.data;
    final msg = body is Map
        ? (body['error'] is String && (body['error'] as String).contains(' ')
            ? body['error'] as String
            : body['message'] as String?)
        : null;
    throw WinAISourceException(msg ?? L10n.current.commonLoadError);
  }

  /// Fichiers de l'utilisateur, plafonds, et contenus WinPlus disponibles.
  Future<WinAISourcesData> load() async {
    try {
      final own = _data((await _api.dio.get('/winai/sources')).data);
      final all =
          _data((await _api.dio.get('/winai/sources/disponibles')).data);
      final mistakes = all['erreursQuiz'];
      return WinAISourcesData(
        usage: WinAISourceUsage.fromJson(
            own['usage'] as Map<String, dynamic>? ?? const {}),
        documents: (own['sources'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(WinAIDocument.fromJson)
            .toList(),
        exams: _refs(all['epreuves']),
        courses: _refs(all['formations']),
        quizMistakes: mistakes is Map<String, dynamic>
            ? WinAISourceRef.fromJson(mistakes)
            : null,
      );
    } on DioException catch (e) {
      _fail(e);
    }
  }

  /// Téléverse un fichier ; il est ensuite analysé par le serveur (état
  /// « pending » puis « ready »).
  Future<WinAIDocument> upload(List<int> bytes, String fileName) async {
    try {
      // Jusqu'à 25 Mo (serveur 41b2fbe) : sur un réseau lent, l'envoi dépasse
      // le délai habituel (même réglage que la vidéo du répétiteur).
      final res = await _api.dio.post('/winai/sources',
          data: FormData.fromMap(
              {'file': MultipartFile.fromBytes(bytes, filename: fileName)}),
          options: Options(
              sendTimeout: const Duration(minutes: 5),
              receiveTimeout: const Duration(minutes: 2)));
      final d = _data(res.data);
      return WinAIDocument.fromJson(
          d['source'] as Map<String, dynamic>? ?? const {});
    } on DioException catch (e) {
      _fail(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _api.dio.delete('/winai/sources/$id');
    } on DioException catch (e) {
      _fail(e);
    }
  }
}
