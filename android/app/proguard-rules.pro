# Keep Flutter engine and plugin classes.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep SourceFile/LineNumber for crash stack traces.
-keepattributes SourceFile,LineNumberTable

# Keep annotations used by common Android/Kotlin libraries.
-keepattributes *Annotation*

# Do not warn for optional metadata used by support libraries.
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement
