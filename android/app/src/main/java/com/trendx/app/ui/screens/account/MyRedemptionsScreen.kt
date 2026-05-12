package com.trendx.app.ui.screens.account

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CardGiftcard
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.models.Redemption
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXType
import com.trendx.app.ui.components.DetailScreenScaffold
import com.trendx.app.ui.components.EmptyStateView

// Mirrors MyRedemptionsScreen from AccountScreen.swift.
@Composable
fun MyRedemptionsScreen(
    redemptions: List<Redemption>,
    onClose: () -> Unit,
    modifier: Modifier = Modifier
) {
    DetailScreenScaffold(
        title = "الهدايا المكتسبة",
        onClose = onClose,
        modifier = modifier
    ) {
        if (redemptions.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize().padding(20.dp),
                contentAlignment = Alignment.Center) {
                EmptyStateView(
                    icon = Icons.Filled.CardGiftcard,
                    title = "لا هدايا بعد",
                    message = "كل تصويت يمنحك نقاطاً، استبدلها لاحقاً بهدايا من تبويب الهدايا."
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(start = 20.dp, end = 20.dp,
                    top = 8.dp, bottom = 40.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(redemptions, key = { it.id }) { row ->
                    RedemptionRow(row)
                }
            }
        }
    }
}

@Composable
private fun RedemptionRow(redemption: Redemption) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(TrendXColors.Surface)
            .border(0.8.dp, TrendXColors.Outline, RoundedCornerShape(16.dp))
            .padding(14.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(TrendXColors.AiViolet.copy(alpha = 0.12f))
        ) {
            Icon(imageVector = Icons.Filled.CardGiftcard, contentDescription = null,
                tint = TrendXColors.AiViolet, modifier = Modifier.size(18.dp))
        }
        Spacer(Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(text = redemption.brandName, style = TextStyle(
                fontSize = 14.sp, fontWeight = FontWeight.Bold, color = TrendXColors.Ink))
            Text(text = redemption.giftName, style = TrendXType.Small,
                color = TrendXColors.SecondaryInk)
        }
        Column(horizontalAlignment = Alignment.End) {
            Text(text = redemption.code,
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 13.sp,
                    color = TrendXColors.PrimaryDeep))
            Text(text = "-${redemption.pointsSpent} نقطة",
                style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 11.sp,
                    color = TrendXColors.AccentDeep))
        }
    }
}
