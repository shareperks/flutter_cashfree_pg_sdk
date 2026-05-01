buildscript {
    // Some 3rd-party plugins still expect this legacy Gradle property.
    extra.set("kotlin_version", "2.2.20")
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://artifactory.smallcase.com/artifactory/SCGateway")
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
