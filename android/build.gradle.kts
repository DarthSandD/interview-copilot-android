allprojects {
    repositories {
        google()
        mavenCentral()
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

// whisper_ggml hardcodes ndkVersion "29.0.13113456" (a beta build whose
// download is unreliable here). NDK 28 is fully installed and compiles
// whisper.cpp correctly, so force every Android module onto it.
//
// The guard matters: the block above evaluates :app early, and calling
// afterEvaluate on an already-evaluated project throws.
subprojects {
    if (!state.executed) {
        afterEvaluate {
            extensions.findByName("android")?.withGroovyBuilder {
                setProperty("ndkVersion", "28.2.13676358")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
