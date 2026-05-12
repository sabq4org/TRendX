# kotlinx.serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keepclassmembers class kotlinx.serialization.json.** { *** Companion; }
-keepclasseswithmembers class kotlinx.serialization.json.** { kotlinx.serialization.KSerializer serializer(...); }
-keep,includedescriptorclasses class com.trendx.app.**$$serializer { *; }
-keepclassmembers class com.trendx.app.** { *** Companion; }
-keepclasseswithmembers class com.trendx.app.** { kotlinx.serialization.KSerializer serializer(...); }
