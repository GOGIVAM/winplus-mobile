import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/auth/reset_password_screen.dart';
import 'package:winplus/services/deep_links.dart';

/// Liens du site ouverts dans l'application : seul le lien « mot de passe
/// oublié » a un écran mobile, sur les hôtes du site.
void main() {
  test('lien de reinitialisation : ecran du nouveau mot de passe avec le jeton decode', () {
    final page = DeepLinks.pageFor(Uri.parse('https://winplus.cm/reset-password/abc%2B123'));
    expect(page, isA<ResetPasswordScreen>());
    expect((page! as ResetPasswordScreen).token, 'abc+123');
  });

  test('www et integration sont acceptes', () {
    expect(DeepLinks.pageFor(Uri.parse('https://www.winplus.cm/reset-password/t')), isA<ResetPasswordScreen>());
    expect(DeepLinks.pageFor(Uri.parse('https://integration.winplus.cm/reset-password/t')), isA<ResetPasswordScreen>());
  });

  test('autre hote, autre chemin ou jeton absent : rien n\'est ouvert', () {
    expect(DeepLinks.pageFor(Uri.parse('https://exemple.com/reset-password/t')), isNull);
    expect(DeepLinks.pageFor(Uri.parse('https://winplus.cm/verify/ABC')), isNull);
    expect(DeepLinks.pageFor(Uri.parse('https://winplus.cm/reset-password/')), isNull);
    expect(DeepLinks.pageFor(Uri.parse('https://winplus.cm/reset-password/a/b')), isNull);
  });
}
