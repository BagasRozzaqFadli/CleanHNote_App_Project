
import 'package:appwrite/appwrite.dart';

class AppwriteService {
  static const String endpoint = 'https://fra.cloud.appwrite.io/v1';
  static const String projectId = '68e8a86b003d5067a4c4';

  static Client getClient() {
    return Client()
      ..setEndpoint(endpoint)
      ..setProject(projectId)
      ..setSelfSigned(status: true);
  }
}
