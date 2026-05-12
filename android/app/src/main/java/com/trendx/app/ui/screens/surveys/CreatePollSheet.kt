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
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.Movie
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
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.models.PollType
import com.trendx.app.models.Topic
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients
import com.trendx.app.ui.components.DetailScreenScaffold
import com.trendx.app.ui.components.ToolbarTextPill

@Composable
fun CreatePollSheet(
    topics: List<Topic>,
    onClose: () -> Unit,
    onPublish: (
        title: String, description: String?, topicId: String?, type: String,
        durationDays: Int, options: List<String>, onError: (String) -> Unit
    ) -> Unit,
    modifier: Modifier = Modifier
) {
    var question by remember { mutableStateOf("") }
    var selectedType by remember { mutableStateOf(PollType.SingleChoice) }
    var selectedTopic by remember { mutableStateOf<Topic?>(null) }
    var durationDays by remember { mutableIntStateOf(2) }
    val options = remember { mutableStateListOf("", "") }

    val choiceOptions: List<String> = options.map { it.trim() }.filter { it.isNotEmpty() }
    val publishableOptions: List<String> = when (selectedType) {
        PollType.SingleChoice, PollType.MultipleChoice -> choiceOptions
        PollType.Rating -> (1..5).map { it.toString() }
        PollType.LinearScale -> (1..10).map { it.toString() }
    }
    val canPublish = remember(question, options.toList(), selectedType) {
        val hasQ = question.trim().isNotEmpty() && question.length <= 500
        when (selectedType) {
            PollType.SingleChoice, PollType.MultipleChoice -> hasQ && choiceOptions.size >= 2
            else -> hasQ
        }
    }

    DetailScreenScaffold(
        title = "منشور جديد",
        onClose = onClose,
        trailing = {
            ToolbarTextPill(
                label = "نشر",
                enabled = canPublish,
                onClick = {
                    onPublish(
                        question.trim(), null, selectedTopic?.id,
                        selectedType.raw, durationDays, publishableOptions
                    ) { /* errors via banner */ }
                }
            )
        },
        modifier = modifier
    ) {
        Column(
            modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState())
                .padding(20.dp).padding(bottom = 100.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            AITip()
            QuestionField(question, { question = it })
            MediaButtons()
            FieldDivider()
            PollTypeSection(selectedType) { selectedType = it }

            if (selectedType == PollType.SingleChoice || selectedType == PollType.MultipleChoice) {
                OptionsSection(options)
            } else {
                ScalePreview(selectedType)
            }
            FieldDivider()
            DurationSection(durationDays) { durationDays = it }
            TopicSection(topics, selectedTopic) { selectedTopic = it }
        }
    }
}

@Composable
private fun AITip() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(TrendXColors.AiViolet.copy(alpha = 0.06f))
            .border(1.dp, TrendXColors.AiIndigo.copy(alpha = 0.14f),
                RoundedCornerShape(14.dp))
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
            Text("TRENDX AI يساعدك",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 12.sp,
                    color = TrendXColors.AiIndigo))
            Text("صِغ سؤالاً واضحاً بخيارات موزونة — أسئلة اليوم تصنع رؤى الغد.",
                style = TextStyle(fontWeight = FontWeight.Medium, fontSize = 12.5.sp,
                    color = TrendXColors.SecondaryInk, lineHeight = 18.sp))
        }
    }
}

@Composable
private fun QuestionField(question: String, onChange: (String) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("عنوان المنشور",
            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 12.sp,
                color = TrendXColors.SecondaryInk))
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(TrendXColors.SoftFill)
                .heightIn(min = 80.dp)
                .padding(14.dp)
        ) {
            if (question.isEmpty()) {
                Text("اضف سؤالك هنا",
                    style = TextStyle(fontSize = 14.sp, color = TrendXColors.TertiaryInk))
            }
            BasicTextField(
                value = question,
                onValueChange = { if (it.length <= 500) onChange(it) },
                textStyle = TextStyle(fontSize = 14.sp, fontWeight = FontWeight.Medium,
                    color = TrendXColors.Ink, lineHeight = 20.sp),
                modifier = Modifier.fillMaxWidth(),
                cursorBrush = androidx.compose.ui.graphics.SolidColor(TrendXColors.Primary)
            )
        }
        Row(modifier = Modifier.fillMaxWidth()) {
            Spacer(Modifier.weight(1f))
            Text("${question.length}/500",
                style = TextStyle(fontSize = 11.sp, color = TrendXColors.TertiaryInk))
        }
    }
}

@Composable
private fun MediaButtons() {
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        DisabledMediaButton(icon = Icons.Filled.Image, title = "صورة قريباً",
            modifier = Modifier.weight(1f))
        DisabledMediaButton(icon = Icons.Filled.Movie, title = "فيديو قريباً",
            modifier = Modifier.weight(1f))
    }
}

@Composable
private fun DisabledMediaButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String, modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(14.dp))
            .background(TrendXColors.PaleFill)
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Icon(icon, contentDescription = null, tint = TrendXColors.TertiaryInk,
            modifier = Modifier.size(14.dp))
        Text(title,
            style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 13.sp,
                color = TrendXColors.TertiaryInk))
    }
}

@Composable
private fun FieldDivider() {
    Box(modifier = Modifier.fillMaxWidth().height(1.dp)
        .background(TrendXColors.Outline.copy(alpha = 0.4f)))
}

@Composable
private fun PollTypeSection(selected: PollType, onChange: (PollType) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("نوع السؤال",
            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 12.sp,
                color = TrendXColors.SecondaryInk))
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            PollType.values().forEach { type ->
                val isSelected = selected == type
                Box(
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(
                            if (isSelected) TrendXColors.Primary
                            else TrendXColors.SoftFill
                        )
                        .clickable { onChange(type) }
                        .padding(horizontal = 14.dp, vertical = 8.dp)
                ) {
                    Text(type.displayName,
                        style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 11.sp,
                            color = if (isSelected) Color.White
                                    else TrendXColors.SecondaryInk))
                }
            }
        }
        Text(typeHelperText(selected),
            style = TextStyle(fontSize = 11.sp, color = TrendXColors.TertiaryInk,
                lineHeight = 16.sp))
    }
}

private fun typeHelperText(type: PollType): String = when (type) {
    PollType.SingleChoice -> "يناسب سؤالاً له إجابة واحدة واضحة."
    PollType.MultipleChoice -> "يسمح للمستخدم باختيار أكثر من إجابة في النسخ القادمة."
    PollType.Rating -> "سيتم إنشاء مقياس تقييم من 1 إلى 5 تلقائياً."
    PollType.LinearScale -> "سيتم إنشاء مقياس خطي من 1 إلى 10 تلقائياً."
}

@Composable
private fun OptionsSection(options: androidx.compose.runtime.snapshots.SnapshotStateList<String>) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("الخيارات",
            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 12.sp,
                color = TrendXColors.SecondaryInk))
        options.forEachIndexed { index, value ->
            Row(verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .clip(RoundedCornerShape(12.dp))
                        .background(TrendXColors.SoftFill)
                        .padding(14.dp)
                ) {
                    if (value.isEmpty()) {
                        Text("الخيار ${index + 1}",
                            style = TextStyle(fontSize = 14.sp, color = TrendXColors.TertiaryInk))
                    }
                    BasicTextField(
                        value = value,
                        onValueChange = { options[index] = it },
                        textStyle = TextStyle(fontSize = 14.sp, fontWeight = FontWeight.SemiBold,
                            color = TrendXColors.Ink),
                        modifier = Modifier.fillMaxWidth(),
                        cursorBrush = androidx.compose.ui.graphics.SolidColor(TrendXColors.Primary)
                    )
                }
                if (options.size > 2) {
                    Box(
                        contentAlignment = Alignment.Center,
                        modifier = Modifier.size(24.dp).clip(CircleShape)
                            .clickable { options.removeAt(index) }
                    ) {
                        Icon(Icons.Filled.Cancel, contentDescription = "حذف",
                            tint = TrendXColors.Error, modifier = Modifier.size(18.dp))
                    }
                }
            }
        }
        if (options.size < 6) {
            Row(verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.clickable { options.add("") }) {
                Icon(Icons.Filled.AddCircle, contentDescription = null,
                    tint = TrendXColors.Primary, modifier = Modifier.size(14.dp))
                Text("إضافة خيار",
                    style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 12.sp,
                        color = TrendXColors.Primary))
            }
        }
    }
}

@Composable
private fun ScalePreview(type: PollType) {
    val labels = if (type == PollType.Rating) (1..5).map { it.toString() }
                 else (1..10).map { it.toString() }
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("معاينة المقياس",
            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 12.sp,
                color = TrendXColors.SecondaryInk))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            labels.forEach { label ->
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier
                        .weight(1f)
                        .clip(RoundedCornerShape(10.dp))
                        .background(TrendXColors.SoftFill)
                        .padding(vertical = 12.dp)
                ) {
                    Text(label,
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 14.sp,
                            color = TrendXColors.Ink))
                }
            }
        }
    }
}

@Composable
private fun DurationSection(durationDays: Int, onChange: (Int) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("مدة المنشور",
            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 12.sp,
                color = TrendXColors.SecondaryInk))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            listOf(1, 2, 3, 7, 14, 30).forEach { days ->
                val isSelected = durationDays == days
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier
                        .weight(1f)
                        .clip(RoundedCornerShape(12.dp))
                        .background(
                            if (isSelected) TrendXColors.Primary
                            else TrendXColors.SoftFill
                        )
                        .clickable { onChange(days) }
                        .padding(vertical = 12.dp)
                ) {
                    Text("$days",
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 14.sp,
                            color = if (isSelected) Color.White else TrendXColors.Ink))
                }
            }
        }
    }
}

@Composable
private fun TopicSection(
    topics: List<Topic>,
    selected: Topic?,
    onSelect: (Topic) -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("للمواضيع",
            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 12.sp,
                color = TrendXColors.SecondaryInk))
        // Horizontal scroll of topic chips
        Row(
            modifier = Modifier.fillMaxWidth()
                .horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            topics.forEach { topic ->
                val isSelected = selected?.id == topic.id
                Box(
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(
                            if (isSelected) TrendXColors.Primary
                            else TrendXColors.SoftFill
                        )
                        .clickable { onSelect(topic) }
                        .padding(horizontal = 14.dp, vertical = 8.dp)
                ) {
                    Text(topic.name,
                        style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 12.sp,
                            color = if (isSelected) Color.White
                                    else TrendXColors.SecondaryInk))
                }
            }
        }
    }
}

