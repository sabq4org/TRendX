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
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.PeopleAlt
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.SubcomposeAsyncImage
import com.trendx.app.models.Poll
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients
import com.trendx.app.theme.TrendXType

// Mirrors MiniPollCard from SharedComponents.swift — fixed-width card
// for the "اتجاهات اليوم" horizontal carousel. Two layouts:
// (1) hasImage → 84dp photo strip with topic chip overlay + body below.
// (2) no image → topic chip + AI marker row, then title + footer.
@Composable
fun MiniPollCard(
    poll: Poll,
    onTap: () -> Unit,
    modifier: Modifier = Modifier
) {
    val style = poll.topicStyle
    val tint = style.tint
    val hasImage = !poll.imageUrl.isNullOrBlank()

    Column(
        modifier = modifier
            .width(248.dp)
            .height(168.dp)
            .shadow(elevation = 10.dp, shape = RoundedCornerShape(20.dp), clip = false)
            .clip(RoundedCornerShape(20.dp))
            .background(TrendXColors.Surface)
            .border(0.8.dp, TrendXColors.Outline, RoundedCornerShape(20.dp))
            .clickable(onClick = onTap)
    ) {
        if (hasImage) {
            Box(modifier = Modifier
                .fillMaxWidth()
                .height(84.dp)) {
                SubcomposeAsyncImage(
                    model = poll.imageUrl,
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    loading = { Box(modifier = Modifier.fillMaxSize().background(style.gradient)) },
                    error = { Box(modifier = Modifier.fillMaxSize().background(style.gradient)) },
                    modifier = Modifier.fillMaxSize()
                )
                Box(modifier = Modifier
                    .fillMaxSize()
                    .background(Brush.verticalGradient(
                        listOf(Color.Transparent, Color.Black.copy(alpha = 0.50f)))))
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier
                        .align(Alignment.BottomStart)
                        .padding(10.dp)
                        .clip(CircleShape)
                        .background(Color.White.copy(alpha = 0.18f))
                        .border(0.6.dp, Color.White.copy(alpha = 0.28f), CircleShape)
                        .padding(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Icon(imageVector = style.glyph, contentDescription = null,
                        tint = Color.White, modifier = Modifier.size(9.5.dp))
                    Spacer(Modifier.width(5.dp))
                    Text(
                        text = poll.topicName ?: style.label,
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 10.5.sp,
                            color = Color.White)
                    )
                }
            }
        }

        Column(
            verticalArrangement = Arrangement.spacedBy(10.dp),
            modifier = Modifier
                .weight(1f)
                .padding(horizontal = 14.dp, vertical = if (hasImage) 12.dp else 16.dp)
        ) {
            if (!hasImage) {
                Row(verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier
                            .clip(CircleShape)
                            .background(style.wash)
                            .border(0.6.dp, style.hairline, CircleShape)
                            .padding(horizontal = 9.dp, vertical = 4.dp)
                    ) {
                        Icon(imageVector = style.glyph, contentDescription = null,
                            tint = tint, modifier = Modifier.size(10.dp))
                        Spacer(Modifier.width(5.dp))
                        Text(
                            text = poll.topicName ?: style.label,
                            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                                color = tint)
                        )
                    }
                    Spacer(Modifier.weight(1f))
                    if (poll.aiInsight != null) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .clip(CircleShape)
                                .background(TrendXColors.AiIndigo.copy(alpha = 0.10f))
                                .border(0.8.dp, TrendXColors.AiIndigo.copy(alpha = 0.18f), CircleShape)
                                .padding(horizontal = 7.dp, vertical = 3.dp)
                        ) {
                            Icon(imageVector = Icons.Filled.AutoAwesome, contentDescription = null,
                                tint = TrendXColors.AiIndigo, modifier = Modifier.size(9.dp))
                            Spacer(Modifier.width(3.dp))
                            Text(text = "AI", style = TextStyle(
                                fontWeight = FontWeight.Black, fontSize = 10.sp,
                                color = TrendXColors.AiIndigo))
                        }
                    }
                }
            }

            Text(
                text = poll.title,
                style = TextStyle(
                    fontSize = 14.5.sp, fontWeight = FontWeight.SemiBold,
                    color = TrendXColors.Ink, lineHeight = 18.sp
                ),
                maxLines = if (hasImage) 2 else 3
            )

            Spacer(modifier = Modifier.weight(1f))

            Row(verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(imageVector = Icons.Filled.PeopleAlt, contentDescription = null,
                        tint = TrendXColors.TertiaryInk, modifier = Modifier.size(11.dp))
                    Spacer(Modifier.width(4.dp))
                    Text(text = poll.totalVotes.toString(), style = TextStyle(
                        fontSize = 11.sp, fontWeight = FontWeight.SemiBold,
                        color = TrendXColors.TertiaryInk))
                }
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(imageVector = Icons.Filled.Star, contentDescription = null,
                        tint = TrendXColors.Accent, modifier = Modifier.size(11.dp))
                    Spacer(Modifier.width(3.dp))
                    Text(text = "+${poll.rewardPoints}", style = TextStyle(
                        fontSize = 11.sp, fontWeight = FontWeight.Bold,
                        color = TrendXColors.AccentDeep))
                }
                Spacer(Modifier.weight(1f))
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier
                        .shadow(elevation = 4.dp, shape = CircleShape, clip = false,
                            ambientColor = TrendXColors.Primary, spotColor = TrendXColors.Primary)
                        .size(28.dp)
                        .clip(CircleShape)
                        .background(TrendXGradients.Primary)
                ) {
                    Icon(imageVector = Icons.Filled.ArrowBack, contentDescription = null,
                        tint = Color.White, modifier = Modifier.size(11.dp))
                }
            }
        }
    }
}
