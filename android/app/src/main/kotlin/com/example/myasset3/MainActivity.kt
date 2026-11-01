package com.example.myasset3

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {

    private val channelName = "myasset/gallery"
    private val pickImageRequest = 1001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->

            when (call.method) {
                "pickImage" -> {
                    if (pendingResult != null) {
                        result.error(
                            "BUSY",
                            "Pemilih foto sedang dibuka",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    pendingResult = result

                    try {
                        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                            type = "image/*"
                            addCategory(Intent.CATEGORY_OPENABLE)
                        }

                        startActivityForResult(
                            Intent.createChooser(intent, "Pilih Foto Aset"),
                            pickImageRequest
                        )
                    } catch (e: Exception) {
                        pendingResult = null
                        result.error(
                            "GALLERY_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != pickImageRequest) return

        val result = pendingResult ?: return
        pendingResult = null

        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }

        val uri: Uri? = data?.data

        if (uri == null) {
            result.error(
                "NO_IMAGE",
                "Foto tidak ditemukan",
                null
            )
            return
        }

        try {
            val directory = File(filesDir, "asset_photos")

            if (!directory.exists()) {
                directory.mkdirs()
            }

            val filename =
                "asset_${System.currentTimeMillis()}_${System.nanoTime()}.jpg"

            val destination = File(directory, filename)

            contentResolver.openInputStream(uri).use { input ->
                if (input == null) {
                    throw Exception("Tidak bisa membaca foto")
                }

                FileOutputStream(destination).use { output ->
                    input.copyTo(output)
                }
            }

            result.success(destination.absolutePath)

        } catch (e: Exception) {
            result.error(
                "SAVE_IMAGE_ERROR",
                e.message,
                null
            )
        }
    }
}