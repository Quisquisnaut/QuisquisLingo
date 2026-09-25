package org.quisquislingo.app

import android.Manifest
import android.app.Activity
import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import java.io.File
import java.io.FileNotFoundException
import java.io.IOException

/**
 * The public QQL folders on Android, `Download/QuisquisLingo/Imports` and
 * `Download/QuisquisLingo/Exports`.
 *
 * Android 10 and later: Quick Export writes through MediaStore Downloads,
 * which needs no permission and no dialog; Quick Import reads through one
 * persisted folder permission (a Storage Access Framework tree) on exactly
 * `Download/QuisquisLingo/Imports`. Android 7–9 use ordinary files in the
 * Download folder once the storage permission is granted; Dart does that
 * part. Nothing here uses app-private storage for these folders.
 */
class QuickFolders(private val activity: Activity) {
    companion object {
        const val AUTHORITY = "com.android.externalstorage.documents"
        val IMPORTS_DOC_ID = "primary:${Environment.DIRECTORY_DOWNLOADS}/QuisquisLingo/Imports"
        val CATEGORY_FOLDERS = listOf("Courses", "Merges", "Audio", "Images", "Lesson Icons")
    }

    private val resolver get() = activity.contentResolver

    /** Android 10 and later: MediaStore and folder permissions. */
    val scopedStorage: Boolean get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q

    fun storageInfo(): Map<String, Any?> = mapOf(
        "sdk" to Build.VERSION.SDK_INT,
        "scoped" to scopedStorage,
        "downloadsPath" to downloadsDirectory().absolutePath,
    )

    @Suppress("DEPRECATION")
    private fun downloadsDirectory(): File =
        Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)

    /** Android 7–9: the storage permission. Always true from Android 10. */
    fun hasLegacyPermission(): Boolean =
        scopedStorage || activity.checkSelfPermission(
            Manifest.permission.WRITE_EXTERNAL_STORAGE,
        ) == PackageManager.PERMISSION_GRANTED

    // ---------------------------------------------------------------- Imports

    private fun isImportsTree(uri: Uri?): Boolean {
        if (uri == null || uri.authority != AUTHORITY) return false
        return try {
            DocumentsContract.getTreeDocumentId(uri).equals(IMPORTS_DOC_ID, ignoreCase = true)
        } catch (ignored: IllegalArgumentException) {
            false
        }
    }

    /** The persisted Imports permission, while QQL still holds it. */
    private fun importsTree(): Uri? = resolver.persistedUriPermissions
        .firstOrNull { it.isReadPermission && isImportsTree(it.uri) }
        ?.uri

    /**
     * True when Quick Import can read now. Android 10 and later: the folder
     * permission is held and the folder is still there (a deleted or renamed
     * folder counts as no access); Android 7–9: the storage permission.
     */
    fun hasImportAccess(): Boolean {
        if (!scopedStorage) return hasLegacyPermission()
        val tree = importsTree() ?: return false
        return try {
            val root = DocumentsContract.buildDocumentUriUsingTree(
                tree,
                DocumentsContract.getTreeDocumentId(tree),
            )
            resolver.query(
                root,
                arrayOf(DocumentsContract.Document.COLUMN_MIME_TYPE),
                null,
                null,
                null,
            )?.use {
                it.moveToFirst() && it.getString(0) == DocumentsContract.Document.MIME_TYPE_DIR
            } ?: false
        } catch (ignored: Exception) {
            false
        }
    }

    /** Makes Download/QuisquisLingo/Imports exist before the folder screen opens on it. */
    fun ensureImportsFolder() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            File(downloadsDirectory(), "QuisquisLingo/Imports").mkdirs()
            return
        }
        // Android 10 has no direct file access to Download: a pending
        // placeholder makes MediaStore create the folders, then it goes.
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, ".quisquislingo")
            put(
                MediaStore.MediaColumns.RELATIVE_PATH,
                "${Environment.DIRECTORY_DOWNLOADS}/QuisquisLingo/Imports/",
            )
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        try {
            resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)?.let {
                resolver.delete(it, null, null)
            }
        } catch (ignored: Exception) {
        }
    }

    fun treePickerIntent(): Intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            putExtra(
                DocumentsContract.EXTRA_INITIAL_URI,
                DocumentsContract.buildDocumentUri(AUTHORITY, IMPORTS_DOC_ID),
            )
        }
        addFlags(
            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
        )
    }

    /**
     * Keeps the permission the folder screen returned when it is exactly the
     * Imports folder, and creates the category folders inside it.
     */
    fun acceptTree(data: Intent?): String {
        val tree = data?.data ?: return "cancelled"
        if (!isImportsTree(tree)) return "wrongFolder"
        val flags = data.flags and
            (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        resolver.takePersistableUriPermission(tree, flags)
        for (name in CATEGORY_FOLDERS) {
            try {
                childDirectory(tree, DocumentsContract.getTreeDocumentId(tree), name, create = true)
            } catch (ignored: Exception) {
            }
        }
        return "granted"
    }

    fun releaseImportAccess() {
        for (permission in resolver.persistedUriPermissions) {
            if (isImportsTree(permission.uri)) {
                resolver.releasePersistableUriPermission(
                    permission.uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
                )
            }
        }
    }

    private class Child(
        val id: String,
        val name: String,
        val mime: String,
        val size: Long?,
        val modified: Long?,
    )

    private fun children(tree: Uri, parentId: String): List<Child> {
        val out = mutableListOf<Child>()
        resolver.query(
            DocumentsContract.buildChildDocumentsUriUsingTree(tree, parentId),
            arrayOf(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                DocumentsContract.Document.COLUMN_MIME_TYPE,
                DocumentsContract.Document.COLUMN_SIZE,
                DocumentsContract.Document.COLUMN_LAST_MODIFIED,
            ),
            null,
            null,
            null,
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                out.add(
                    Child(
                        cursor.getString(0),
                        cursor.getString(1) ?: "",
                        cursor.getString(2) ?: "",
                        if (cursor.isNull(3)) null else cursor.getLong(3),
                        if (cursor.isNull(4)) null else cursor.getLong(4),
                    ),
                )
            }
        } ?: throw FileNotFoundException()
        return out
    }

    private fun childDirectory(tree: Uri, parentId: String, name: String, create: Boolean): String? {
        val existing = children(tree, parentId).firstOrNull {
            it.mime == DocumentsContract.Document.MIME_TYPE_DIR && it.name == name
        }
        if (existing != null) return existing.id
        if (!create) return null
        val created = DocumentsContract.createDocument(
            resolver,
            DocumentsContract.buildDocumentUriUsingTree(tree, parentId),
            DocumentsContract.Document.MIME_TYPE_DIR,
            name,
        ) ?: throw IOException("create")
        return DocumentsContract.getDocumentId(created)
    }

    /** The files (not folders) in Imports/[segments]; missing folders are created. */
    fun listImports(segments: List<String>): List<Map<String, Any?>> {
        val tree = importsTree() ?: throw SecurityException("accessRequired")
        var id = DocumentsContract.getTreeDocumentId(tree)
        for (segment in segments) id = childDirectory(tree, id, segment, create = true)!!
        return children(tree, id)
            .filter { it.mime != DocumentsContract.Document.MIME_TYPE_DIR }
            .map {
                mapOf(
                    "uri" to DocumentsContract.buildDocumentUriUsingTree(tree, it.id).toString(),
                    "name" to it.name,
                    "size" to it.size,
                )
            }
    }

    /** Every file below Imports, named relative to it, for Inventory. */
    fun listAllImports(): List<Map<String, Any?>> {
        val tree = importsTree() ?: return emptyList()
        val out = mutableListOf<Map<String, Any?>>()
        fun walk(parentId: String, prefix: String) {
            for (child in children(tree, parentId)) {
                if (child.mime == DocumentsContract.Document.MIME_TYPE_DIR) {
                    walk(child.id, "$prefix${child.name}/")
                } else {
                    out.add(
                        mapOf(
                            "name" to "$prefix${child.name}",
                            "size" to child.size,
                            "modified" to child.modified,
                        ),
                    )
                }
            }
        }
        try {
            walk(DocumentsContract.getTreeDocumentId(tree), "")
        } catch (ignored: Exception) {
        }
        return out
    }

    /** Deletes everything below Imports, keeping the folder. Returns the file count. */
    fun deleteImports(): Int {
        val files = listAllImports().size
        val tree = importsTree() ?: return 0
        for (child in children(tree, DocumentsContract.getTreeDocumentId(tree))) {
            try {
                DocumentsContract.deleteDocument(
                    resolver,
                    DocumentsContract.buildDocumentUriUsingTree(tree, child.id),
                )
            } catch (ignored: Exception) {
            }
        }
        return files
    }

    // ---------------------------------------------------------------- Exports

    private fun ownDownload(relative: String, name: String): Uri? {
        val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
        return resolver.query(
            collection,
            arrayOf(MediaStore.MediaColumns._ID),
            "${MediaStore.MediaColumns.RELATIVE_PATH}=? AND ${MediaStore.MediaColumns.DISPLAY_NAME}=?",
            arrayOf(relative, name),
            null,
        )?.use { if (it.moveToFirst()) ContentUris.withAppendedId(collection, it.getLong(0)) else null }
    }

    class DownloadTarget(val uri: Uri, val inserted: Boolean)

    /**
     * Chooses the name (name.ext, name_2.ext, … among QQL's own Download
     * entries; the existing one when [replace]) and makes the entry, pending
     * until [finishDownload]. Android may still add " (1)" when another app's
     * file already has the name; the final name is reported.
     */
    fun beginDownload(
        relativeFolder: String,
        baseName: String,
        extension: String,
        mimeType: String,
        replace: Boolean,
    ): DownloadTarget {
        val relative = relativeFolder.trimEnd('/') + "/"
        var name = "$baseName.$extension"
        if (replace) {
            ownDownload(relative, name)?.let { return DownloadTarget(it, inserted = false) }
        } else {
            var suffix = 2
            while (ownDownload(relative, name) != null) {
                name = "${baseName}_$suffix.$extension"
                suffix++
            }
        }
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, relative)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IOException("insert")
        return DownloadTarget(uri, inserted = true)
    }

    /** Publishes a finished entry (returning its final name), or removes an unfinished one. */
    fun finishDownload(target: DownloadTarget, keep: Boolean): String? {
        if (!keep) {
            if (target.inserted) {
                try {
                    resolver.delete(target.uri, null, null)
                } catch (ignored: Exception) {
                }
            }
            return null
        }
        if (target.inserted) {
            val values = ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }
            resolver.update(target.uri, values, null, null)
        }
        return resolver.query(
            target.uri,
            arrayOf(MediaStore.MediaColumns.DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { if (it.moveToFirst()) it.getString(0) else null }
    }

    /** QQL's own Download entries below [relativePrefix], for Inventory. */
    fun listOwnDownloads(relativePrefix: String): List<Map<String, Any?>> {
        val prefix = relativePrefix.trimEnd('/') + "/"
        val out = mutableListOf<Map<String, Any?>>()
        resolver.query(
            MediaStore.Downloads.EXTERNAL_CONTENT_URI,
            arrayOf(
                MediaStore.MediaColumns.DISPLAY_NAME,
                MediaStore.MediaColumns.RELATIVE_PATH,
                MediaStore.MediaColumns.SIZE,
                MediaStore.MediaColumns.DATE_MODIFIED,
            ),
            "${MediaStore.MediaColumns.RELATIVE_PATH} LIKE ?",
            arrayOf("$prefix%"),
            null,
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                val below = (cursor.getString(1) ?: "").removePrefix(prefix)
                out.add(
                    mapOf(
                        "name" to below + (cursor.getString(0) ?: ""),
                        "size" to if (cursor.isNull(2)) null else cursor.getLong(2),
                        "modified" to if (cursor.isNull(3)) null else cursor.getLong(3) * 1000,
                    ),
                )
            }
        }
        return out
    }

    /** Deletes QQL's own Download entries below [relativePrefix]. Returns the count. */
    fun deleteOwnDownloads(relativePrefix: String): Int {
        val prefix = relativePrefix.trimEnd('/') + "/"
        return resolver.delete(
            MediaStore.Downloads.EXTERNAL_CONTENT_URI,
            "${MediaStore.MediaColumns.RELATIVE_PATH} LIKE ?",
            arrayOf("$prefix%"),
        )
    }

    /** Android 7–9: lets file managers and the Downloads app see a new file. */
    fun scanFile(path: String) {
        MediaScannerConnection.scanFile(activity, arrayOf(path), null, null)
    }
}
