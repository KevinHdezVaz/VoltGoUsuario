# Flutter Stripe
-keep class com.stripe.android.** { *; }
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.stripe.android.**
-dontwarn com.reactnativestripesdk.**

# Keep Stripe Push Provisioning classes
-keep class com.stripe.android.pushProvisioning.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**

# Keep all classes referenced by Stripe
-keep class * implements com.stripe.android.core.StripeError { *; }
-keep class * extends com.stripe.android.core.model.StripeModel { *; }

# Additional rules for R8
-keepattributes Signature
-keepattributes *Annotation*
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }