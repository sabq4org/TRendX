package com.trendx.app.ui.screens.account

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Base64
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Cake
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Domain
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Female
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Notes
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Public
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.models.AccountType
import com.trendx.app.models.MemberTier as MemberTierModel
import com.trendx.app.models.TrendXUser
import com.trendx.app.models.UserGender
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients
import com.trendx.app.theme.TrendXType
import com.trendx.app.ui.components.DetailScreenScaffold
import com.trendx.app.ui.components.MemberTierBadge
import com.trendx.app.ui.components.ToolbarTextPill
import com.trendx.app.ui.components.TrendXProfileImage
import java.io.ByteArrayOutputStream
import kotlin.math.max
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

// Mirrors TRENDX/Screens/ProfileEditScreen.swift. Every editable field
// the iOS form ships: name, email, handle (@), bio, city, country,
// account type (individual/organization — government is admin-promoted),
// gender, birth year, and avatar. The avatar uses Android's modern
// PhotosPicker, then resizes/compresses the picked image into a
// `data:image/jpeg;base64,…` URL and POSTs it through the same
// `/profile` endpoint iOS uses. Region was removed from the iOS form too
// (city + country are enough) so we mirror that here.
@Composable
fun ProfileEditScreen(
    user: TrendXUser,
    onClose: () -> Unit,
    onSave: (
        name: String,
        email: String,
        handle: String?,
        bio: String?,
        city: String?,
        country: String?,
        gender: String?,
        birthYear: Int?,
        accountType: String?,
        avatarUrl: String?,
        onError: (String) -> Unit
    ) -> Unit,
    isSaving: Boolean = false,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    var name by remember(user.id) { mutableStateOf(user.name) }
    var email by remember(user.id) { mutableStateOf(user.email) }
    var handle by remember(user.id) { mutableStateOf(user.handle.orEmpty()) }
    var bio by remember(user.id) { mutableStateOf(user.bio.orEmpty()) }
    var city by remember(user.id) { mutableStateOf(user.city.orEmpty()) }
    var country by remember(user.id) { mutableStateOf(user.country.ifBlank { "SA" }) }
    var gender by remember(user.id) { mutableStateOf(user.gender) }
    var birthYear by remember(user.id) { mutableIntStateOf(user.birthYear ?: 2000) }
    var accountType by remember(user.id) { mutableStateOf(user.accountType) }
    var avatarUrl by remember(user.id) { mutableStateOf(user.avatarUrl.orEmpty()) }
    var isProcessingImage by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    val pickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia()
    ) { uri: Uri? ->
        if (uri != null) {
            isProcessingImage = true
            scope.launch {
                val dataUrl = withContext(Dispatchers.IO) {
                    processImageToDataUrl(context, uri, maxDim = 480, qualityPercent = 60)
                }
                isProcessingImage = false
                if (dataUrl == null) {
                    error = "تعذّر معالجة الصورة. حاول صورة أخرى أصغر حجماً."
                } else {
                    avatarUrl = dataUrl
                    error = null
                }
            }
        }
    }

    val nameTrim = name.trim()
    val emailTrim = email.trim()
    val handleTrim = handle.trim().removePrefix("@")
    val canSave = nameTrim.isNotBlank() && emailTrim.contains("@") && (
        nameTrim != user.name ||
            emailTrim != user.email ||
            handleTrim != user.handle.orEmpty() ||
            bio.trim() != user.bio.orEmpty() ||
            city.trim() != user.city.orEmpty() ||
            country != user.country.ifBlank { "SA" } ||
            gender != user.gender ||
            birthYear != (user.birthYear ?: 2000) ||
            accountType != user.accountType ||
            avatarUrl != user.avatarUrl.orEmpty()
        )

    DetailScreenScaffold(
        title = "الملف الشخصي",
        onClose = onClose,
        trailing = {
            ToolbarTextPill(
                label = if (isSaving) "حفظ…" else "حفظ",
                enabled = canSave && !isSaving,
                onClick = {
                    error = null
                    onSave(
                        nameTrim,
                        emailTrim,
                        handleTrim.takeIf { it.isNotBlank() },
                        bio.trim().takeIf { it.isNotBlank() },
                        city.trim().takeIf { it.isNotBlank() },
                        country,
                        gender.name,
                        birthYear,
                        accountType.name,
                        avatarUrl.takeIf { it.isNotBlank() }
                    ) { msg -> error = msg }
                }
            )
        },
        modifier = modifier
    ) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(start = 20.dp, end = 20.dp,
                top = 8.dp, bottom = 40.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item("hero") {
                AvatarHero(
                    avatarUrl = avatarUrl,
                    fallbackInitial = user.avatarInitial.ifEmpty { name.take(1) },
                    name = name,
                    points = user.points,
                    isProcessingImage = isProcessingImage,
                    onPickAvatar = {
                        pickerLauncher.launch(
                            PickVisualMediaRequest(
                                ActivityResultContracts.PickVisualMedia.ImageOnly
                            )
                        )
                    }
                )
            }
            error?.let { msg ->
                item("error") {
                    Text(text = msg, style = TrendXType.Small, color = TrendXColors.Error)
                }
            }
            item("form") {
                FormCard {
                    EditField(label = "الاسم", value = name, onChange = { name = it },
                        placeholder = "اسمك الكامل", icon = Icons.Filled.Person)
                    Divider()
                    EditField(
                        label = "البريد الإلكتروني", value = email,
                        onChange = { email = it },
                        placeholder = "you@example.com",
                        keyboardType = KeyboardType.Email,
                        icon = Icons.Filled.Email
                    )
                    Divider()
                    EditField(label = "المعرّف", value = handle, onChange = { handle = it },
                        placeholder = "@you", prefix = "@", icon = Icons.Filled.Person)
                    Divider()
                    EditField(label = "نبذة قصيرة", value = bio, onChange = { bio = it },
                        placeholder = "اكتب جملة عن نفسك", lines = 3,
                        icon = Icons.Filled.Notes)
                    Divider()
                    EditField(label = "المدينة", value = city, onChange = { city = it },
                        placeholder = "الرياض / جدة / …", icon = Icons.Filled.LocationOn)
                    Divider()
                    CountryRow(country = country, onChange = { country = it })
                    Divider()
                    if (accountType != AccountType.government) {
                        AccountTypeRow(value = accountType, onChange = { accountType = it })
                        Divider()
                    }
                    GenderRow(value = gender, onChange = { gender = it })
                    Divider()
                    BirthYearRow(value = birthYear, onChange = { birthYear = it })
                }
            }
        }
    }
}

@Composable
private fun AvatarHero(
    avatarUrl: String,
    fallbackInitial: String,
    name: String,
    points: Int,
    isProcessingImage: Boolean,
    onPickAvatar: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp),
        modifier = Modifier
            .fillMaxWidth()
            .shadow(elevation = 14.dp, shape = RoundedCornerShape(20.dp), clip = false,
                ambientColor = TrendXColors.Primary, spotColor = TrendXColors.Primary)
            .clip(RoundedCornerShape(20.dp))
            .background(TrendXGradients.Header)
            .padding(20.dp)
    ) {
        Box(modifier = Modifier.size(112.dp), contentAlignment = Alignment.BottomEnd) {
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .shadow(elevation = 14.dp, shape = CircleShape, clip = false,
                        ambientColor = TrendXColors.PrimaryDeep,
                        spotColor = TrendXColors.PrimaryDeep)
                    .size(108.dp)
                    .clip(CircleShape)
                    .background(Color.White)
                    .clickable(onClick = onPickAvatar)
            ) {
                TrendXProfileImage(
                    urlString = avatarUrl.takeIf { it.isNotBlank() },
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.size(102.dp).clip(CircleShape)
                ) {
                    Text(
                        text = fallbackInitial,
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 40.sp,
                            color = TrendXColors.PrimaryDeep)
                    )
                }
            }
            // Camera badge — opens system photo picker. While the picked
            // image is being resized + base64-encoded we show a spinner
            // in the badge so the user knows we're busy.
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .shadow(elevation = 6.dp, shape = CircleShape, clip = false)
                    .size(34.dp)
                    .clip(CircleShape)
                    .background(TrendXColors.Accent)
                    .border(2.dp, Color.White, CircleShape)
                    .clickable(onClick = onPickAvatar)
            ) {
                if (isProcessingImage) {
                    CircularProgressIndicator(
                        color = Color.White,
                        strokeWidth = 1.5.dp,
                        modifier = Modifier.size(15.dp)
                    )
                } else {
                    Icon(imageVector = Icons.Filled.CameraAlt,
                        contentDescription = "تعديل الصورة",
                        tint = Color.White, modifier = Modifier.size(15.dp))
                }
            }
        }
        Text(text = name.ifBlank { "اسمك" },
            style = TextStyle(fontWeight = FontWeight.Black, fontSize = 18.sp,
                color = Color.White))
        MemberTierBadge(tier = MemberTierModel.from(points), compact = true)
        Text(text = "اضغط الصورة لاختيار صورة جديدة من معرضك.",
            style = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 11.sp,
                color = Color.White.copy(alpha = 0.78f)))
    }
}

@Composable
private fun FormCard(content: @Composable () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(TrendXColors.Surface)
            .border(0.8.dp, TrendXColors.Outline, RoundedCornerShape(20.dp))
    ) {
        content()
    }
}

@Composable
private fun Divider() {
    Box(modifier = Modifier
        .fillMaxWidth()
        .padding(horizontal = 14.dp)
        .height(0.5.dp)
        .background(TrendXColors.Outline.copy(alpha = 0.4f)))
}

@Composable
private fun FieldIcon(icon: ImageVector) {
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .size(28.dp)
            .clip(CircleShape)
            .background(TrendXColors.Primary.copy(alpha = 0.10f))
    ) {
        Icon(imageVector = icon, contentDescription = null, tint = TrendXColors.Primary,
            modifier = Modifier.size(11.dp))
    }
}

@Composable
private fun EditField(
    label: String,
    value: String,
    onChange: (String) -> Unit,
    placeholder: String,
    icon: ImageVector,
    lines: Int = 1,
    prefix: String? = null,
    keyboardType: KeyboardType = KeyboardType.Text
) {
    Column(verticalArrangement = Arrangement.spacedBy(6.dp),
        modifier = Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            FieldIcon(icon = icon)
            Spacer(Modifier.width(10.dp))
            Text(text = label, style = TextStyle(fontWeight = FontWeight.Black,
                fontSize = 12.sp, color = TrendXColors.TertiaryInk))
        }
        OutlinedTextField(
            value = value,
            onValueChange = onChange,
            placeholder = { Text(text = placeholder) },
            singleLine = lines == 1,
            minLines = if (lines > 1) lines else 1,
            maxLines = if (lines > 1) lines else 1,
            prefix = prefix?.let { { Text(text = it) } },
            keyboardOptions = KeyboardOptions(
                keyboardType = keyboardType,
                imeAction = if (lines > 1) ImeAction.Default else ImeAction.Next
            ),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = TrendXColors.Primary,
                unfocusedBorderColor = TrendXColors.Outline,
                focusedContainerColor = TrendXColors.Surface,
                unfocusedContainerColor = TrendXColors.Surface
            ),
            modifier = Modifier.fillMaxWidth()
        )
    }
}

@Composable
private fun CountryRow(country: String, onChange: (String) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            FieldIcon(icon = Icons.Filled.Public)
            Spacer(Modifier.width(10.dp))
            Text(text = "الدولة", style = TextStyle(fontWeight = FontWeight.Black,
                fontSize = 12.sp, color = TrendXColors.TertiaryInk))
        }
        LazyRow(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            items(CountryList) { entry ->
                val isSelected = entry.code == country
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(if (isSelected) TrendXColors.Primary
                                    else TrendXColors.SoftFill)
                        .clickable { onChange(entry.code) }
                        .padding(horizontal = 10.dp, vertical = 6.dp)
                ) {
                    Text(text = "${entry.flag} ${entry.name}",
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                            color = if (isSelected) Color.White
                                    else TrendXColors.SecondaryInk))
                }
            }
        }
    }
}

@Composable
private fun AccountTypeRow(value: AccountType, onChange: (AccountType) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            FieldIcon(icon = Icons.Filled.Domain)
            Spacer(Modifier.width(10.dp))
            Text(text = "نوع الحساب", style = TextStyle(fontWeight = FontWeight.Black,
                fontSize = 12.sp, color = TrendXColors.TertiaryInk))
        }
        SegmentBar(
            options = listOf(AccountType.individual to "فرد",
                AccountType.organization to "منظّمة"),
            selected = value,
            onSelect = onChange
        )
    }
}

@Composable
private fun GenderRow(value: UserGender, onChange: (UserGender) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            FieldIcon(icon = Icons.Filled.Female)
            Spacer(Modifier.width(10.dp))
            Text(text = "الجنس", style = TextStyle(fontWeight = FontWeight.Black,
                fontSize = 12.sp, color = TrendXColors.TertiaryInk))
        }
        SegmentBar(
            options = listOf(
                UserGender.male to "ذكر",
                UserGender.female to "أنثى",
                UserGender.unspecified to "غير محدّد"
            ),
            selected = value,
            onSelect = onChange
        )
    }
}

@Composable
private fun BirthYearRow(value: Int, onChange: (Int) -> Unit) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 12.dp)
    ) {
        FieldIcon(icon = Icons.Filled.Cake)
        Spacer(Modifier.width(10.dp))
        Text(text = "سنة الميلاد", style = TextStyle(fontWeight = FontWeight.Black,
            fontSize = 12.sp, color = TrendXColors.TertiaryInk))
        Spacer(Modifier.weight(1f))
        Row(verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            StepperButton(icon = Icons.Filled.Remove,
                enabled = value > 1940,
                onClick = { if (value > 1940) onChange(value - 1) })
            Text(text = value.toString(),
                style = TextStyle(fontWeight = FontWeight.Black, fontSize = 15.sp,
                    color = TrendXColors.Ink))
            StepperButton(icon = Icons.Filled.Add,
                enabled = value < 2026,
                onClick = { if (value < 2026) onChange(value + 1) })
        }
    }
}

@Composable
private fun StepperButton(icon: ImageVector, enabled: Boolean, onClick: () -> Unit) {
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .size(28.dp)
            .clip(CircleShape)
            .background(TrendXColors.Primary.copy(alpha = if (enabled) 0.10f else 0.04f))
            .clickable(enabled = enabled, onClick = onClick)
    ) {
        Icon(imageVector = icon, contentDescription = null,
            tint = TrendXColors.Primary.copy(alpha = if (enabled) 1f else 0.5f),
            modifier = Modifier.size(11.dp))
    }
}

@Composable
private fun <T> SegmentBar(
    options: List<Pair<T, String>>,
    selected: T,
    onSelect: (T) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(TrendXColors.SoftFill)
            .padding(3.dp)
    ) {
        options.forEach { (value, label) ->
            val isSelected = value == selected
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(10.dp))
                    .background(if (isSelected) TrendXColors.Primary else Color.Transparent)
                    .clickable { onSelect(value) }
                    .padding(vertical = 8.dp)
            ) {
                Text(text = label, style = TextStyle(
                    fontWeight = FontWeight.Black, fontSize = 12.sp,
                    color = if (isSelected) Color.White else TrendXColors.SecondaryInk
                ))
            }
        }
    }
}

private data class CountryEntry(val code: String, val flag: String, val name: String)
private val CountryList = listOf(
    CountryEntry("SA", "🇸🇦", "السعودية"),
    CountryEntry("AE", "🇦🇪", "الإمارات"),
    CountryEntry("KW", "🇰🇼", "الكويت"),
    CountryEntry("QA", "🇶🇦", "قطر"),
    CountryEntry("BH", "🇧🇭", "البحرين"),
    CountryEntry("OM", "🇴🇲", "عُمان"),
    CountryEntry("EG", "🇪🇬", "مصر"),
    CountryEntry("JO", "🇯🇴", "الأردن"),
    CountryEntry("LB", "🇱🇧", "لبنان"),
    CountryEntry("SY", "🇸🇾", "سوريا"),
    CountryEntry("IQ", "🇮🇶", "العراق"),
    CountryEntry("YE", "🇾🇪", "اليمن"),
    CountryEntry("MA", "🇲🇦", "المغرب"),
    CountryEntry("DZ", "🇩🇿", "الجزائر"),
    CountryEntry("TN", "🇹🇳", "تونس"),
    CountryEntry("LY", "🇱🇾", "ليبيا"),
    CountryEntry("SD", "🇸🇩", "السودان"),
    CountryEntry("PS", "🇵🇸", "فلسطين")
)

/// Resize + JPEG-compress + base64-encode the user's picked image to a
/// `data:image/jpeg;base64,…` URL we can ship through the `/profile`
/// endpoint without a separate upload pipeline. Mirrors the iOS path
/// (max 480px, 60% quality → ~80KB payload typical).
private fun processImageToDataUrl(
    context: Context,
    uri: Uri,
    maxDim: Int,
    qualityPercent: Int
): String? {
    return try {
        val bitmap = context.contentResolver.openInputStream(uri)?.use { input ->
            BitmapFactory.decodeStream(input)
        } ?: return null
        val resized = resizeBitmap(bitmap, maxDim)
        val output = ByteArrayOutputStream()
        resized.compress(Bitmap.CompressFormat.JPEG, qualityPercent.coerceIn(1, 100), output)
        val base64 = Base64.encodeToString(output.toByteArray(), Base64.NO_WRAP)
        "data:image/jpeg;base64,$base64"
    } catch (_: Throwable) {
        null
    }
}

private fun resizeBitmap(bitmap: Bitmap, maxDim: Int): Bitmap {
    val w = bitmap.width
    val h = bitmap.height
    val largest = max(w, h)
    if (largest <= maxDim) return bitmap
    val scale = maxDim.toFloat() / largest
    return Bitmap.createScaledBitmap(bitmap, (w * scale).toInt(), (h * scale).toInt(), true)
}
