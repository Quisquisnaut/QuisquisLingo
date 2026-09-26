package org.quisquislingo.app

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.io.FileNotFoundException
import java.io.InputStream
import java.io.OutputStream
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger

/**
 * Android side of QQL's storage bridge.
 *
 * The UI channel shows the system screens: the Storage Access Framework
 * document pickers (Save as… and Open from…), the folder screen that grants
 * Quick Import its folder, and the Android 7–9 storage permission. The I/O
 * channel runs on a background task queue and moves bytes in bounded chunks,
 * so a large file never crosses the channel whole and storage never blocks
 * the UI thread. Dart checks every byte it receives; this side only moves
 * them. See [QuickFolders] for the public `Download/QuisquisLingo` folders.
 */
class QqlStorageBridge(private val activity: Activity) {
    companion object {
        const val UI_CHANNEL = "org.quisquislingo.app/storage"
        const val IO_CHANNEL = "org.quisquislingo.app/storage_io"
        private const val REQUEST_CREATE = 0x5101
        private const val REQUEST_OPEN = 0x5102
        private const val REQUEST_TREE = 0x5103
        private const val REQUEST_PERMISSION = 0x5104
        private const val MAX_CHUNK = 1024 * 1024
    }

    /** One open write: a picked document, or a Download entry being made. */
    private class Writer(
        val uri: Uri,
        val stream: OutputStream,
        val download: QuickFolders.DownloadTarget?,
    )

    private val folders = QuickFolders(activity)
    private var pending: MethodChannel.Result? = null

    /** The folders to create once the pending folder screen grants access. */
    private var pendingTreeFolders: List<String> = emptyList()

    /** What the pending permission request answers: "import" or "write". */
    private var pendingPermissionFor: String? = null
    private val readers = ConcurrentHashMap<Int, InputStream>()
    private val writers = ConcurrentHashMap<Int, Writer>()
    private val nextHandle = AtomicInteger(1)

    fun register(engine: FlutterEngine) {
        val messenger = engine.dartExecutor.binaryMessenger
        MethodChannel(messenger, UI_CHANNEL).setMethodCallHandler(::onUiCall)
        MethodChannel(
            messenger,
            IO_CHANNEL,
            StandardMethodCodec.INSTANCE,
            messenger.makeBackgroundTaskQueue(),
        ).setMethodCallHandler(::onIoCall)
    }

    // ---------------------------------------------------------------- UI

    private fun onUiCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "createDocument" -> {
                val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = call.argument<String>("mimeType") ?: "application/octet-stream"
                    putExtra(Intent.EXTRA_TITLE, call.argument<String>("suggestedName"))
                }
                launch(intent, REQUEST_CREATE, result)
            }
            "openDocuments" -> {
                val mimeTypes = call.argument<List<String>>("mimeTypes").orEmpty()
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = mimeTypes.singleOrNull() ?: "*/*"
                    if (mimeTypes.size > 1) {
                        putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes.toTypedArray())
                    }
                    putExtra(
                        Intent.EXTRA_ALLOW_MULTIPLE,
                        call.argument<Boolean>("multiple") == true,
                    )
                }
                launch(intent, REQUEST_OPEN, result)
            }
            "requestImportAccess" -> {
                if (!folders.scopedStorage) {
                    requestLegacyPermission("import", result)
                    return
                }
                // The folder must exist for the folder screen to open on it.
                folders.ensureRootFolder()
                pendingTreeFolders = call.argument<List<String>>("folders").orEmpty()
                launch(folders.treePickerIntent(), REQUEST_TREE, result)
            }
            "requestLegacyWriteAccess" -> requestLegacyPermission("write", result)
            else -> result.notImplemented()
        }
    }

    private fun launch(intent: Intent, request: Int, result: MethodChannel.Result) {
        if (pending != null) {
            result.error("busy", "Another file dialog is already open.", null)
            return
        }
        pending = result
        try {
            @Suppress("DEPRECATION")
            activity.startActivityForResult(intent, request)
        } catch (error: Exception) {
            pending = null
            result.error("unavailable", error.javaClass.simpleName, null)
        }
    }

    /** Android 7–9 only: the storage permission, asked once by the system. */
    private fun requestLegacyPermission(purpose: String, result: MethodChannel.Result) {
        val answer: (Boolean) -> Any =
            { granted -> if (purpose == "import") (if (granted) "granted" else "denied") else granted }
        if (folders.hasLegacyPermission()) {
            result.success(answer(true))
            return
        }
        if (pending != null) {
            result.error("busy", "Another request is already open.", null)
            return
        }
        pending = result
        pendingPermissionFor = purpose
        activity.requestPermissions(
            arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
            REQUEST_PERMISSION,
        )
    }

    /** From MainActivity.onRequestPermissionsResult; true when it was ours. */
    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != REQUEST_PERMISSION) return false
        val result = pending ?: return true
        val purpose = pendingPermissionFor
        pending = null
        pendingPermissionFor = null
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        result.success(if (purpose == "import") (if (granted) "granted" else "denied") else granted)
        return true
    }

    /** From MainActivity.onActivityResult; true when the result was ours. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CREATE &&
            requestCode != REQUEST_OPEN &&
            requestCode != REQUEST_TREE
        ) {
            return false
        }
        val result = pending ?: return true
        pending = null
        if (requestCode == REQUEST_TREE) {
            result.success(
                if (resultCode != Activity.RESULT_OK) {
                    "cancelled"
                } else {
                    try {
                        folders.acceptTree(data, pendingTreeFolders)
                    } catch (error: Exception) {
                        "denied"
                    }
                },
            )
            return true
        }
        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(null) // cancelled
            return true
        }
        if (requestCode == REQUEST_CREATE) {
            val uri = data.data
            result.success(if (uri == null) null else describe(uri))
            return true
        }
        val uris = mutableListOf<Uri>()
        val clip = data.clipData
        if (clip != null) {
            for (index in 0 until clip.itemCount) uris.add(clip.getItemAt(index).uri)
        } else {
            data.data?.let { uris.add(it) }
        }
        result.success(if (uris.isEmpty()) null else uris.map { describe(it) })
        return true
    }

    private fun describe(uri: Uri): Map<String, Any?> {
        var name: String? = null
        var size: Long? = null
        try {
            activity.contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE),
                null,
                null,
                null,
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val nameColumn = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    val sizeColumn = cursor.getColumnIndex(OpenableColumns.SIZE)
                    if (nameColumn >= 0 && !cursor.isNull(nameColumn)) {
                        name = cursor.getString(nameColumn)
                    }
                    if (sizeColumn >= 0 && !cursor.isNull(sizeColumn)) {
                        size = cursor.getLong(sizeColumn)
                    }
                }
            }
        } catch (ignored: Exception) {
            // The name is only for display; the bytes are checked in Dart.
        }
        return mapOf(
            "uri" to uri.toString(),
            "name" to (name ?: uri.lastPathSegment ?: "file"),
            "size" to size,
        )
    }

    // ---------------------------------------------------------------- I/O

    private fun onIoCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "openRead" -> {
                    val uri = Uri.parse(call.argument<String>("uri"))
                    val stream = activity.contentResolver.openInputStream(uri)
                        ?: throw FileNotFoundException()
                    val handle = nextHandle.getAndIncrement()
                    readers[handle] = stream
                    result.success(handle)
                }
                "read" -> {
                    val stream = readers[call.argument<Int>("handle")!!]
                        ?: throw IllegalStateException("closed")
                    val wanted = (call.argument<Int>("maxBytes") ?: MAX_CHUNK)
                        .coerceIn(1, MAX_CHUNK)
                    val buffer = ByteArray(wanted)
                    val count = stream.read(buffer)
                    result.success(if (count <= 0) ByteArray(0) else buffer.copyOf(count))
                }
                "closeRead" -> {
                    readers.remove(call.argument<Int>("handle")!!)?.close()
                    result.success(null)
                }
                "openWrite" -> {
                    val uri = Uri.parse(call.argument<String>("uri"))
                    val stream = try {
                        openTruncating(uri)
                    } catch (error: Exception) {
                        deleteQuietly(uri)
                        throw error
                    }
                    val handle = nextHandle.getAndIncrement()
                    writers[handle] = Writer(uri, stream, null)
                    result.success(handle)
                }
                "beginDownload" -> {
                    val target = folders.beginDownload(
                        call.argument<String>("relativeFolder")!!,
                        call.argument<String>("baseName")!!,
                        call.argument<String>("extension")!!,
                        call.argument<String>("mimeType") ?: "application/octet-stream",
                        call.argument<Boolean>("replace") == true,
                    )
                    val stream = try {
                        openTruncating(target.uri)
                    } catch (error: Exception) {
                        folders.finishDownload(target, keep = false)
                        throw error
                    }
                    val handle = nextHandle.getAndIncrement()
                    writers[handle] = Writer(target.uri, stream, target)
                    result.success(handle)
                }
                "write" -> {
                    val writer = writers[call.argument<Int>("handle")!!]
                        ?: throw IllegalStateException("closed")
                    writer.stream.write(call.argument<ByteArray>("bytes")!!)
                    result.success(null)
                }
                "closeWrite" -> {
                    val writer = writers.remove(call.argument<Int>("handle")!!)
                    val keep = call.argument<Boolean>("keep") == true
                    result.success(if (writer == null) null else finishWrite(writer, keep))
                }
                "storageInfo" -> result.success(folders.storageInfo())
                "hasImportAccess" -> result.success(folders.hasImportAccess())
                "listImports" -> {
                    val segments = call.argument<List<String>>("segments").orEmpty()
                    val items = try {
                        folders.listImports(segments)
                    } catch (error: SecurityException) {
                        null
                    } catch (error: FileNotFoundException) {
                        null
                    } catch (error: IllegalArgumentException) {
                        null
                    }
                    if (items == null) {
                        result.error("accessRequired", "Quick Import access is missing.", null)
                    } else {
                        result.success(items)
                    }
                }
                "listTree" -> result.success(
                    folders.listTree(call.argument<List<String>>("segments").orEmpty()),
                )
                "deleteTree" -> result.success(
                    folders.deleteTree(call.argument<List<String>>("segments").orEmpty()),
                )
                "releaseImportAccess" -> {
                    folders.releaseImportAccess()
                    result.success(null)
                }
                "listOwnDownloads" -> result.success(
                    folders.listOwnDownloads(call.argument<String>("relativePrefix")!!),
                )
                "deleteOwnDownloads" -> result.success(
                    folders.deleteOwnDownloads(call.argument<String>("relativePrefix")!!),
                )
                "scanFile" -> {
                    folders.scanFile(call.argument<String>("path")!!)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (error: Exception) {
            // The message may name a document; Dart logs the type only.
            result.error("io", error.javaClass.simpleName, null)
        }
    }

    private fun openTruncating(uri: Uri): OutputStream {
        val resolver = activity.contentResolver
        val stream = try {
            resolver.openOutputStream(uri, "wt")
        } catch (unsupported: IllegalArgumentException) {
            resolver.openOutputStream(uri, "w")
        } catch (unsupported: UnsupportedOperationException) {
            resolver.openOutputStream(uri, "w")
        }
        return stream ?: throw FileNotFoundException()
    }

    /**
     * Closes a write. A picked document that failed or was abandoned is
     * deleted; a Download entry is published or removed. Returns the Download
     * entry's final name, or null for a picked document.
     */
    private fun finishWrite(writer: Writer, keep: Boolean): String? {
        var closed = false
        try {
            writer.stream.close()
            closed = true
        } finally {
            if (!keep || !closed) {
                val download = writer.download
                if (download == null) {
                    deleteQuietly(writer.uri)
                } else {
                    folders.finishDownload(download, keep = false)
                }
            }
        }
        if (!keep) return null
        return writer.download?.let { folders.finishDownload(it, keep = true) }
    }

    /** Best effort: an empty document may stay where the user chose. */
    private fun deleteQuietly(uri: Uri) {
        try {
            DocumentsContract.deleteDocument(activity.contentResolver, uri)
        } catch (ignored: Exception) {
        }
    }
}
