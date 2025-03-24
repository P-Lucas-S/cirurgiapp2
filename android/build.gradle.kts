plugins {
    // Aplica o plugin do Google Services apenas onde for necessário
    id("com.google.gms.google-services") version "4.3.15" apply false
}

buildscript {
    // Atualizado para Kotlin 2.1.20 para compatibilidade com as bibliotecas que usam metadata 2.1.x
    val kotlinVersion = "2.1.20"

    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.4.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Configuração de diretório de build compartilhado para o projeto raiz e seus subprojetos
val sharedBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(sharedBuildDir)

subprojects {
    layout.buildDirectory.set(sharedBuildDir.dir(name))
    evaluationDependsOn(":app")
}

// Tarefa para limpar o diretório de build
tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
