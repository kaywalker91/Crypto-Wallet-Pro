import com.android.build.gradle.LibraryExtension
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

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    if (name == "qr_code_scanner") {
        plugins.withId("com.android.library") {
            extensions.configure<LibraryExtension> {
                if (namespace == null) {
                    namespace = "net.touchcapture.qr.flutterqr"
                }
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_1_8
                    targetCompatibility = JavaVersion.VERSION_1_8
                    isCoreLibraryDesugaringEnabled = true
                }
            }
            dependencies {
                add("coreLibraryDesugaring", "com.android.tools:desugar_jdk_libs:2.0.4")
            }
        }
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_1_8.toString()
            targetCompatibility = JavaVersion.VERSION_1_8.toString()
        }
        tasks.withType<KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
