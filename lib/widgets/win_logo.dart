import 'package:flutter/material.dart';

/// Logo WinPlus dans un disque blanc.
///
/// Le logo (bleu nuit et sarcelle, fond transparent) se lit mal posé tel quel
/// sur une photo ou sur le vert profond : partout où l'application s'ouvre
/// (démarrage, écrans d'accueil, verrouillage, connexion), il est présenté
/// dans un cercle blanc, comme l'icône de l'application.
class WinLogo extends StatelessWidget {
  /// Diamètre du disque.
  final double size;

  /// Ombre douce sous le disque.
  final bool shadow;
  const WinLogo({super.key, this.size = 96, this.shadow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: shadow
            ? const [
                BoxShadow(
                    color: Color(0x290B3530),
                    blurRadius: 18,
                    offset: Offset(0, 6)),
              ]
            : null,
      ),
      // Le logo occupe 62 % du disque, légèrement abaissé : son « + » en haut
      // à droite le fait paraître décentré sinon.
      child: Padding(
        padding: EdgeInsets.only(top: size * 0.03),
        child: Image.asset('assets/winplus-logo.png',
            width: size * 0.62, excludeFromSemantics: true),
      ),
    );
  }
}
