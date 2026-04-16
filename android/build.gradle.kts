// buildscript block DIHAPUS — sudah ditangani oleh settings.gradle.kts
// Mendaftarkan plugin via settings.gradle.kts adalah cara yang benar
// untuk Flutter project dengan Gradle modern (versi 7+)

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    afterEvaluate {
        extensions.findByType(com.android.build.gradle.LibraryExtension::class)?.apply {
            compileSdk = 35
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}