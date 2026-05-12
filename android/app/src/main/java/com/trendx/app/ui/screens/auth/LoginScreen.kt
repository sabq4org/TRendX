package com.trendx.app.ui.screens.auth

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
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
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
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

private enum class AuthMode { SignUp, SignIn }

// Faithful port of TRENDX/Screens/Auth/LoginScreen.swift — mode switcher
// between SmartSignUpFlow (new users) and a focused SignInCard (returning
// users). The default mode is SignUp, and "لديّ حساب" / "جديد على
// TRENDX؟" buttons flip between the two.
@Composable
fun LoginScreen(
    onSignIn: (email: String, password: String, onError: (String) -> Unit) -> Unit,
    onSignUp: (
        name: String, email: String, password: String,
        gender: UserGender, birthYear: Int?, city: String?,
        interests: List<String>, voiceLine: String?,
        onError: (String) -> Unit
    ) -> Unit,
    onContinueAsGuest: () -> Unit,
    isLoading: Boolean = false,
    isRemoteEnabled: Boolean = true,
    modifier: Modifier = Modifier
) {
    var mode by remember { mutableStateOf(AuthMode.SignUp) }

    Box(modifier = modifier.fillMaxSize()) {
        AnimatedContent(
            targetState = mode,
            transitionSpec = {
                fadeIn(androidx.compose.animation.core.tween(280)) togetherWith
                    fadeOut(androidx.compose.animation.core.tween(180))
            },
            label = "auth-mode"
        ) { current ->
            when (current) {
                AuthMode.SignUp -> SmartSignUpFlow(
                    onSwitchToSignIn = { mode = AuthMode.SignIn },
                    onSubmit = onSignUp
                )
                AuthMode.SignIn -> SignInCard(
                    onSignIn = onSignIn,
                    onSwitchToSignUp = { mode = AuthMode.SignUp },
                    onContinueAsGuest = onContinueAsGuest,
                    isLoading = isLoading,
                    isRemoteEnabled = isRemoteEnabled
                )
            }
        }
    }
}

// ---- Sign-in card ----

@Composable
private fun SignInCard(
    onSignIn: (email: String, password: String, onError: (String) -> Unit) -> Unit,
    onSwitchToSignUp: () -> Unit,
    onContinueAsGuest: () -> Unit,
    isLoading: Boolean,
    isRemoteEnabled: Boolean
) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var error by remember { mutableStateOf<String?>(null) }

    val canSubmit = email.contains('@') && password.length >= 6 && !isLoading

    Box(modifier = Modifier.fillMaxSize()) {
        TrendXAmbientBackground()
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .imePadding(),
            contentPadding = PaddingValues(start = 22.dp, end = 22.dp,
                top = 60.dp, bottom = 60.dp),
            verticalArrangement = Arrangement.spacedBy(22.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            item("brand") {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Text(text = "TRENDX",
                        style = TextStyle(fontFamily = FontFamily.Default,
                            fontWeight = FontWeight.Black, fontSize = 38.sp,
                            color = TrendXColors.PrimaryDeep))
                    Text(text = "مرحباً مرة أخرى — لوحتك تنتظرك",
                        style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 14.sp,
                            color = TrendXColors.SecondaryInk))
                }
            }
            item("card") {
                Column(
                    verticalArrangement = Arrangement.spacedBy(14.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .shadow(elevation = 12.dp, shape = RoundedCornerShape(22.dp), clip = false)
                        .clip(RoundedCornerShape(22.dp))
                        .background(TrendXColors.Surface)
                        .padding(18.dp)
                ) {
                    AuthField(
                        title = "البريد", value = email, onValueChange = { email = it },
                        icon = Icons.Filled.Email, keyboardType = KeyboardType.Email
                    )
                    AuthField(
                        title = "كلمة المرور", value = password, onValueChange = { password = it },
                        icon = Icons.Filled.Lock, keyboardType = KeyboardType.Password,
                        isPassword = true
                    )
                    error?.let {
                        Text(text = it, style = TextStyle(fontSize = 12.sp,
                            fontWeight = FontWeight.Medium, color = TrendXColors.Error))
                    }
                    PrimaryGradientButton(
                        label = if (isLoading) "..." else "دخول",
                        enabled = canSubmit,
                        isLoading = isLoading,
                        onClick = {
                            error = null
                            onSignIn(email.trim(), password) { error = it }
                        }
                    )
                    SwitchToSignUpButton(onClick = onSwitchToSignUp)
                    Text(
                        text = if (isRemoteEnabled) "متصل بـ TRENDX API"
                               else "وضع محلي احتياطي حتى تضيف رابط API",
                        style = TextStyle(fontSize = 12.sp, fontWeight = FontWeight.Medium,
                            color = TrendXColors.TertiaryInk),
                        modifier = Modifier.fillMaxWidth(),
                        textAlign = androidx.compose.ui.text.style.TextAlign.Center
                    )
                }
            }
            item("guest") {
                TextButton(onClick = onContinueAsGuest) {
                    Text(text = "متابعة كزائر",
                        style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 13.sp,
                            color = TrendXColors.SecondaryInk))
                }
            }
        }
    }
}

@Composable
private fun AuthField(
    title: String,
    value: String,
    onValueChange: (String) -> Unit,
    icon: ImageVector,
    keyboardType: KeyboardType,
    isPassword: Boolean = false
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(TrendXColors.SoftFill)
            .padding(horizontal = 14.dp, vertical = 14.dp)
    ) {
        Icon(imageVector = icon, contentDescription = null, tint = TrendXColors.Primary,
            modifier = Modifier.size(18.dp))
        Spacer(Modifier.width(10.dp))
        Box(modifier = Modifier.weight(1f)) {
            if (value.isEmpty()) {
                Text(text = title,
                    style = TextStyle(fontWeight = FontWeight.Medium, fontSize = 14.sp,
                        color = TrendXColors.TertiaryInk))
            }
            BasicTextField(
                value = value,
                onValueChange = onValueChange,
                singleLine = true,
                visualTransformation = if (isPassword) PasswordVisualTransformation()
                    else androidx.compose.ui.text.input.VisualTransformation.None,
                cursorBrush = SolidColor(TrendXColors.Primary),
                keyboardOptions = KeyboardOptions(
                    keyboardType = keyboardType,
                    imeAction = if (isPassword) ImeAction.Done else ImeAction.Next
                ),
                textStyle = LocalTextStyle.current.merge(TextStyle(
                    fontWeight = FontWeight.Medium, fontSize = 14.sp,
                    color = TrendXColors.Ink
                )),
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

@Composable
private fun PrimaryGradientButton(
    label: String,
    enabled: Boolean,
    isLoading: Boolean,
    onClick: () -> Unit
) {
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(
                if (enabled) TrendXGradients.Primary
                else SolidColor(TrendXColors.TertiaryInk.copy(alpha = 0.45f))
            )
            .clickable(enabled = enabled, onClick = onClick)
            .padding(vertical = 15.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (isLoading) {
                CircularProgressIndicator(color = Color.White, strokeWidth = 1.6.dp,
                    modifier = Modifier.size(14.dp))
                Spacer(Modifier.width(10.dp))
            }
            Text(text = label,
                style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 16.sp,
                    color = Color.White))
        }
    }
}

@Composable
private fun SwitchToSignUpButton(onClick: () -> Unit) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(TrendXColors.Primary.copy(alpha = 0.10f))
            .clickable(onClick = onClick)
            .padding(vertical = 11.dp)
    ) {
        Icon(imageVector = Icons.Filled.AutoAwesome, contentDescription = null,
            tint = TrendXColors.Primary, modifier = Modifier.size(13.dp))
        Spacer(Modifier.width(6.dp))
        Text(text = "جديد على TRENDX؟ سجّل بأسلوب AI",
            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 13.sp,
                color = TrendXColors.Primary))
    }
}
