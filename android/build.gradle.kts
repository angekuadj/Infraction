import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

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

fun Project.forceCompileSdk(version: Int) {
    val android = extensions.findByName("android") ?: return
    val cls = android.javaClass
    for (name in listOf("setCompileSdk", "setCompileSdkVersion")) {
        for (paramType in listOf(Int::class.javaPrimitiveType, Int::class.javaObjectType)) {
            try {
                cls.getMethod(name, paramType).invoke(android, version)
                return
            } catch (_: Exception) {
            }
        }
    }
}

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.add("-Xlint:-options")
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    plugins.withId("com.android.library") {
        dependencies.add(
            "implementation",
            "androidx.concurrent:concurrent-futures:1.2.0",
        )
    }
    plugins.withId("com.android.application") {
        dependencies.add(
            "implementation",
            "androidx.concurrent:concurrent-futures:1.2.0",
        )
    }

    if (state.executed) {
        forceCompileSdk(36)
    } else {
        afterEvaluate { forceCompileSdk(36) }
    }

}

gradle.projectsEvaluated {
    rootProject.subprojects.forEach { project ->
        val javaTarget = project.tasks
            .withType<JavaCompile>()
            .firstOrNull()
            ?.targetCompatibility
            ?: JavaVersion.VERSION_17.toString()
        val jvmTarget = when (javaTarget) {
            "1.8", "8" -> JvmTarget.JVM_1_8
            "11" -> JvmTarget.JVM_11
            "17" -> JvmTarget.JVM_17
            "21" -> JvmTarget.JVM_21
            else -> JvmTarget.JVM_17
        }
        project.tasks.withType<KotlinCompile>().configureEach {
            compilerOptions {
                this.jvmTarget.set(jvmTarget)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
