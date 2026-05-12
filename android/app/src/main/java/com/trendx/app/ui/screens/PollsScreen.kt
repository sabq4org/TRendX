package com.trendx.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Archive
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
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
import com.trendx.app.models.Poll
import com.trendx.app.models.Survey
import com.trendx.app.theme.TrendXAmbientBackground
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients
import com.trendx.app.theme.TrendXType
import com.trendx.app.ui.components.CategoryInsightCTA
import com.trendx.app.ui.components.EmptyStateView
import com.trendx.app.ui.components.PollListRow
import com.trendx.app.ui.components.PollsSegmentButton
import com.trendx.app.ui.components.SurveyListRow
import com.trendx.app.ui.components.TrendXSearchBar

// Faithful Compose port of TRENDX/Screens/PollsScreen.swift. Sticky header
// with title + Polls/Surveys toggle + create button + 3-segment switcher,
// then a scrolling list of PollListRow items filtered by the active
// segment and the search field.
@Composable
fun PollsScreen(
    polls: List<Poll>,
    surveys: List<Survey>,
    isGuest: Boolean,
    onOpenPoll: (Poll) -> Unit,
    onOpenSurvey: (Survey) -> Unit,
    onCreatePoll: () -> Unit,
    onCreateSurvey: () -> Unit,
    onOpenCategoryInsight: () -> Unit,
    modifier: Modifier = Modifier
) {
    var selectedSegment by remember { mutableIntStateOf(0) }
    var searchText by remember { mutableStateOf("") }
    var showSurveys by remember { mutableStateOf(false) }

    val activePolls = remember(polls) { polls.filter { !it.isExpired } }
    val votedPolls = remember(polls) { polls.filter { it.hasUserVoted } }
    val endedPolls = remember(polls) { polls.filter { it.isExpired } }

    val visiblePolls = remember(polls, selectedSegment, searchText) {
        val base = when (selectedSegment) {
            0 -> activePolls
            1 -> votedPolls
            else -> endedPolls
        }
        if (searchText.isBlank()) base
        else base.filter {
            it.title.contains(searchText, ignoreCase = true) ||
                (it.topicName?.contains(searchText, ignoreCase = true) ?: false) ||
                it.authorName.contains(searchText, ignoreCase = true)
        }
    }

    Box(modifier = modifier.fillMaxSize()) {
        TrendXAmbientBackground()
        Column(modifier = Modifier.fillMaxSize().statusBarsPadding()) {
            // Sticky header
            Column(
                verticalArrangement = Arrangement.spacedBy(16.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 16.dp)
            ) {
                PollsHeaderRow(
                    showSurveys = showSurveys,
                    onSelectPolls = { showSurveys = false },
                    onSelectSurveys = { showSurveys = true },
                    onCreate = if (showSurveys) onCreateSurvey else onCreatePoll
                )
                Row(
                    horizontalArrangement = Arrangement.spacedBy(0.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(14.dp))
                        .background(TrendXColors.SoftFill)
                        .padding(3.dp)
                ) {
                    PollsSegmentButton(
                        title = "النشطة",
                        count = activePolls.size,
                        icon = Icons.Filled.Bolt,
                        isSelected = selectedSegment == 0,
                        onClick = { selectedSegment = 0 },
                        modifier = Modifier.weight(1f)
                    )
                    PollsSegmentButton(
                        title = "صوّتت",
                        count = votedPolls.size,
                        icon = Icons.Filled.CheckCircle,
                        isSelected = selectedSegment == 1,
                        onClick = { selectedSegment = 1 },
                        modifier = Modifier.weight(1f)
                    )
                    PollsSegmentButton(
                        title = "منتهية",
                        count = endedPolls.size,
                        icon = Icons.Filled.Archive,
                        isSelected = selectedSegment == 2,
                        onClick = { selectedSegment = 2 },
                        modifier = Modifier.weight(1f)
                    )
                }
            }

            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(
                    start = 20.dp, end = 20.dp, top = 16.dp, bottom = 130.dp
                ),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                if (!showSurveys) {
                    item("search") {
                        TrendXSearchBar(
                            text = searchText,
                            onTextChange = { searchText = it },
                            placeholder = "ابحث داخل الاستطلاعات…"
                        )
                    }
                    if (visiblePolls.isEmpty()) {
                        item("empty") {
                            EmptyStateView(
                                icon = if (selectedSegment == 0) Icons.Filled.AutoAwesome
                                       else Icons.Filled.CheckCircle,
                                title = if (selectedSegment == 0) "لحظة هدوء قبل الاتجاه التالي"
                                        else "لا توجد نتائج هنا",
                                message = if (selectedSegment == 0) "TRENDX AI يرصد الآن اتجاهات جديدة"
                                          else "جرّب تغيير البحث."
                            )
                        }
                    } else {
                        items(visiblePolls, key = { it.id }) { poll ->
                            PollListRow(poll = poll, onTap = { onOpenPoll(poll) })
                        }
                    }
                } else {
                    item("category-cta") {
                        CategoryInsightCTA(onClick = onOpenCategoryInsight)
                    }
                    if (surveys.isEmpty()) {
                        item("survey-empty") {
                            EmptyStateView(
                                icon = Icons.Filled.AutoAwesome,
                                title = "لا توجد استبيانات",
                                message = "ستظهر الاستبيانات المتعددة الأسئلة هنا"
                            )
                        }
                    } else {
                        items(surveys, key = { it.id }) { survey ->
                            SurveyListRow(survey = survey, onTap = { onOpenSurvey(survey) })
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun PollsHeaderRow(
    showSurveys: Boolean,
    onSelectPolls: () -> Unit,
    onSelectSurveys: () -> Unit,
    onCreate: () -> Unit
) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(text = if (showSurveys) "الاستبيانات" else "الاستطلاعات",
                style = TrendXType.Headline, color = TrendXColors.Ink)
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(imageVector = Icons.Filled.AutoAwesome, contentDescription = null,
                    tint = TrendXColors.AiIndigo, modifier = Modifier.size(10.dp))
                Spacer(Modifier.width(5.dp))
                Text(
                    text = if (showSurveys) "استبيانات متعددة الأسئلة"
                           else "مرتّبة ذكياً بواسطة TRENDX AI",
                    style = TextStyle(fontSize = 12.sp, fontWeight = FontWeight.Medium,
                        color = TrendXColors.TertiaryInk)
                )
            }
        }
        Row(
            modifier = Modifier
                .clip(CircleShape)
                .background(TrendXColors.SoftFill)
                .padding(3.dp)
        ) {
            HeaderToggleButton(label = "استطلاعات", isSelected = !showSurveys,
                onClick = onSelectPolls)
            HeaderToggleButton(label = "استبيانات", isSelected = showSurveys,
                onClick = onSelectSurveys)
        }
        Spacer(Modifier.width(8.dp))
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .shadow(elevation = 8.dp, shape = CircleShape, clip = false,
                    ambientColor = TrendXColors.Primary, spotColor = TrendXColors.Primary)
                .size(32.dp)
                .clip(CircleShape)
                .background(TrendXGradients.Primary)
                .clickable(onClick = onCreate)
        ) {
            Icon(imageVector = Icons.Filled.Add, contentDescription = "إنشاء",
                tint = Color.White, modifier = Modifier.size(14.dp))
        }
    }
}

@Composable
private fun HeaderToggleButton(label: String, isSelected: Boolean, onClick: () -> Unit) {
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .clip(CircleShape)
            .background(if (isSelected) TrendXColors.Primary else Color.Transparent)
            .clickable(onClick = onClick)
            .padding(horizontal = 10.dp, vertical = 6.dp)
    ) {
        Text(text = label, style = TextStyle(
            fontSize = 11.sp, fontWeight = FontWeight.SemiBold,
            color = if (isSelected) Color.White else TrendXColors.SecondaryInk))
    }
}

