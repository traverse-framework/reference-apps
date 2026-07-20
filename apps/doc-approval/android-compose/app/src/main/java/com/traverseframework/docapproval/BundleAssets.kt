package com.traverseframework.docapproval

import android.content.Context
import java.io.File

/** Copies bundled Traverse runtime assets from APK assets into app filesDir. */
object BundleAssets {
    fun materialize(context: Context, assetDir: String = AppConstants.BUNDLE_ASSET_DIR): File {
        val dest = File(context.filesDir, assetDir)
        copyAssetTree(context, assetDir, dest)
        return dest
    }

    private fun copyAssetTree(context: Context, assetPath: String, destDir: File) {
        val children = context.assets.list(assetPath) ?: return
        if (children.isEmpty()) {
            // leaf file
            destDir.parentFile?.mkdirs()
            context.assets.open(assetPath).use { input ->
                destDir.outputStream().use { output -> input.copyTo(output) }
            }
            return
        }
        destDir.mkdirs()
        for (child in children) {
            val childAsset = "$assetPath/$child"
            val childDest = File(destDir, child)
            val grand = context.assets.list(childAsset)
            if (grand.isNullOrEmpty()) {
                context.assets.open(childAsset).use { input ->
                    childDest.outputStream().use { output -> input.copyTo(output) }
                }
            } else {
                copyAssetTree(context, childAsset, childDest)
            }
        }
    }
}
