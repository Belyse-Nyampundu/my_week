tasks.register("assembleDebug") {
    group = "build"
    description = "Assembles the debug APK from the Flutter Android build in android/."
    dependsOn(gradle.includedBuild("android").task(":app:assembleDebug"))
}

tasks.register("assembleRelease") {
    group = "build"
    description = "Assembles the release APK from the Flutter Android build in android/."
    dependsOn(gradle.includedBuild("android").task(":app:assembleRelease"))
}
