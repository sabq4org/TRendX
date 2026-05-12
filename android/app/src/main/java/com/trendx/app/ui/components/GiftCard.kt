package com.trendx.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.models.Gift
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXType

// Mirrors GiftCard in SharedComponents.swift — gradient hero (brand
// color), watermark icon, brand monogram + value chip, category lozenge,
// progress bar (when not affordable), and a CTA arrow / lock at the
// bottom-right.
@Composable
fun GiftCard(
    gift: Gift,
    userPoints: Int,
    onTap: () -> Unit,
    modifier: Modifier = Modifier
) {
    val tint = gift.categoryTint
    val canAfford = userPoints >= gift.pointsRequired
    val progress = if (gift.pointsRequired <= 0) 1f
        else (userPoints.toFloat() / gift.pointsRequired.toFloat()).coerceAtMost(1f)

    Column(
        modifier = modifier
            .shadow(elevation = 12.dp, shape = RoundedCornerShape(20.dp), clip = false,
                ambientColor = tint, spotColor = tint)
            .clip(RoundedCornerShape(20.dp))
            .background(TrendXColors.ElevatedSurface)
            .border(1.dp, TrendXColors.Outline, RoundedCornerShape(20.dp))
            .clickable(onClick = onTap)
    ) {
        // Hero
        Box(modifier = Modifier
            .fillMaxWidth()
            .height(120.dp)
            .background(Brush.linearGradient(listOf(tint,
                Color(red = (tint.red + 0.2f).coerceAtMost(1f),
                    green = (tint.green + 0.2f).coerceAtMost(1f),
                    blue = (tint.blue + 0.2f).coerceAtMost(1f)))))
        ) {
            // Watermark icon
            Icon(
                imageVector = gift.categoryIcon,
                contentDescription = null,
                tint = Color.White.copy(alpha = 0.18f),
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .padding(start = 0.dp, bottom = 0.dp)
                    .size(110.dp)
                    .rotate(-10f)
            )
            // Glossy top sheen
            Box(modifier = Modifier
                .fillMaxWidth()
                .height(120.dp)
                .background(Brush.verticalGradient(listOf(
                    Color.White.copy(alpha = 0.22f), Color.Transparent))))
            Column(
                modifier = Modifier.fillMaxSize().padding(14.dp),
                verticalArrangement = Arrangement.SpaceBetween
            ) {
                Row(verticalAlignment = Alignment.Top) {
                    BrandMonogram(text = gift.brandMonogram, tint = tint)
                    Spacer(Modifier.weight(1f))
                    ValueChip(value = gift.valueInRiyal.toInt())
                }
                CategoryLozenge(category = gift.category, icon = gift.categoryIcon)
            }
        }
        // Body
        Column(
            verticalArrangement = Arrangement.spacedBy(10.dp),
            modifier = Modifier.fillMaxWidth().padding(12.dp)
        ) {
            Text(text = gift.brandName,
                style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 14.5.sp,
                    color = TrendXColors.Ink),
                maxLines = 1)
            Text(text = gift.name, style = TextStyle(fontSize = 11.5.sp,
                fontWeight = FontWeight.Medium, color = TrendXColors.TertiaryInk),
                maxLines = 1)
            if (!canAfford) {
                AffordabilityBar(progress = progress, tint = tint)
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                PointsRequiredChip(points = gift.pointsRequired)
                Spacer(Modifier.weight(1f))
                CTAButton(canAfford = canAfford)
            }
        }
    }
}

@Composable
private fun BrandMonogram(text: String, tint: Color) {
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .shadow(elevation = 4.dp, shape = CircleShape, clip = false,
                ambientColor = tint, spotColor = tint)
            .size(48.dp)
            .clip(CircleShape)
            .background(Color.White.copy(alpha = 0.18f))
    ) {
        Text(text = text, style = TextStyle(fontWeight = FontWeight.Black,
            fontSize = 22.sp, color = Color.White))
    }
}

@Composable
private fun ValueChip(value: Int) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .clip(CircleShape)
            .background(Color.White.copy(alpha = 0.22f))
            .border(0.5.dp, Color.White.copy(alpha = 0.35f), CircleShape)
            .padding(horizontal = 10.dp, vertical = 5.dp)
    ) {
        Text(text = value.toString(),
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 13.sp, color = Color.White))
        Spacer(Modifier.width(2.dp))
        Text(text = "ر.س",
            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 10.sp,
                color = Color.White.copy(alpha = 0.85f)))
    }
}

@Composable
private fun CategoryLozenge(category: String, icon: androidx.compose.ui.graphics.vector.ImageVector) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .clip(CircleShape)
            .background(Color.Black.copy(alpha = 0.22f))
            .padding(horizontal = 8.dp, vertical = 4.dp)
    ) {
        Icon(imageVector = icon, contentDescription = null, tint = Color.White,
            modifier = Modifier.size(9.dp))
        Spacer(Modifier.width(5.dp))
        Text(text = category,
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 10.sp, color = Color.White))
    }
}

@Composable
private fun AffordabilityBar(progress: Float, tint: Color) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(4.dp)
            .clip(CircleShape)
            .background(TrendXColors.SoftFill)
    ) {
        if (progress > 0f) {
            Box(modifier = Modifier
                .fillMaxWidth(fraction = progress.coerceAtLeast(0.001f))
                .height(4.dp)
                .clip(CircleShape)
                .background(tint.copy(alpha = 0.9f)))
        }
    }
}

@Composable
private fun PointsRequiredChip(points: Int) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .clip(CircleShape)
            .background(TrendXColors.Accent.copy(alpha = 0.12f))
            .padding(horizontal = 8.dp, vertical = 5.dp)
    ) {
        Icon(imageVector = Icons.Filled.Star, contentDescription = null,
            tint = TrendXColors.Accent, modifier = Modifier.size(11.dp))
        Spacer(Modifier.width(3.dp))
        Text(text = points.toString(),
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 12.sp,
                color = TrendXColors.AccentDeep))
    }
}

@Composable
private fun CTAButton(canAfford: Boolean) {
    val bg = if (canAfford) TrendXColors.Success else TrendXColors.SoftFill
    val fg = if (canAfford) Color.White else TrendXColors.TertiaryInk
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .shadow(elevation = if (canAfford) 6.dp else 0.dp, shape = CircleShape, clip = false,
                ambientColor = TrendXColors.Success, spotColor = TrendXColors.Success)
            .size(30.dp)
            .clip(CircleShape)
            .background(bg)
    ) {
        Icon(
            imageVector = if (canAfford) Icons.Filled.ArrowBack else Icons.Filled.Lock,
            contentDescription = null, tint = fg, modifier = Modifier.size(12.dp)
        )
    }
}
