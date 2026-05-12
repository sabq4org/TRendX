package com.trendx.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Circle
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.theme.TrendXColors

// Mirrors StatusBadge in TRENDX/Theme/TrendXTheme.swift.
enum class StatusBadgeKind(
    val tint: Color,
    val icon: ImageVector,
    val label: String
) {
    Active(TrendXColors.Success, Icons.Filled.Circle, "نشط"),
    Ended(TrendXColors.Muted, Icons.Filled.CheckCircle, "منتهي"),
    Voted(TrendXColors.Primary, Icons.Filled.Verified, "صوّتت"),
    Draft(TrendXColors.Accent, Icons.Filled.Edit, "مسودة"),
    Warning(TrendXColors.Warning, Icons.Filled.AccessTime, "ينتهي قريباً")
}

@Composable
fun StatusBadge(kind: StatusBadgeKind, modifier: Modifier = Modifier) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .clip(CircleShape)
            .background(kind.tint.copy(alpha = 0.10f))
            .padding(horizontal = 9.dp, vertical = 4.dp)
    ) {
        Icon(
            imageVector = kind.icon,
            contentDescription = null,
            tint = kind.tint,
            modifier = Modifier.size(9.dp)
        )
        Text(
            text = kind.label,
            color = kind.tint,
            style = TextStyle(fontSize = 11.sp, fontWeight = FontWeight.SemiBold),
            modifier = Modifier.padding(start = 4.dp)
        )
    }
}
