package com.trendx.app.ui.components

import androidx.compose.animation.animateContentSize
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
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients

// Mirrors AIInsightChip from SharedComponents.swift — collapsible chip
// inside a PollCard that surfaces a single AI insight line; tap to expand.
@Composable
fun AIInsightChip(
    text: String,
    label: String = "رؤية TRENDX AI",
    modifier: Modifier = Modifier
) {
    var isExpanded by remember { mutableStateOf(false) }

    Row(
        verticalAlignment = Alignment.Top,
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(TrendXGradients.AiSoft)
            .border(0.9.dp, TrendXColors.AiIndigo.copy(alpha = 0.28f), RoundedCornerShape(14.dp))
            .clickable { isExpanded = !isExpanded }
            .padding(horizontal = 12.dp, vertical = 10.dp)
            .animateContentSize()
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .shadow(elevation = 6.dp, shape = CircleShape, clip = false,
                    ambientColor = TrendXColors.AiIndigo, spotColor = TrendXColors.AiIndigo)
                .size(28.dp)
                .clip(CircleShape)
                .background(TrendXGradients.Ai)
        ) {
            Icon(imageVector = Icons.Filled.AutoAwesome, contentDescription = null,
                tint = Color.White, modifier = Modifier.size(12.dp))
        }
        Spacer(Modifier.width(10.dp))
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = label,
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                        color = TrendXColors.AiIndigo)
                )
                Spacer(Modifier.width(6.dp))
                Icon(
                    imageVector = if (isExpanded) Icons.Filled.ExpandLess else Icons.Filled.ExpandMore,
                    contentDescription = null,
                    tint = TrendXColors.TertiaryInk,
                    modifier = Modifier.size(11.dp)
                )
            }
            Text(
                text = text,
                style = TextStyle(fontWeight = FontWeight.Medium, fontSize = 13.sp,
                    color = TrendXColors.Ink),
                maxLines = if (isExpanded) Int.MAX_VALUE else 1
            )
        }
    }
}
