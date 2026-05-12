package com.trendx.app.ui.screens.surveys

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.outlined.Circle
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.repositories.SurveyDraftInput
import com.trendx.app.theme.PollCoverStyle
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients
import com.trendx.app.ui.components.DetailScreenScaffold
import com.trendx.app.ui.components.ToolbarTextPill

private data class QuestionDraft(
    val title: String = "",
    val options: List<String> = listOf("", "")
) {
    val cleanedOptions: List<String> get() =
        options.map { it.trim() }.filter { it.isNotEmpty() }
    val isValid: Boolean get() = title.trim().isNotEmpty() && cleanedOptions.size >= 2
}

@Composable
fun CreateSurveySheet(
    onClose: () -> Unit,
    onPublish: (
        title: String, description: String, coverStyle: String,
        rewardPoints: Int, durationDays: Int, questions: List<SurveyDraftInput>,
        onError: (String) -> Unit
    ) -> Unit,
    modifier: Modifier = Modifier
) {
    var title by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var coverStyle by remember { mutableStateOf(PollCoverStyle.Generic) }
    var rewardPoints by remember { mutableIntStateOf(120) }
    var durationDays by remember { mutableIntStateOf(14) }
    val drafts = remember { mutableStateListOf(QuestionDraft(), QuestionDraft()) }

    val canPublish = remember(title, drafts.toList()) {
        title.trim().isNotEmpty() && drafts.count { it.isValid } >= 2
    }

    DetailScreenScaffold(
        title = "استبيان جديد",
        onClose = onClose,
        trailing = {
            ToolbarTextPill(
                label = "نشر",
                enabled = canPublish,
                onClick = {
                    val valid = drafts.filter { it.isValid }
                    val perQuestion = (rewardPoints / valid.size.coerceAtLeast(1))
                        .coerceAtLeast(20)
                    val payload = valid.mapIndexed { _, d ->
                        SurveyDraftInput(
                            title = d.title.trim(),
                            options = d.cleanedOptions,
                            rewardPoints = perQuestion
                        )
                    }
                    onPublish(
                        title.trim(), description.trim(), coverStyle.rawValue,
                        rewardPoints, durationDays, payload
                    ) { /* handled by AppViewModel banner */ }
                }
            )
        },
        modifier = modifier
    ) {
        Column(
            modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState())
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(22.dp)
        ) {
            HeaderTip()
            SurveyMetaCard(
                title = title, onTitleChange = { title = it },
                description = description, onDescriptionChange = { description = it },
                coverStyle = coverStyle, onCoverStyleChange = { coverStyle = it },
                rewardPoints = rewardPoints, onRewardChange = { rewardPoints = it },
                durationDays = durationDays, onDurationChange = { durationDays = it }
            )
            QuestionsSection(drafts)
        }
    }
}

@Composable
private fun HeaderTip() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(TrendXColors.AiViolet.copy(alpha = 0.06f))
            .padding(12.dp),
        verticalAlignment = Alignment.Top,
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier.size(30.dp).clip(CircleShape).background(TrendXGradients.Header)
        ) {
            Icon(Icons.Filled.AutoAwesome, contentDescription = null,
                tint = Color.White, modifier = Modifier.size(13.dp))
        }
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text("ابنِ استبياناً متماسكاً",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 12.sp,
                    color = TrendXColors.AiIndigo))
            Text("سؤالان على الأقل — كل سؤال يحتاج خيارين على الأقل لتصبح النتائج مقروءة.",
                style = TextStyle(fontWeight = FontWeight.Medium, fontSize = 12.sp,
                    color = TrendXColors.SecondaryInk, lineHeight = 17.sp))
        }
    }
}

@Composable
private fun SurveyMetaCard(
    title: String, onTitleChange: (String) -> Unit,
    description: String, onDescriptionChange: (String) -> Unit,
    coverStyle: PollCoverStyle, onCoverStyleChange: (PollCoverStyle) -> Unit,
    rewardPoints: Int, onRewardChange: (Int) -> Unit,
    durationDays: Int, onDurationChange: (Int) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(TrendXColors.Surface)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        FieldLabel("العنوان")
        FilledTextField(value = title, onValueChange = onTitleChange,
            placeholder = "مثال: نظرتنا إلى الذكاء الاصطناعي في 2026")
        FieldLabel("وصف مختصر — اختياري")
        FilledTextField(value = description, onValueChange = onDescriptionChange,
            placeholder = "ما الزاوية التي يستكشفها الاستبيان؟", minHeight = 64.dp)

        FieldLabel("نمط الغلاف")
        Row(
            modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            PollCoverStyle.values().forEach { style ->
                CoverChip(style = style, selected = coverStyle == style,
                    onClick = { onCoverStyleChange(style) })
            }
        }

        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Column(modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(6.dp)) {
                FieldLabel("المدّة")
                SegmentedPicker(
                    options = listOf(3, 7, 14, 30),
                    selected = durationDays,
                    label = { "$it يوم" },
                    onSelect = onDurationChange
                )
            }
            Column(modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(6.dp)) {
                FieldLabel("المكافأة")
                SegmentedPicker(
                    options = listOf(80, 120, 200, 300),
                    selected = rewardPoints,
                    label = { "$it" },
                    onSelect = onRewardChange
                )
            }
        }
    }
}

@Composable
private fun QuestionsSection(drafts: androidx.compose.runtime.snapshots.SnapshotStateList<QuestionDraft>) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("الأسئلة",
                style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 14.sp,
                    color = TrendXColors.SecondaryInk),
                modifier = Modifier.weight(1f))
            Text("${drafts.count { it.isValid }} من ${drafts.size}",
                style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 11.sp,
                    color = TrendXColors.TertiaryInk))
        }
        drafts.forEachIndexed { idx, draft ->
            QuestionCard(
                index = idx,
                draft = draft,
                canRemove = drafts.size > 2,
                onChange = { newDraft -> drafts[idx] = newDraft },
                onRemove = { drafts.removeAt(idx) }
            )
        }
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .border(1.5.dp, TrendXColors.Primary.copy(alpha = 0.4f),
                    RoundedCornerShape(14.dp))
                .clickable { drafts.add(QuestionDraft()) }
                .padding(vertical = 13.dp),
            contentAlignment = Alignment.Center
        ) {
            Row(verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Icon(Icons.Filled.AddCircle, contentDescription = null,
                    tint = TrendXColors.Primary, modifier = Modifier.size(14.dp))
                Text("إضافة سؤال",
                    style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 14.sp,
                        color = TrendXColors.Primary))
            }
        }
    }
}

@Composable
private fun QuestionCard(
    index: Int,
    draft: QuestionDraft,
    canRemove: Boolean,
    onChange: (QuestionDraft) -> Unit,
    onRemove: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(TrendXColors.Surface)
            .border(1.dp,
                if (draft.isValid) TrendXColors.Primary.copy(alpha = 0.25f)
                else TrendXColors.TertiaryInk.copy(alpha = 0.15f),
                RoundedCornerShape(16.dp))
            .padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier.size(24.dp).clip(CircleShape)
                    .background(TrendXColors.Primary)
            ) {
                Text("${index + 1}",
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 12.sp,
                        color = Color.White))
            }
            Text("سؤال",
                style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 12.sp,
                    color = TrendXColors.SecondaryInk),
                modifier = Modifier.weight(1f))
            if (canRemove) {
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier.size(28.dp).clip(CircleShape)
                        .background(TrendXColors.Error.copy(alpha = 0.10f))
                        .clickable(onClick = onRemove)
                ) {
                    Icon(Icons.Filled.Delete, contentDescription = "حذف",
                        tint = TrendXColors.Error, modifier = Modifier.size(12.dp))
                }
            }
        }
        FilledTextField(
            value = draft.title,
            onValueChange = { onChange(draft.copy(title = it)) },
            placeholder = "نصّ السؤال", radius = 10.dp
        )
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            draft.options.forEachIndexed { oIdx, opt ->
                Row(verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Icon(Icons.Outlined.Circle, contentDescription = null,
                        tint = TrendXColors.TertiaryInk, modifier = Modifier.size(11.dp))
                    Box(modifier = Modifier.weight(1f)) {
                        FilledTextField(
                            value = opt,
                            onValueChange = { newValue ->
                                val newList = draft.options.toMutableList()
                                newList[oIdx] = newValue
                                onChange(draft.copy(options = newList))
                            },
                            placeholder = "الخيار ${oIdx + 1}", radius = 9.dp
                        )
                    }
                    if (draft.options.size > 2) {
                        Box(
                            contentAlignment = Alignment.Center,
                            modifier = Modifier.size(22.dp).clip(CircleShape)
                                .clickable {
                                    val newList = draft.options.toMutableList()
                                    newList.removeAt(oIdx)
                                    onChange(draft.copy(options = newList))
                                }
                        ) {
                            Text("×",
                                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 16.sp,
                                    color = TrendXColors.TertiaryInk))
                        }
                    }
                }
            }
            if (draft.options.size < 6) {
                Row(verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    modifier = Modifier.padding(top = 2.dp).clickable {
                        onChange(draft.copy(options = draft.options + ""))
                    }) {
                    Text("+",
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 14.sp,
                            color = TrendXColors.Primary))
                    Text("خيار آخر",
                        style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 12.sp,
                            color = TrendXColors.Primary))
                }
            }
        }
    }
}

@Composable
private fun CoverChip(style: PollCoverStyle, selected: Boolean, onClick: () -> Unit) {
    val bg = if (selected) style.tint else style.wash
    val fg = if (selected) Color.White else style.tint
    Row(
        modifier = Modifier
            .clip(CircleShape)
            .background(bg)
            .clickable(onClick = onClick)
            .padding(horizontal = 12.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Icon(style.glyph, contentDescription = null, tint = fg, modifier = Modifier.size(11.dp))
        Text(style.label,
            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 11.sp, color = fg))
    }
}

@Composable
private fun FieldLabel(text: String) {
    Text(text.uppercase(),
        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
            letterSpacing = 0.4.sp, color = TrendXColors.TertiaryInk))
}

@Composable
private fun FilledTextField(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    radius: androidx.compose.ui.unit.Dp = 12.dp,
    minHeight: androidx.compose.ui.unit.Dp = 48.dp
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(radius))
            .background(TrendXColors.SoftFill)
            .padding(horizontal = 14.dp, vertical = 12.dp)
            .heightIn(min = minHeight)
    ) {
        if (value.isEmpty()) {
            Text(placeholder,
                style = TextStyle(fontSize = 13.sp, color = TrendXColors.TertiaryInk))
        }
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            textStyle = TextStyle(fontSize = 14.sp, fontWeight = FontWeight.SemiBold,
                color = TrendXColors.Ink),
            modifier = Modifier.fillMaxWidth(),
            cursorBrush = androidx.compose.ui.graphics.SolidColor(TrendXColors.Primary)
        )
    }
}

@Composable
private fun <T> SegmentedPicker(
    options: List<T>,
    selected: T,
    label: (T) -> String,
    onSelect: (T) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(10.dp))
            .background(TrendXColors.SoftFill)
            .padding(2.dp)
    ) {
        options.forEach { option ->
            val isSelected = option == selected
            Box(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(8.dp))
                    .background(if (isSelected) Color.White else Color.Transparent)
                    .clickable { onSelect(option) }
                    .padding(vertical = 8.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(label(option),
                    style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 11.sp,
                        color = if (isSelected) TrendXColors.Ink else TrendXColors.SecondaryInk))
            }
        }
    }
}
