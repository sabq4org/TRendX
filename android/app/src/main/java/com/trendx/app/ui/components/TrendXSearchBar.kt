package com.trendx.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.unit.dp
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXType

// Mirrors TrendXSearchBar in TRENDX/Components/SharedComponents.swift.
@Composable
fun TrendXSearchBar(
    text: String,
    onTextChange: (String) -> Unit,
    placeholder: String = "البحث...",
    modifier: Modifier = Modifier
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(TrendXColors.SoftFill)
            .padding(horizontal = 16.dp, vertical = 12.dp)
    ) {
        Icon(
            imageVector = Icons.Filled.Search,
            contentDescription = null,
            tint = TrendXColors.TertiaryInk,
            modifier = Modifier.size(16.dp)
        )
        Spacer(Modifier.width(12.dp))
        Box(modifier = Modifier.weight(1f)) {
            if (text.isEmpty()) {
                Text(text = placeholder, style = TrendXType.Body,
                    color = TrendXColors.TertiaryInk)
            }
            BasicTextField(
                value = text,
                onValueChange = onTextChange,
                singleLine = true,
                cursorBrush = SolidColor(TrendXColors.Primary),
                textStyle = LocalTextStyle.current.merge(TrendXType.Body.copy(color = TrendXColors.Ink)),
                modifier = Modifier.fillMaxWidth()
            )
        }
        if (text.isNotEmpty()) {
            Icon(
                imageVector = Icons.Filled.Cancel,
                contentDescription = "مسح",
                tint = TrendXColors.TertiaryInk,
                modifier = Modifier
                    .size(16.dp)
                    .clickable { onTextChange("") }
            )
        }
    }
}
