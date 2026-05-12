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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.theme.TrendXAmbientBackground
import com.trendx.app.theme.TrendXColors

// Shared scaffold for every pushed Account sub-screen and for any sheet
// that mimics the iOS NavigationStack pattern. Toolbar has a circular
// close on the leading edge (= screen left in RTL) per
// [[feedback-sheet-close-placement]], plus optional trailing action.
@Composable
fun DetailScreenScaffold(
    title: String,
    onClose: () -> Unit,
    trailing: (@Composable () -> Unit)? = null,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    Box(modifier = modifier.fillMaxSize()) {
        TrendXAmbientBackground()
        Column(modifier = Modifier.fillMaxSize().statusBarsPadding()) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp, vertical = 12.dp)
            ) {
                ToolbarCircleButton(icon = Icons.Filled.Close, label = "إغلاق", onClick = onClose)
                Spacer(Modifier.width(8.dp))
                Text(
                    text = title,
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 17.sp,
                        color = TrendXColors.Ink),
                    modifier = Modifier.weight(1f)
                )
                trailing?.invoke()
            }
            Box(modifier = Modifier.fillMaxWidth().weight(1f)) {
                content()
            }
        }
    }
}

@Composable
fun ToolbarCircleButton(
    icon: ImageVector,
    label: String,
    onClick: () -> Unit,
    tint: androidx.compose.ui.graphics.Color = TrendXColors.Ink
) {
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .size(36.dp)
            .clip(CircleShape)
            .background(TrendXColors.Surface)
            .border(0.8.dp, TrendXColors.Outline, CircleShape)
            .clickable(onClick = onClick)
    ) {
        Icon(imageVector = icon, contentDescription = label, tint = tint,
            modifier = Modifier.size(15.dp))
    }
}

@Composable
fun ToolbarTextPill(
    label: String,
    enabled: Boolean = true,
    onClick: () -> Unit
) {
    val bg = if (enabled) TrendXColors.Primary.copy(alpha = 0.10f) else TrendXColors.SoftFill
    val fg = if (enabled) TrendXColors.Primary else TrendXColors.TertiaryInk
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .clip(CircleShape)
            .background(bg)
            .clickable(enabled = enabled, onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 8.dp)
    ) {
        Text(text = label, style = TextStyle(fontWeight = FontWeight.Bold,
            fontSize = 13.sp, color = fg))
    }
}
