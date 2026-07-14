package ananda.yoga.nara

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var pendingResult: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BACKUP_CHANNEL,
        ).setMethodCallHandler(::handleBackupCall)
    }

    private fun handleBackupCall(call: MethodCall, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "Pemilih file sedang digunakan.", null)
            return
        }
        when (call.method) {
            "saveBackup" -> startSave(call, result)
            "openBackup" -> startOpen(result)
            else -> result.notImplemented()
        }
    }

    private fun startSave(call: MethodCall, result: MethodChannel.Result) {
        val bytes = call.argument<ByteArray>("bytes")
        val name = call.argument<String>("name")
        if (bytes == null || name == null) {
            result.error("invalid_arguments", "Data backup tidak valid.", null)
            return
        }
        pendingResult = result
        pendingBytes = bytes
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = BACKUP_MIME
            putExtra(Intent.EXTRA_TITLE, name)
        }
        startActivityForResult(intent, REQUEST_SAVE_BACKUP)
    }

    private fun startOpen(result: MethodChannel.Result) {
        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf(BACKUP_MIME))
        }
        startActivityForResult(intent, REQUEST_OPEN_BACKUP)
    }

    @Deprecated("Deprecated by Android, retained for Flutter Activity result interop")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_SAVE_BACKUP && requestCode != REQUEST_OPEN_BACKUP) return
        val result = pendingResult ?: return
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            if (requestCode == REQUEST_SAVE_BACKUP) result.success(false) else result.success(null)
            clearPending()
            return
        }
        try {
            if (requestCode == REQUEST_SAVE_BACKUP) {
                writeBackup(uri, requireNotNull(pendingBytes))
                result.success(true)
            } else {
                result.success(readBackup(uri))
            }
        } catch (error: Exception) {
            result.error("file_io", "File backup tidak dapat diproses.", error.message)
        } finally {
            clearPending()
        }
    }

    private fun writeBackup(uri: Uri, bytes: ByteArray) {
        contentResolver.openOutputStream(uri, "w").use { stream ->
            requireNotNull(stream) { "Output stream tidak tersedia." }
            stream.write(bytes)
            stream.flush()
        }
    }

    private fun readBackup(uri: Uri): ByteArray =
        contentResolver.openInputStream(uri).use { stream ->
            requireNotNull(stream) { "Input stream tidak tersedia." }
            stream.readBytes()
        }

    private fun clearPending() {
        pendingResult = null
        pendingBytes = null
    }

    companion object {
        private const val BACKUP_CHANNEL = "ananda.yoga.nara/backup_files"
        private const val BACKUP_MIME = "application/vnd.nara.backup"
        private const val REQUEST_SAVE_BACKUP = 6101
        private const val REQUEST_OPEN_BACKUP = 6102
    }
}
