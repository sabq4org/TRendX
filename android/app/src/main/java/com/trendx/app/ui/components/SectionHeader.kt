package com.trendx.app.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXType

// Mirrors SectionHeader from SharedComponents.swift.
@Composable
fun SectionHeader(
    title: String,
    subtitle: String? = null,
    showMore: Boolean = true,
    onMoreTap: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier.fillMaxWidth().padding(horizontal = 20.dp)
    ) {
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(text = title, style = TrendXType.Subheadline, color = TrendXColors.Ink)
            subtitle?.let {
                Text(
                    text = it,
                    style = TextStyle(fontSize = 12.sp, fontWeight = FontWeight.Medium,
                        color = TrendXColors.TertiaryInk)
                )
            }
        }
        if (showMore) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.clickable(enabled = onMoreTap != null) { onMoreTap?.invoke() }
            ) {
                Text(
                    text = "عرض الكل",
                    style = TextStyle(fontSize = 12.sp, fontWeight = FontWeight.SemiBold,
                        color = TrendXColors.Primary)
                )
                Spacer(Modifier.width(3.dp))
                Icon(imageVector = Icons.Filled.ChevronLeft, contentDescription = null,
                    tint = TrendXColors.Primary, modifier = Modifier.size(12.dp))
            }
        }
    }
}
