-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

-keepattributes SourceFile,LineNumberTable

# Razorpay Checkout
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}
-optimizations !method/inlining/
-keepclasseswithmembers class * {
  public void onPayment*(...);
}

# OneSignal
-dontwarn com.onesignal.**
-keep class com.onesignal.** { *; }
-keep interface com.onesignal.** { *; }

-ignorewarnings
-keep class * {
    public private *;
}
