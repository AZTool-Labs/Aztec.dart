package com.example.aztec_dart

import android.content.Context
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

object NativeLibraryLoader {
    /**
     * Extracts a native library from assets to the specified directory
     *
     * @param context The application context
     * @param libraryName The name of the library to extract
     * @param directory The directory to extract the library to
     * @return true if the extraction was successful, false otherwise
     */
    fun extractNativeLibrary(context: Context, libraryName: String, directory: String): Boolean {
        val libraryFile = File(directory, libraryName)
        
        // Check if the library already exists and is up to date
        if (libraryFile.exists()) {
            // In a real implementation, you might want to check the version or hash
            // of the library to determine if it needs to be updated
            return true
        }
        
        try {
            // Create the directory if it doesn't exist
            val dir = File(directory)
            if (!dir.exists()) {
                dir.mkdirs()
            }
            
            // Open the library from assets
            context.assets.open("lib/$libraryName").use { inputStream ->
                // Create the output file
                FileOutputStream(libraryFile).use { outputStream ->
                    // Copy the library to the output file
                    val buffer = ByteArray(1024)
                    var read: Int
                    while (inputStream.read(buffer).also { read = it } != -1) {
                        outputStream.write(buffer, 0, read)
                    }
                    outputStream.flush()
                }
            }
            
            // Make the library executable
            libraryFile.setExecutable(true)
            
            return true
        } catch (e: IOException) {
            e.printStackTrace()
            return false
        }
    }
    
    /**
     * Loads a native library from the specified path
     *
     * @param libraryPath The path to the library
     * @return true if the library was loaded successfully, false otherwise
     */
    fun loadLibrary(libraryPath: String): Boolean {
        return try {
            System.load(libraryPath)
            true
        } catch (e: UnsatisfiedLinkError) {
            e.printStackTrace()
            false
        }
    }
}
