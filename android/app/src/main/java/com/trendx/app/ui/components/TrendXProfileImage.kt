package com.trendx.app.ui.components

import android.graphics.BitmapFactory
import android.util.Base64
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import coil.compose.SubcomposeAsyncImage

// Mirrors `TrendXProfileImage` on iOS — accepts either an HTTPS URL
// (Vercel Blob, gravatar, etc.) or a base64 `data:image/...;base64,…`
// URI produced by ProfileEditScreen's PhotosPicker pipeline. Coil's
// AsyncImage handles HTTPS natively but silently fails on data URIs,
// which was why uploaded avatars showed the initial fallback even
// after a successful save.
@Composable
fun TrendXProfileImage(
    urlString: String?,
    modifier: Modifier = Modifier,
    contentScale: ContentScale = ContentScale.Crop,
    fallback: @Composable () -> Unit
) {
    when {
        urlString.isNullOrBlank() -> fallback()
        urlString.startsWith("data:") -> {
            val bitmap = remember(urlString) { decodeDataUri(urlString) }
            if (bitmap != null) {
                Image(
                    bitmap = bitmap, contentDescription = null,
                    contentScale = contentScale, modifier = modifier
                )
            } else {
                fallback()
            }
        }
        else -> SubcomposeAsyncImage(
            model = urlString,
            contentDescription = null,
            contentScale = contentScale,
            loading = { Box(modifier = modifier) { fallback() } },
            error = { Box(modifier = modifier) { fallback() } },
            modifier = modifier
        )
    }
}

private fun decodeDataUri(uri: String): ImageBitmap? {
    return try {
        val base64Part = uri.substringAfter("base64,", missingDelimiterValue = "")
        if (base64Part.isEmpty()) return null
        val bytes = Base64.decode(base64Part, Base64.DEFAULT)
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size)?.asImageBitmap()
    } catch (_: Throwable) {
        null
    }
}
