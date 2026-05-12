package com.trendx.app.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.foundation.layout.offset
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.SubcomposeAsyncImage
import com.trendx.app.theme.PollCoverStyle
import com.trendx.app.theme.TrendXColors

// Mirrors TrendXEditorialCover + PollCoverView from SharedComponents.swift —
// editorial hero with layered gradient, dotted texture, soft sheen, large
// watermark glyph and TRENDX badge + topic phrase. When `imageUrl` is set,
// renders the photo with a darken-gradient and topic chip overlaid.
@Composable
fun TrendXEditorialCover(
    imageUrl: String?,
    style: PollCoverStyle,
    height: Dp = 140.dp,
    showsTopicOverlay: Boolean = true,
    modifier: Modifier = Modifier
) {
    if (!imageUrl.isNullOrBlank()) {
        Box(
            modifier = modifier
                .fillMaxWidth()
                .height(height)
                .shadow(elevation = 14.dp, shape = RoundedCornerShape(16.dp), clip = false,
                    ambientColor = style.tint, spotColor = style.tint)
                .clip(RoundedCornerShape(16.dp))
                .border(0.8.dp, Color.White.copy(alpha = 0.10f), RoundedCornerShape(16.dp))
        ) {
            SubcomposeAsyncImage(
                model = imageUrl,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                loading = { PollCoverGradient(style = style) },
                error = { PollCoverGradient(style = style) },
                modifier = Modifier.fillMaxSize()
            )
            if (showsTopicOverlay) {
                Box(modifier = Modifier
                    .fillMaxWidth()
                    .height(height * 0.55f)
                    .align(Alignment.BottomStart)
                    .background(Brush.verticalGradient(listOf(Color.Transparent, Color.Black.copy(alpha = 0.55f)))))
                TopicChipOverlay(style = style, modifier = Modifier
                    .align(Alignment.BottomStart)
                    .padding(12.dp))
            }
        }
    } else {
        PollCoverGradient(style = style, height = height, modifier = modifier)
    }
}

@Composable
private fun PollCoverGradient(
    style: PollCoverStyle,
    height: Dp = 140.dp,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(height)
            .shadow(elevation = 14.dp, shape = RoundedCornerShape(16.dp), clip = false,
                ambientColor = style.tint, spotColor = style.tint)
            .clip(RoundedCornerShape(16.dp))
            .background(style.gradient)
            .border(0.8.dp, Color.White.copy(alpha = 0.12f), RoundedCornerShape(16.dp))
    ) {
        // Layered blur-feel blobs — Compose can't blur cheaply, so we use
        // soft alpha layering and gradient overlays to evoke the same
        // depth as the iOS PollCoverView.
        Canvas(modifier = Modifier.fillMaxSize()) {
            drawCircle(
                color = Color.White.copy(alpha = 0.20f),
                radius = size.width * 0.30f,
                center = Offset(x = size.width * 0.18f, y = size.height * 0.85f)
            )
            drawCircle(
                color = Color.Black.copy(alpha = 0.16f),
                radius = size.width * 0.28f,
                center = Offset(x = size.width * 0.85f, y = size.height * 1.05f)
            )
            // Dot grid texture
            val spacing = 12f
            var x = spacing / 2
            while (x < size.width) {
                var y = spacing / 2
                while (y < size.height) {
                    drawCircle(
                        color = Color.White.copy(alpha = 0.09f),
                        radius = 0.6f,
                        center = Offset(x, y)
                    )
                    y += spacing
                }
                x += spacing
            }
        }

        // Top sheen
        Box(modifier = Modifier
            .fillMaxWidth()
            .height(height * 0.4f)
            .background(Brush.verticalGradient(
                listOf(Color.White.copy(alpha = 0.18f), Color.Transparent))))

        // Watermark glyph — bottom-trailing, very subtle. We use `offset`
        // (which accepts negatives) to push it slightly past the card edge
        // for the "spilling out" feel from iOS. Compose's `padding` would
        // throw IllegalArgumentException on negative values.
        Icon(
            imageVector = style.glyph,
            contentDescription = null,
            tint = Color.White.copy(alpha = 0.10f),
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .offset(x = 30.dp, y = 30.dp)
                .size(180.dp)
        )

        // Editorial content
        Column(modifier = Modifier.fillMaxSize().padding(14.dp)) {
            // TRENDX pill
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier
                    .clip(CircleShape)
                    .background(Color.White.copy(alpha = 0.14f))
                    .border(0.6.dp, Color.White.copy(alpha = 0.22f), CircleShape)
                    .padding(horizontal = 10.dp, vertical = 5.dp)
            ) {
                Box(modifier = Modifier
                    .size(5.dp)
                    .clip(CircleShape)
                    .background(Color.White.copy(alpha = 0.95f)))
                Spacer(Modifier.width(6.dp))
                Text(
                    text = "TRENDX",
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 9.5.sp,
                        color = Color.White.copy(alpha = 0.92f), letterSpacing = 1.8.sp)
                )
            }

            Spacer(modifier = Modifier.weight(1f))

            // Hero phrase + topic strip
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(
                    text = style.heroPhrase,
                    style = TextStyle(fontFamily = FontFamily.Default, fontWeight = FontWeight.Black,
                        fontSize = 22.sp, color = Color.White)
                )
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = style.label,
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                            color = Color.White.copy(alpha = 0.92f))
                    )
                    Spacer(Modifier.width(6.dp))
                    Box(modifier = Modifier
                        .width(18.dp)
                        .height(1.dp)
                        .background(Color.White.copy(alpha = 0.5f)))
                    Spacer(Modifier.width(6.dp))
                    Text(
                        text = "قراءة مجتمعية",
                        style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 10.5.sp,
                            color = Color.White.copy(alpha = 0.78f))
                    )
                }
            }
        }
    }
}

@Composable
private fun TopicChipOverlay(style: PollCoverStyle, modifier: Modifier = Modifier) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .clip(CircleShape)
            .background(Color.White.copy(alpha = 0.16f))
            .border(0.6.dp, Color.White.copy(alpha = 0.28f), CircleShape)
            .padding(horizontal = 10.dp, vertical = 5.dp)
    ) {
        Icon(imageVector = style.glyph, contentDescription = null,
            tint = Color.White, modifier = Modifier.size(11.dp))
        Spacer(Modifier.width(6.dp))
        Text(
            text = style.label,
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 12.sp, color = Color.White)
        )
    }
}
