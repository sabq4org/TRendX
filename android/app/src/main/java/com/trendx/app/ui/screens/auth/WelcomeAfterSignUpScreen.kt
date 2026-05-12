package com.trendx.app.ui.screens.auth

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
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
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.FormatQuote
import androidx.compose.material.icons.filled.MonitorHeart
import androidx.compose.material.icons.filled.PeopleAlt
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.models.Topic
import com.trendx.app.theme.TrendXAmbientBackground
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients
import kotlinx.coroutines.delay

private enum class WelcomeStage { Greeting, Tuning, Ready }

// Faithful Compose port of TRENDX/Screens/Auth/WelcomeAfterSignUpScreen.swift
// — three short stages animate in over a few seconds (greeting → tuning →
// ready), then the user can tap "ابدأ التجربة" to dismiss into the tab
// interface. Personalized using the user's name, picked interests, and
// optional voice line from the sign-up flow.
@Composable
fun WelcomeAfterSignUpScreen(
    name: String,
    interests: List<Topic>,
    voiceLine: String?,
    onContinue: () -> Unit,
    modifier: Modifier = Modifier
) {
    var stage by remember { mutableStateOf(WelcomeStage.Greeting) }
    val firstName = remember(name) {
        name.split(' ').firstOrNull()?.takeIf { it.isNotBlank() } ?: name
    }

    LaunchedEffect(Unit) {
        delay(1500)
        stage = WelcomeStage.Tuning
        delay(1900)
        stage = WelcomeStage.Ready
    }

    val transition = rememberInfiniteTransition(label = "welcome-orb")
    val orbScale by transition.animateFloat(
        initialValue = 0.85f, targetValue = 1.05f,
        animationSpec = infiniteRepeatable(
            animation = tween(1600, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "orbScale"
    )
    val orbGlow by transition.animateFloat(
        initialValue = 0.4f, targetValue = 1.0f,
        animationSpec = infiniteRepeatable(
            animation = tween(1600, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "orbGlow"
    )

    Box(modifier = modifier.fillMaxSize()) {
        TrendXAmbientBackground()
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(32.dp),
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .padding(horizontal = 24.dp)
        ) {
            Spacer(Modifier.height(40.dp))

            AiOrb(stage = stage, scale = orbScale, glow = orbGlow)

            // Headline + subline that swap with stage (cross-fade slide)
            AnimatedContent(
                targetState = stage,
                transitionSpec = {
                    (slideInVertically { it / 4 } + fadeIn(tween(220))) togetherWith
                        (slideOutVertically { -it / 4 } + fadeOut(tween(160)))
                },
                label = "stage-text"
            ) { current ->
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    Text(text = headlineFor(current, firstName, interests),
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 28.sp,
                            color = TrendXColors.Ink),
                        textAlign = TextAlign.Center)
                    Text(text = sublineFor(current, interests),
                        style = TextStyle(fontWeight = FontWeight.Medium, fontSize = 15.sp,
                            color = TrendXColors.SecondaryInk, lineHeight = 21.sp),
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 26.dp))
                }
            }

            AnimatedVisibility(
                visible = stage == WelcomeStage.Ready,
                enter = fadeIn(tween(280)) + slideInVertically { it / 5 },
                exit = fadeOut(tween(160))
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(16.dp),
                    modifier = Modifier.padding(horizontal = 2.dp)) {
                    if (interests.isNotEmpty()) {
                        InterestsCloud(interests = interests)
                    }
                    AiPersonalizedQuote(interests = interests, voiceLine = voiceLine)
                    InsightsRow()
                }
            }

            Spacer(Modifier.weight(1f))

            StageDots(current = stage)

            // Continue button — only on Ready
            AnimatedVisibility(
                visible = stage == WelcomeStage.Ready,
                enter = fadeIn(tween(280)) + slideInVertically { it / 4 },
                exit = fadeOut(tween(160))
            ) {
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 2.dp)
                        .shadow(elevation = 14.dp, shape = RoundedCornerShape(18.dp), clip = false,
                            ambientColor = TrendXColors.Primary, spotColor = TrendXColors.Primary)
                        .clip(RoundedCornerShape(18.dp))
                        .background(TrendXGradients.Primary)
                        .clickable(onClick = onContinue)
                        .padding(vertical = 16.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(imageVector = Icons.Filled.AutoAwesome, contentDescription = null,
                            tint = Color.White, modifier = Modifier.size(15.dp))
                        Spacer(Modifier.width(8.dp))
                        Text(text = "ابدأ التجربة",
                            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 16.sp,
                                color = Color.White))
                    }
                }
            }
            // Reserve space when button hidden so layout doesn't jump.
            if (stage != WelcomeStage.Ready) {
                Box(modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp))
            }

            Spacer(Modifier.height(20.dp))
        }
    }
}

// ---- AI Orb ----

@Composable
private fun AiOrb(stage: WelcomeStage, scale: Float, glow: Float) {
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier.size(220.dp)
    ) {
        // Outer glow halos
        Box(modifier = Modifier
            .size(220.dp)
            .clip(CircleShape)
            .background(TrendXColors.Primary.copy(alpha = (glow * 0.18f).coerceAtMost(1f))))
        Box(modifier = Modifier
            .size(170.dp)
            .clip(CircleShape)
            .background(TrendXColors.AiViolet.copy(alpha = (glow * 0.14f).coerceAtMost(1f))))

        // Main orb
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(132.dp)
                .scale(scale)
                .shadow(elevation = 28.dp, shape = CircleShape, clip = false,
                    ambientColor = TrendXColors.Primary, spotColor = TrendXColors.Primary)
                .clip(CircleShape)
                .background(Brush.linearGradient(listOf(
                    TrendXColors.AiIndigo, TrendXColors.Primary, TrendXColors.AiViolet
                )))
        ) {
            Icon(
                imageVector = if (stage == WelcomeStage.Ready) Icons.Filled.Check
                              else Icons.Filled.AutoAwesome,
                contentDescription = null, tint = Color.White,
                modifier = Modifier.size(44.dp)
            )
        }
    }
}

// ---- Stage progress dots ----

@Composable
private fun StageDots(current: WelcomeStage) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        WelcomeStage.entries.forEach { s ->
            val reached = s.ordinal <= current.ordinal
            val isActive = s == current
            Box(modifier = Modifier
                .size(width = if (isActive) 24.dp else 7.dp, height = 7.dp)
                .clip(CircleShape)
                .background(if (reached) TrendXColors.Primary
                            else TrendXColors.TertiaryInk.copy(alpha = 0.25f)))
        }
    }
}

// ---- Personalized pieces ----

@Composable
private fun InterestsCloud(interests: List<Topic>) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(text = "اهتماماتك المختارة",
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                color = TrendXColors.TertiaryInk))
        LazyRow(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            items(interests, key = { it.id }) { topic ->
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(TrendXColors.Primary.copy(alpha = 0.12f))
                        .border(0.8.dp, TrendXColors.Primary.copy(alpha = 0.18f), CircleShape)
                        .padding(horizontal = 10.dp, vertical = 5.dp)
                ) {
                    Icon(imageVector = Icons.Filled.AutoAwesome, contentDescription = null,
                        tint = TrendXColors.PrimaryDeep, modifier = Modifier.size(9.dp))
                    Spacer(Modifier.width(4.dp))
                    Text(text = topic.name,
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.5.sp,
                            color = TrendXColors.PrimaryDeep))
                }
            }
        }
    }
}

@Composable
private fun AiPersonalizedQuote(interests: List<Topic>, voiceLine: String?) {
    val body = when {
        !voiceLine.isNullOrBlank() ->
            "سمعتك تقول: “$voiceLine”.\nسأبني لوحتك حول هذي العبارة — ابدأ بأقرب اتجاه يلامسها."
        interests.isNotEmpty() ->
            "اخترت ${interests.first().name}. الجمهور السعودي الآن منقسم تماماً حول قضية فيها — رأيك يقدر يرجّح كفّة."
        else ->
            "اختر أول استطلاع يلفت نظرك — كل صوت يضيف بُعداً للنبض الذي نرسمه."
    }
    Row(
        verticalAlignment = Alignment.Top,
        modifier = Modifier
            .fillMaxWidth()
            .shadow(elevation = 10.dp, shape = RoundedCornerShape(16.dp), clip = false,
                ambientColor = TrendXColors.Primary, spotColor = TrendXColors.Primary)
            .clip(RoundedCornerShape(16.dp))
            .background(TrendXColors.Surface)
            .border(1.dp, TrendXColors.Primary.copy(alpha = 0.16f), RoundedCornerShape(16.dp))
            .padding(14.dp)
    ) {
        Icon(imageVector = Icons.Filled.FormatQuote, contentDescription = null,
            tint = TrendXColors.Primary.copy(alpha = 0.7f), modifier = Modifier.size(14.dp))
        Spacer(Modifier.width(10.dp))
        Text(text = body,
            style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 13.sp,
                color = TrendXColors.Ink, lineHeight = 19.sp))
    }
}

@Composable
private fun InsightsRow() {
    Row(horizontalArrangement = Arrangement.spacedBy(10.dp),
        modifier = Modifier.fillMaxWidth()) {
        InsightChip(icon = Icons.Filled.MonitorHeart, title = "نبض اليوم",
            tint = TrendXColors.Primary, modifier = Modifier.weight(1f))
        InsightChip(icon = Icons.Filled.TrendingUp, title = "مؤشّرك",
            tint = TrendXColors.AiViolet, modifier = Modifier.weight(1f))
        InsightChip(icon = Icons.Filled.PeopleAlt, title = "مجتمعك",
            tint = TrendXColors.Accent, modifier = Modifier.weight(1f))
    }
}

@Composable
private fun InsightChip(icon: ImageVector, title: String, tint: Color, modifier: Modifier = Modifier) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
        modifier = modifier
            .shadow(elevation = 8.dp, shape = RoundedCornerShape(14.dp), clip = false)
            .clip(RoundedCornerShape(14.dp))
            .background(TrendXColors.Surface)
            .padding(vertical = 12.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(38.dp)
                .clip(CircleShape)
                .background(tint.copy(alpha = 0.14f))
        ) {
            Icon(imageVector = icon, contentDescription = null, tint = tint,
                modifier = Modifier.size(15.dp))
        }
        Text(text = title, style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
            color = TrendXColors.SecondaryInk))
    }
}

// ---- Per-stage copy ----

private fun headlineFor(stage: WelcomeStage, firstName: String, interests: List<Topic>): String {
    return when (stage) {
        WelcomeStage.Greeting -> "أهلاً $firstName ✨"
        WelcomeStage.Tuning -> {
            val primary = interests.firstOrNull()?.name
            when {
                primary != null && interests.size > 1 ->
                    "أهيّئ بوصلتك لـ$primary و${interests.size - 1} اهتمام آخر…"
                primary != null -> "أهيّئ بوصلتك لقطاع $primary…"
                else -> "أُهيّئ بوصلتك الآن…"
            }
        }
        WelcomeStage.Ready -> "بوصلتك جاهزة، $firstName"
    }
}

private fun sublineFor(stage: WelcomeStage, interests: List<Topic>): String {
    return when (stage) {
        WelcomeStage.Greeting ->
            "انضممت لأكثر مجتمع رأي ذكاء في المنطقة — رأيك من اليوم محسوب."
        WelcomeStage.Tuning ->
            "أربط اختياراتك بآلاف الاستجابات الحيّة… أبحث عن أوّل اتجاه يستحقّ مشاركتك فيه."
        WelcomeStage.Ready -> {
            val primary = interests.firstOrNull()?.name
            if (primary != null)
                "اخترت لك ٣ اتّجاهات صاعدة في $primary${if (interests.size > 1) " و${interests.size - 1} موضوع آخر" else ""}. ابدأ بأقواها الآن."
            else
                "ابدأ بنبض اليوم، أو استكشف الاتجاهات على لوحتك الشخصية."
        }
    }
}
