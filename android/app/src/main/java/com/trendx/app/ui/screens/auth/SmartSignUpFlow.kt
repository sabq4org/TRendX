package com.trendx.app.ui.screens.auth

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
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
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.FormatQuote
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshots.SnapshotStateList
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.models.UserGender
import com.trendx.app.theme.TrendXAmbientBackground
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

// Faithful Compose port of TRENDX/Screens/Auth/SmartSignUpFlow.swift.
// 9-step AI-led conversational onboarding: greeting → name → email →
// password → gender → birthDecade → city → interests → voice → finishing.
// Each AI message scrolls in with a typing-dots indicator, each user
// answer becomes a brand-gradient bubble. Step transitions resign the
// keyboard and re-focus the right field for text steps.

private enum SignUpStep {
    Greeting, AskName, AskEmail, AskPassword, AskGender,
    AskBirthDecade, AskCity, AskInterests, AskVoice, Finishing, Done
}

private data class ChatMsg(val author: Author, val text: String, val key: Long) {
    enum class Author { Ai, User }
}

@Composable
fun SmartSignUpFlow(
    onSwitchToSignIn: () -> Unit = {},
    onSubmit: (
        name: String, email: String, password: String,
        gender: UserGender, birthYear: Int?, city: String?,
        interests: List<String>, voiceLine: String?,
        onError: (String) -> Unit
    ) -> Unit,
    interestTopicNames: List<String> = DefaultInterestPool,
    saudiCities: List<String> = DefaultSaudiCities,
    modifier: Modifier = Modifier
) {
    val scope = androidx.compose.runtime.rememberCoroutineScope()
    var step by remember { mutableStateOf(SignUpStep.Greeting) }
    val messages = remember { mutableStateListOf<ChatMsg>() }
    var isTyping by remember { mutableStateOf(false) }
    val listState = rememberLazyListState()

    // Collected values
    var name by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var gender by remember { mutableStateOf(UserGender.unspecified) }
    var birthYear by remember { mutableStateOf<Int?>(null) }
    var city by remember { mutableStateOf("") }
    val interests = remember { mutableStateListOf<String>() }
    var voiceLine by remember { mutableStateOf("") }

    // Live input scratchpads
    var nameInput by remember { mutableStateOf("") }
    var emailInput by remember { mutableStateOf("") }
    var passwordInput by remember { mutableStateOf("") }

    LaunchedEffect(Unit) {
        runStep(SignUpStep.Greeting,
            messages = messages,
            setStep = { step = it },
            setTyping = { isTyping = it },
            name = { name },
            interests = interests
        )
    }

    LaunchedEffect(messages.size, isTyping) {
        if (messages.isNotEmpty()) listState.animateScrollToItem(messages.lastIndex)
    }

    Box(modifier = modifier.fillMaxSize()) {
        TrendXAmbientBackground()

        Column(modifier = Modifier
            .fillMaxSize()
            .statusBarsPadding()) {

            ChatHeader(isTyping = isTyping, onSwitchToSignIn = { /* TODO */ })

            // Conversation transcript
            LazyColumn(
                state = listState,
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
                contentPadding = androidx.compose.foundation.layout.PaddingValues(
                    horizontal = 18.dp, vertical = 12.dp
                ),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(messages, key = { it.key }) { msg ->
                    MessageBubble(msg)
                }
                if (isTyping) {
                    item("typing") { TypingBubble() }
                }
            }

            // Input bar — switches per-step
            InputBar(
                step = step,
                nameInput = nameInput, onNameChange = { nameInput = it },
                emailInput = emailInput, onEmailChange = { emailInput = it },
                passwordInput = passwordInput, onPasswordChange = { passwordInput = it },
                voiceLine = voiceLine, onVoiceChange = { voiceLine = it },
                interests = interests,
                interestPool = interestTopicNames,
                saudiCities = saudiCities,
                onCommitName = {
                    val v = nameInput.trim()
                    if (v.isEmpty()) return@InputBar
                    name = v
                    appendUser(messages, v)
                    nameInput = ""
                    advance(scope, SignUpStep.AskEmail, { step = it }, isTyping = { isTyping = it },
                        messages = messages, name = { name }, interests = interests)
                },
                onCommitEmail = {
                    val v = emailInput.trim()
                    if (!isValidEmail(v)) return@InputBar
                    email = v.lowercase()
                    appendUser(messages, email)
                    emailInput = ""
                    advance(scope, SignUpStep.AskPassword, { step = it }, isTyping = { isTyping = it },
                        messages = messages, name = { name }, interests = interests)
                },
                onCommitPassword = {
                    if (passwordInput.length < 6) return@InputBar
                    password = passwordInput
                    appendUser(messages, "•".repeat(passwordInput.length))
                    passwordInput = ""
                    advance(scope, SignUpStep.AskGender, { step = it }, isTyping = { isTyping = it },
                        messages = messages, name = { name }, interests = interests)
                },
                onCommitGender = { g ->
                    gender = g
                    appendUser(messages, g.displayName)
                    advance(scope, SignUpStep.AskBirthDecade, { step = it }, isTyping = { isTyping = it },
                        messages = messages, name = { name }, interests = interests)
                },
                onCommitDecade = { year ->
                    birthYear = year
                    appendUser(messages, year?.let { decadeLabelForYear(it) } ?: "أفضّل لا أقول")
                    advance(scope, SignUpStep.AskCity, { step = it }, isTyping = { isTyping = it },
                        messages = messages, name = { name }, interests = interests)
                },
                onCommitCity = { c ->
                    city = c
                    appendUser(messages, c)
                    advance(scope, SignUpStep.AskInterests, { step = it }, isTyping = { isTyping = it },
                        messages = messages, name = { name }, interests = interests)
                },
                onToggleInterest = { topic ->
                    if (interests.contains(topic)) interests.remove(topic) else interests.add(topic)
                },
                onCommitInterests = {
                    val summary = if (interests.isEmpty()) "تخطّيت" else interests.joinToString(" · ")
                    appendUser(messages, summary)
                    advance(scope, SignUpStep.AskVoice, { step = it }, isTyping = { isTyping = it },
                        messages = messages, name = { name }, interests = interests)
                },
                onCommitVoice = { v ->
                    val trimmed = v.trim()
                    voiceLine = trimmed
                    appendUser(messages, if (trimmed.isEmpty()) "تخطّيت" else "«$trimmed»")
                    advance(scope, SignUpStep.Finishing, { step = it }, isTyping = { isTyping = it },
                        messages = messages, name = { name }, interests = interests)
                    onSubmit(
                        name, email, password, gender, birthYear,
                        city.ifBlank { null }, interests.toList(),
                        trimmed.ifBlank { null }
                    ) { _ ->
                        // Failure: drop back to ask-email so the user can fix.
                        step = SignUpStep.AskEmail
                    }
                }
            )
        }

        // Centered finishing overlay — covers the chat while we register.
        AnimatedVisibility(
            visible = step == SignUpStep.Finishing || step == SignUpStep.Done,
            enter = fadeIn(),
            exit = fadeOut()
        ) {
            SignUpFinishingOverlay(name = name)
        }
    }
}

// ---- Step orchestration ----

private suspend fun runStep(
    next: SignUpStep,
    messages: SnapshotStateList<ChatMsg>,
    setStep: (SignUpStep) -> Unit,
    setTyping: (Boolean) -> Unit,
    name: () -> String,
    interests: SnapshotStateList<String>
) {
    setStep(next)
    when (next) {
        SignUpStep.Greeting -> {
            aiTypeAndSay("أهلاً 👋 أنا TRENDX AI.", messages, setTyping)
            aiTypeAndSay(
                "سأبني ملفّك خلال دقيقتين عبر بضعة أسئلة بسيطة، وكل إجابة تجعل الرؤى التي أقدّمها لك أدقّ.",
                messages, setTyping
            )
            runStep(SignUpStep.AskName, messages, setStep, setTyping, name, interests)
        }
        SignUpStep.AskName -> aiTypeAndSay("لنبدأ — كيف تحبّ أن أناديك؟", messages, setTyping)
        SignUpStep.AskEmail -> aiTypeAndSay(
            "أهلاً ${name()} 🌟 — على أيّ بريد إلكتروني نُسجّلك؟", messages, setTyping
        )
        SignUpStep.AskPassword -> aiTypeAndSay(
            "اختر كلمة مرور آمنة لك — ستحتاجها للدخول لاحقاً.", messages, setTyping
        )
        SignUpStep.AskGender -> aiTypeAndSay(
            "لمَن أُخاطب الآن؟ هذا يساعدني أعرض لك بيانات ممثّلة.", messages, setTyping
        )
        SignUpStep.AskBirthDecade -> aiTypeAndSay(
            "في أيّ جيل تنتمي؟ — هذا يربطك بمن يشاركونك السياق نفسه.", messages, setTyping
        )
        SignUpStep.AskCity -> aiTypeAndSay("من أيّ مدينة تتابعنا؟", messages, setTyping)
        SignUpStep.AskInterests -> aiTypeAndSay(
            "اختر ما يحرّك فضولك (يمكن أكثر من واحد):", messages, setTyping
        )
        SignUpStep.AskVoice -> aiTypeAndSay(
            "سؤال أخير — في كلمة واحدة، ما الذي يهمّك أكثر هذه السنة؟", messages, setTyping
        )
        SignUpStep.Finishing, SignUpStep.Done -> Unit
    }
}

private fun advance(
    scope: kotlinx.coroutines.CoroutineScope,
    next: SignUpStep,
    setStep: (SignUpStep) -> Unit,
    isTyping: (Boolean) -> Unit,
    messages: SnapshotStateList<ChatMsg>,
    name: () -> String,
    interests: SnapshotStateList<String>
) {
    // Run the suspend transition on the screen-scoped coroutine the
    // composable owns — automatically cancels if the user backs out.
    scope.launch {
        runStep(next, messages, setStep, isTyping, name, interests)
    }
}

private suspend fun aiTypeAndSay(
    text: String,
    messages: SnapshotStateList<ChatMsg>,
    setTyping: (Boolean) -> Unit
) {
    setTyping(true)
    val delayMs = (360 + text.length * 18).coerceAtMost(1400).toLong()
    delay(delayMs)
    setTyping(false)
    messages.add(ChatMsg(ChatMsg.Author.Ai, text, System.nanoTime()))
}

private fun appendUser(messages: SnapshotStateList<ChatMsg>, text: String) {
    messages.add(ChatMsg(ChatMsg.Author.User, text, System.nanoTime()))
}

// ---- Header ----

@Composable
private fun ChatHeader(isTyping: Boolean, onSwitchToSignIn: () -> Unit) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 18.dp, vertical = 16.dp)
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .shadow(elevation = 6.dp, shape = CircleShape, clip = false,
                    ambientColor = TrendXColors.Primary, spotColor = TrendXColors.Primary)
                .size(38.dp)
                .clip(CircleShape)
                .background(TrendXGradients.Primary)
        ) {
            Icon(imageVector = Icons.Filled.AutoAwesome, contentDescription = null,
                tint = Color.White, modifier = Modifier.size(16.dp))
        }
        Spacer(Modifier.width(12.dp))
        Column(verticalArrangement = Arrangement.spacedBy(1.dp)) {
            Text(text = "TRENDX AI",
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 14.sp,
                    color = TrendXColors.Ink))
            Text(text = if (isTyping) "يكتب الآن…" else "مرشدك إلى ملفّك",
                style = TextStyle(fontWeight = FontWeight.Medium, fontSize = 11.sp,
                    color = if (isTyping) TrendXColors.Primary else TrendXColors.TertiaryInk))
        }
        Spacer(Modifier.weight(1f))
        Box(
            modifier = Modifier
                .clip(CircleShape)
                .background(TrendXColors.Primary.copy(alpha = 0.10f))
                .clickable(onClick = onSwitchToSignIn)
                .padding(horizontal = 12.dp, vertical = 7.dp)
        ) {
            Text(text = "لديّ حساب",
                style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 12.sp,
                    color = TrendXColors.Primary))
        }
    }
}

// ---- Bubbles ----

@Composable
private fun MessageBubble(msg: ChatMsg) {
    Row(verticalAlignment = Alignment.Bottom,
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (msg.author == ChatMsg.Author.Ai)
            Arrangement.Start else Arrangement.End
    ) {
        if (msg.author == ChatMsg.Author.Ai) {
            AiAvatar()
            Spacer(Modifier.width(10.dp))
            Box(
                modifier = Modifier
                    .widthIn(max = 280.dp)
                    .shadow(elevation = 4.dp, shape = RoundedCornerShape(18.dp), clip = false)
                    .clip(RoundedCornerShape(18.dp))
                    .background(TrendXColors.Surface)
                    .padding(horizontal = 14.dp, vertical = 11.dp)
            ) {
                Text(text = msg.text,
                    style = TextStyle(fontWeight = FontWeight.Medium, fontSize = 15.sp,
                        color = TrendXColors.Ink, lineHeight = 22.sp))
            }
        } else {
            Box(
                modifier = Modifier
                    .widthIn(max = 280.dp)
                    .shadow(elevation = 8.dp, shape = RoundedCornerShape(18.dp), clip = false,
                        ambientColor = TrendXColors.Primary, spotColor = TrendXColors.Primary)
                    .clip(RoundedCornerShape(18.dp))
                    .background(TrendXGradients.Primary)
                    .padding(horizontal = 14.dp, vertical = 11.dp)
            ) {
                Text(text = msg.text,
                    style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 15.sp,
                        color = Color.White, lineHeight = 22.sp))
            }
        }
    }
}

@Composable
private fun TypingBubble() {
    Row(verticalAlignment = Alignment.Bottom, modifier = Modifier.fillMaxWidth()) {
        AiAvatar()
        Spacer(Modifier.width(10.dp))
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier
                .clip(RoundedCornerShape(18.dp))
                .background(TrendXColors.Surface)
                .padding(horizontal = 14.dp, vertical = 11.dp)
        ) {
            val transition = rememberInfiniteTransition(label = "typing")
            (0..2).forEach { i ->
                val alpha by transition.animateFloat(
                    initialValue = 0.3f,
                    targetValue = 1.0f,
                    animationSpec = infiniteRepeatable(
                        animation = tween(350, easing = LinearEasing),
                        repeatMode = RepeatMode.Reverse,
                        initialStartOffset = androidx.compose.animation.core.StartOffset(i * 120)
                    ),
                    label = "dot$i"
                )
                Box(modifier = Modifier
                    .size(7.dp)
                    .clip(CircleShape)
                    .background(TrendXColors.Primary.copy(alpha = alpha)))
                if (i < 2) Spacer(Modifier.width(5.dp))
            }
        }
    }
}

@Composable
private fun AiAvatar() {
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .size(30.dp)
            .clip(CircleShape)
            .background(TrendXGradients.Primary)
    ) {
        Icon(imageVector = Icons.Filled.AutoAwesome, contentDescription = null,
            tint = Color.White, modifier = Modifier.size(12.dp))
    }
}

// ---- Input bar (per-step) ----

@Composable
private fun InputBar(
    step: SignUpStep,
    nameInput: String, onNameChange: (String) -> Unit,
    emailInput: String, onEmailChange: (String) -> Unit,
    passwordInput: String, onPasswordChange: (String) -> Unit,
    voiceLine: String, onVoiceChange: (String) -> Unit,
    interests: SnapshotStateList<String>,
    interestPool: List<String>,
    saudiCities: List<String>,
    onCommitName: () -> Unit,
    onCommitEmail: () -> Unit,
    onCommitPassword: () -> Unit,
    onCommitGender: (UserGender) -> Unit,
    onCommitDecade: (Int?) -> Unit,
    onCommitCity: (String) -> Unit,
    onToggleInterest: (String) -> Unit,
    onCommitInterests: () -> Unit,
    onCommitVoice: (String) -> Unit
) {
    if (step == SignUpStep.Greeting || step == SignUpStep.Finishing || step == SignUpStep.Done) {
        return
    }
    Box(modifier = Modifier
        .fillMaxWidth()
        .background(TrendXColors.Surface.copy(alpha = 0.92f))
        .imePadding()
    ) {
        Box(modifier = Modifier
            .fillMaxWidth()
            .height(0.5.dp)
            .background(TrendXColors.TertiaryInk.copy(alpha = 0.10f)))
        Box(modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)) {
            when (step) {
                SignUpStep.AskName -> InputCard {
                    Icon(Icons.Filled.Person, contentDescription = null,
                        tint = TrendXColors.Primary, modifier = Modifier.size(16.dp))
                    Spacer(Modifier.width(10.dp))
                    PlainTextField(
                        value = nameInput, onValueChange = onNameChange,
                        placeholder = "اسمك الأول",
                        keyboardType = KeyboardType.Text, imeAction = ImeAction.Send,
                        onSubmit = onCommitName,
                        modifier = Modifier.weight(1f)
                    )
                    Spacer(Modifier.width(8.dp))
                    SendButton(enabled = nameInput.trim().isNotEmpty(), onClick = onCommitName)
                }
                SignUpStep.AskEmail -> InputCard {
                    Icon(Icons.Filled.Email, contentDescription = null,
                        tint = TrendXColors.Primary, modifier = Modifier.size(16.dp))
                    Spacer(Modifier.width(10.dp))
                    PlainTextField(
                        value = emailInput, onValueChange = onEmailChange,
                        placeholder = "بريدك الإلكتروني",
                        keyboardType = KeyboardType.Email, imeAction = ImeAction.Send,
                        onSubmit = onCommitEmail,
                        modifier = Modifier.weight(1f)
                    )
                    Spacer(Modifier.width(8.dp))
                    SendButton(enabled = isValidEmail(emailInput), onClick = onCommitEmail)
                }
                SignUpStep.AskPassword -> InputCard {
                    Icon(Icons.Filled.Lock, contentDescription = null,
                        tint = TrendXColors.Primary, modifier = Modifier.size(16.dp))
                    Spacer(Modifier.width(10.dp))
                    PlainTextField(
                        value = passwordInput, onValueChange = onPasswordChange,
                        placeholder = "كلمة مرور (٦ خانات على الأقل)",
                        keyboardType = KeyboardType.Password, imeAction = ImeAction.Send,
                        isPassword = true,
                        onSubmit = onCommitPassword,
                        modifier = Modifier.weight(1f)
                    )
                    Spacer(Modifier.width(8.dp))
                    SendButton(enabled = passwordInput.length >= 6, onClick = onCommitPassword)
                }
                SignUpStep.AskGender -> Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    listOf(UserGender.male, UserGender.female, UserGender.unspecified).forEach { g ->
                        OnboardChip(label = g.displayName, selected = false,
                            onClick = { onCommitGender(g) })
                    }
                }
                SignUpStep.AskBirthDecade -> LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(DecadeOptions) { (label, year) ->
                        OnboardChip(label = label, selected = false,
                            onClick = { onCommitDecade(year) })
                    }
                    item("opt-out") {
                        OnboardChip(label = "أفضّل لا أقول", selected = false,
                            accent = TrendXColors.TertiaryInk,
                            onClick = { onCommitDecade(null) })
                    }
                }
                SignUpStep.AskCity -> LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(saudiCities) { name ->
                        OnboardChip(label = name, selected = false,
                            onClick = { onCommitCity(name) })
                    }
                }
                SignUpStep.AskInterests -> Column(
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    InterestFlow(pool = interestPool, selected = interests,
                        onToggle = onToggleInterest)
                    PrimaryFlatButton(
                        label = if (interests.isEmpty()) "تخطّي"
                                else "اعتمد ${interests.size} اهتماماً",
                        onClick = onCommitInterests
                    )
                }
                SignUpStep.AskVoice -> Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    InputCard {
                        Icon(Icons.Filled.FormatQuote, contentDescription = null,
                            tint = TrendXColors.Primary, modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(10.dp))
                        PlainTextField(
                            value = voiceLine, onValueChange = onVoiceChange,
                            placeholder = "كلمة واحدة، اختياري",
                            keyboardType = KeyboardType.Text, imeAction = ImeAction.Default,
                            singleLine = false,
                            modifier = Modifier.weight(1f)
                        )
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        SecondaryFlatButton(label = "تخطّي",
                            onClick = { onCommitVoice("") },
                            modifier = Modifier.weight(1f))
                        PrimaryFlatButton(label = "ابدأ TRENDX",
                            onClick = { onCommitVoice(voiceLine) },
                            modifier = Modifier.weight(1f))
                    }
                }
                else -> Unit
            }
        }
    }
}

@Composable
private fun InputCard(content: @Composable androidx.compose.foundation.layout.RowScope.() -> Unit) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .shadow(elevation = 4.dp, shape = RoundedCornerShape(16.dp), clip = false)
            .clip(RoundedCornerShape(16.dp))
            .background(TrendXColors.Surface)
            .padding(horizontal = 14.dp, vertical = 11.dp),
        content = content
    )
}

@Composable
private fun PlainTextField(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    keyboardType: KeyboardType,
    imeAction: ImeAction,
    onSubmit: () -> Unit = {},
    isPassword: Boolean = false,
    singleLine: Boolean = true,
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier) {
        if (value.isEmpty()) {
            Text(text = placeholder,
                style = TextStyle(fontWeight = FontWeight.Medium, fontSize = 14.sp,
                    color = TrendXColors.TertiaryInk))
        }
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            singleLine = singleLine,
            visualTransformation = if (isPassword) PasswordVisualTransformation()
                else androidx.compose.ui.text.input.VisualTransformation.None,
            cursorBrush = SolidColor(TrendXColors.Primary),
            keyboardOptions = KeyboardOptions(keyboardType = keyboardType, imeAction = imeAction),
            keyboardActions = androidx.compose.foundation.text.KeyboardActions(
                onSend = { onSubmit() }
            ),
            textStyle = LocalTextStyle.current.merge(TextStyle(
                fontWeight = FontWeight.Medium, fontSize = 14.sp, color = TrendXColors.Ink
            )),
            modifier = Modifier.fillMaxWidth()
        )
    }
}

@Composable
private fun SendButton(enabled: Boolean, onClick: () -> Unit) {
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .size(36.dp)
            .clip(CircleShape)
            .background(if (enabled) Brush.linearGradient(
                listOf(TrendXColors.Primary, TrendXColors.PrimaryLight)
            ) else SolidColor(TrendXColors.TertiaryInk.copy(alpha = 0.4f)))
            .clickable(enabled = enabled, onClick = onClick)
    ) {
        Icon(imageVector = Icons.Filled.ArrowUpward, contentDescription = "إرسال",
            tint = Color.White, modifier = Modifier.size(18.dp))
    }
}

@Composable
private fun OnboardChip(
    label: String,
    selected: Boolean,
    accent: Color = TrendXColors.Primary,
    onClick: () -> Unit
) {
    val bg = if (selected) Brush.linearGradient(
        listOf(TrendXColors.Primary, TrendXColors.PrimaryLight)
    ) else SolidColor(accent.copy(alpha = 0.10f))
    val fg = if (selected) Color.White else accent
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .clip(CircleShape)
            .background(bg)
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 9.dp)
    ) {
        Text(text = label,
            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 13.sp, color = fg))
    }
}

@Composable
private fun InterestFlow(
    pool: List<String>,
    selected: SnapshotStateList<String>,
    onToggle: (String) -> Unit
) {
    // Compose has no built-in flow-row in stable APIs we use elsewhere;
    // we simulate one with chunked rows of width-fitting chips.
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        pool.chunked(3).forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                row.forEach { topic ->
                    OnboardChip(label = topic, selected = selected.contains(topic),
                        onClick = { onToggle(topic) })
                }
            }
        }
    }
}

@Composable
private fun PrimaryFlatButton(
    label: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        contentAlignment = Alignment.Center,
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(TrendXGradients.Primary)
            .clickable(onClick = onClick)
            .padding(vertical = 13.dp)
    ) {
        Text(text = label,
            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 14.sp, color = Color.White))
    }
}

@Composable
private fun SecondaryFlatButton(
    label: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        contentAlignment = Alignment.Center,
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(TrendXColors.SoftFill)
            .clickable(onClick = onClick)
            .padding(vertical = 12.dp)
    ) {
        Text(text = label,
            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 13.sp,
                color = TrendXColors.SecondaryInk))
    }
}

// ---- Finishing overlay ----

@Composable
private fun SignUpFinishingOverlay(name: String) {
    val transition = rememberInfiniteTransition(label = "finishing")
    val orbScale by transition.animateFloat(
        initialValue = 0.92f, targetValue = 1.06f,
        animationSpec = infiniteRepeatable(
            animation = tween(1600, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ), label = "orbScale"
    )
    var dotIndex by remember { mutableStateOf(0) }
    LaunchedEffect(Unit) {
        while (true) {
            delay(380)
            dotIndex = (dotIndex + 1) % 3
        }
    }

    Box(modifier = Modifier
        .fillMaxSize()
        .background(Brush.linearGradient(listOf(
            TrendXColors.Background,
            TrendXColors.Primary.copy(alpha = 0.10f),
            TrendXColors.AiViolet.copy(alpha = 0.08f)
        )))
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(28.dp),
            modifier = Modifier.fillMaxSize().padding(horizontal = 32.dp)
        ) {
            Spacer(Modifier.weight(1f))
            // Orb
            Box(modifier = Modifier.size(220.dp), contentAlignment = Alignment.Center) {
                Box(modifier = Modifier
                    .size(116.dp)
                    .scale(orbScale)
                    .clip(CircleShape)
                    .background(Brush.linearGradient(listOf(
                        TrendXColors.AiIndigo, TrendXColors.Primary, TrendXColors.AiViolet
                    )))
                    .shadow(elevation = 22.dp, shape = CircleShape, clip = false,
                        ambientColor = TrendXColors.Primary, spotColor = TrendXColors.Primary),
                    contentAlignment = Alignment.Center) {
                    Icon(imageVector = Icons.Filled.AutoAwesome, contentDescription = null,
                        tint = Color.White, modifier = Modifier.size(36.dp))
                }
            }
            Column(horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(text = "أُعدّ ملفّك يا $name…",
                    style = TextStyle(fontWeight = FontWeight.Black, fontSize = 22.sp,
                        color = TrendXColors.Ink))
                Text(text = "أربط اختياراتك ببيانات اليوم.",
                    style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 13.sp,
                        color = TrendXColors.SecondaryInk))
            }
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                (0..2).forEach { i ->
                    val isActive = dotIndex == i
                    Box(modifier = Modifier
                        .size(if (isActive) 10.dp else 8.dp)
                        .clip(CircleShape)
                        .background(TrendXColors.Primary.copy(alpha = if (isActive) 1f else 0.4f)))
                }
            }
            Spacer(Modifier.weight(1f))
            Spacer(Modifier.weight(1f))
        }
    }
}

// ---- Helpers + constants ----

private fun isValidEmail(s: String): Boolean {
    val v = s.trim()
    return v.contains('@') && v.contains('.') && v.length >= 5
}

private fun decadeLabelForYear(year: Int): String = when {
    year >= 2000 -> "جيل 2000s"
    year in 1990..1999 -> "جيل 1990s"
    year in 1980..1989 -> "جيل 1980s"
    year in 1970..1979 -> "جيل 1970s"
    else -> "قبل 1970"
}

private val DecadeOptions = listOf(
    "جيل 2000s" to 2002,
    "جيل 1990s" to 1995,
    "جيل 1980s" to 1985,
    "جيل 1970s" to 1975,
    "قبل 1970" to 1965
)

private val DefaultSaudiCities = listOf(
    "الرياض", "جدة", "مكة المكرمة", "المدينة المنورة", "الدمام",
    "الخبر", "الظهران", "الطائف", "أبها", "تبوك", "بريدة", "حائل",
    "الجبيل", "ينبع", "نجران", "الباحة", "جازان", "عرعر", "سكاكا"
)

private val DefaultInterestPool = listOf(
    "السياسة", "الاقتصاد", "التقنية", "الذكاء الاصطناعي",
    "الرياضة", "الصحّة", "التعليم", "الترفيه", "السياحة",
    "الفنّ والثقافة", "البيئة", "الإعلام"
)
