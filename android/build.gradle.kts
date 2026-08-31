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
// Certains plugins Flutter (ex. another_telephony) ciblent encore la JVM 1.8, ce qui
// entre en conflit avec la cible Java d'AGP. On aligne tout le monde sur la 17.
// À déclarer avant le bloc `evaluationDependsOn` ci-dessous, sinon `:app` est déjà
// évalué quand on tente d'enregistrer le `afterEvaluate`.
subprojects {
    afterEvaluate {
        extensions
            .findByType(com.android.build.api.dsl.CommonExtension::class.java)
            ?.compileOptions
            ?.apply {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
