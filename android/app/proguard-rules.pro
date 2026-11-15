# Règles R8 de WinPlus (version de production).
# Les règles de Flutter et des greffons sont ajoutées automatiquement ;
# on ne garde ici que ce que l'analyse de R8 ne peut pas deviner.

# Flutter référence la bibliothèque Play Core (composants différés) sans
# l'embarquer : sans ces lignes, R8 s'arrête sur des classes manquantes.
-dontwarn com.google.android.play.core.**

# flutter_secure_storage : chiffrement par Tink, chargé par réflexion.
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**

# Canal natif de l'application (protection d'écran) : appelé depuis Dart.
-keep class cm.winplus.** { *; }
-keep class com.example.winplus.** { *; }

# flutter_local_notifications : les notifications planifiées sont
# enregistrées en JSON par Gson (réflexion sur les champs et les types génériques).
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# workmanager et flutter_foreground_task : tâches et service relancés par le
# système (par leur nom de classe).
-keep class dev.fluttercommunity.workmanager.** { *; }
-keep class com.pravera.flutter_foreground_task.** { *; }
