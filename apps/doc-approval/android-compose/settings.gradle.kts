pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "doc-approval-android"

val traverseRepo = System.getenv("TRAVERSE_REPO")
    ?: rootDir.resolve("../../../../Traverse").takeIf { it.resolve("packages/kotlin/TraverseEmbedder").exists() }?.absolutePath
    ?: rootDir.resolve("../../../Traverse").takeIf { it.resolve("packages/kotlin/TraverseEmbedder").exists() }?.absolutePath

include(":app")

if (traverseRepo != null) {
    include(":traverse-embedder")
    project(":traverse-embedder").projectDir =
        file("$traverseRepo/packages/kotlin/TraverseEmbedder/traverse-embedder")
}
