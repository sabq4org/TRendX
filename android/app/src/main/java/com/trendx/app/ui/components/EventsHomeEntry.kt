package com.trendx.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.theme.TrendXColors

// Mirrors EventsHomeEntry from HomeScreen.swift — accent-orange gradient
// disc + headline + sub + chevron, tappable card opening EventsScreen.
@Composable
fun EventsHomeEntry(
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val discGradient = Brush.linearGradient(
        listOf(TrendXColors.Accent, Color(red = 0.95f, green = 0.55f, blue = 0.20f))
    )

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .shadow(elevation = 12.dp, shape = RoundedCornerShape(18.dp), clip = false,
                ambientColor = TrendXColors.Accent, spotColor = TrendXColors.Accent)
            .clip(RoundedCornerShape(18.dp))
            .background(TrendXColors.Surface)
            .border(1.dp, TrendXColors.Accent.copy(alpha = 0.20f), RoundedCornerShape(18.dp))
            .clickable(onClick = onClick)
            .padding(14.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .shadow(elevation = 10.dp, shape = CircleShape, clip = false,
                    ambientColor = TrendXColors.Accent, spotColor = TrendXColors.Accent)
                .size(48.dp)
                .clip(CircleShape)
                .background(discGradient)
        ) {
            Icon(imageVector = Icons.Filled.CalendarMonth, contentDescription = null,
                tint = Color.White, modifier = Modifier.size(20.dp))
        }
        Spacer(Modifier.width(14.dp))
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(text = "الفعاليات",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 15.sp,
                    color = TrendXColors.Ink))
            Text(text = "سجّل حضورك في فعاليات الجهات والمنظمات — خريطة حيّة لكل فعالية",
                style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 11.5.sp,
                    color = TrendXColors.TertiaryInk),
                maxLines = 2)
        }
        Icon(imageVector = Icons.Filled.ChevronLeft, contentDescription = null,
            tint = TrendXColors.Accent, modifier = Modifier.size(12.dp))
    }
}
