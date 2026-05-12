package com.trendx.app.ui.components

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import com.trendx.app.theme.TrendXColors
import kotlin.math.sin
import kotlin.random.Random

// Compose port of TRENDX/Components/TrendXConfetti.swift. ~60 colored
// chips fall from the top with light horizontal sway. Brand-agnostic
// palette taken from the iOS app (primary, accent, success, AI violet).
@Composable
fun TrendXConfetti(modifier: Modifier = Modifier, pieceCount: Int = 60) {
    val colors = listOf(
        TrendXColors.Primary, TrendXColors.Accent, TrendXColors.Success,
        TrendXColors.AiViolet, TrendXColors.AiCyan, TrendXColors.Warning
    )
    // Generate stable per-piece params once.
    val pieces = remember(pieceCount) {
        List(pieceCount) {
            ConfettiPiece(
                xFraction = Random.nextFloat(),
                size = Random.nextFloat() * 6f + 4f,
                color = colors[Random.nextInt(colors.size)],
                phase = Random.nextFloat() * (2f * Math.PI.toFloat()),
                speed = Random.nextFloat() * 0.45f + 0.45f,
                rotation = Random.nextFloat() * 360f
            )
        }
    }
    val transition = rememberInfiniteTransition(label = "confetti")
    val progress by transition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 4500, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "confetti-progress"
    )
    Canvas(modifier = modifier.fillMaxSize()) {
        for (piece in pieces) {
            val t = ((progress + piece.phase / 6f) * piece.speed) % 1f
            val y = -size.height * 0.1f + (size.height * 1.2f) * t
            val sway = sin(piece.phase + t * 4f) * 24f
            val x = piece.xFraction * size.width + sway
            drawRect(
                color = piece.color.copy(alpha = (1f - t).coerceIn(0.4f, 1f)),
                topLeft = Offset(x, y),
                size = Size(piece.size, piece.size * 1.6f)
            )
        }
    }
}

private data class ConfettiPiece(
    val xFraction: Float,
    val size: Float,
    val color: Color,
    val phase: Float,
    val speed: Float,
    val rotation: Float
)
