package com.trendx.app.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.models.PollOption
import com.trendx.app.theme.TrendXColors

// Mirrors PollOptionRow from SharedComponents.swift — shows a tappable
// option pill that morphs into a horizontal results bar after voting.
// The fill width is `option.percentage / 100`, tinted with the poll's
// topic color so each card reads with its own visual identity.
@Composable
fun PollOptionRow(
    option: PollOption,
    tint: Color,
    isSelected: Boolean,
    showResults: Boolean,
    isUserChoice: Boolean,
    onTap: () -> Unit,
    modifier: Modifier = Modifier
) {
    val isLeading = showResults && option.percentage >= 50
    val borderColor = if (isSelected || isUserChoice) tint else TrendXColors.StrongOutline
    val borderWidth = if (isSelected || isUserChoice) 1.4.dp else 0.8.dp

    Box(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(TrendXColors.SoftFill)
            .border(borderWidth, borderColor, RoundedCornerShape(12.dp))
            .clickable(enabled = !showResults, onClick = onTap)
    ) {
        if (showResults) {
            // Animated fill bar — left-anchored width = percentage of total.
            Canvas(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp)
            ) {
                val w = size.width * (option.percentage.toFloat() / 100f)
                val brush = Brush.horizontalGradient(
                    colors = if (isUserChoice)
                        listOf(tint.copy(alpha = 0.22f), tint.copy(alpha = 0.10f))
                    else
                        listOf(tint.copy(alpha = 0.08f), tint.copy(alpha = 0.04f))
                )
                drawRoundRect(brush = brush,
                    topLeft = Offset(0f, 0f),
                    size = Size(w, size.height))
            }
        }

        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.padding(horizontal = 14.dp, vertical = 12.dp)
        ) {
            if (isUserChoice) {
                Icon(imageVector = Icons.Filled.CheckCircle, contentDescription = null,
                    tint = tint, modifier = Modifier.size(15.dp))
                Spacer(Modifier.width(10.dp))
            } else if (showResults && isLeading) {
                Icon(imageVector = Icons.Filled.BarChart, contentDescription = null,
                    tint = tint.copy(alpha = 0.85f), modifier = Modifier.size(11.dp))
                Spacer(Modifier.width(10.dp))
            }
            Text(
                text = option.text,
                style = TextStyle(
                    fontSize = 14.5.sp,
                    fontWeight = if (isUserChoice) FontWeight.SemiBold else FontWeight.Medium,
                    color = if (isUserChoice) tint else TrendXColors.Ink
                ),
                modifier = Modifier.weight(1f)
            )
            if (showResults) {
                Spacer(Modifier.width(8.dp))
                Text(
                    text = "${option.percentage.toInt()}%",
                    style = TextStyle(
                        fontWeight = FontWeight.Black, fontSize = 13.sp,
                        color = if (isUserChoice) tint else TrendXColors.SecondaryInk
                    )
                )
            }
        }
    }
}
