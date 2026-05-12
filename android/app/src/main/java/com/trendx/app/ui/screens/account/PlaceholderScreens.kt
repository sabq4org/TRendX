package com.trendx.app.ui.screens.account

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.GpsFixed
import androidx.compose.material.icons.filled.PeopleAlt
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trendx.app.theme.TrendXColors
import com.trendx.app.theme.TrendXGradients
import com.trendx.app.ui.components.DetailScreenScaffold

// Placeholders for Account sub-screens that need a dedicated Compose
// port + backend wiring (PublicProfile, MyNetwork follow graph, Opinion
// DNA, TRENDX Index, Predictive Accuracy). Each one shows the iOS hero
// chrome and a "قيد الإنشاء" body so the AccountScreen entries route
// somewhere meaningful instead of an app-message banner. Each gets
// fully ported in its own session.

// MyNetworkScreen + PublicProfileScreen now live in their own files
// (real implementations against /me/following + /me/followers + /users/:id).
// The placeholder versions used to live here for the first scaffold pass.

@Composable
fun OpinionDNAScreen(onClose: () -> Unit, modifier: Modifier = Modifier) =
    PlaceholderHero(
        title = "بصمة الرأي",
        eyebrow = "TRENDX AI",
        body = "تحليل خاص لاهتماماتك ونمط تصويتك مع أقرب الشخصيات إليك في المجتمع. قيد الإنشاء.",
        icon = Icons.Filled.AutoAwesome,
        accent = TrendXGradients.Ai,
        accentColor = TrendXColors.AiViolet,
        onClose = onClose,
        modifier = modifier
    )

@Composable
fun TrendXIndexScreen(onClose: () -> Unit, modifier: Modifier = Modifier) =
    PlaceholderHero(
        title = "مؤشر TRENDX",
        eyebrow = "نبض السعودية اليومي",
        body = "مؤشر مركّب يعكس مزاج الرأي العام السعودي يومياً (0–100) مع تفصيل لكل قطاع. قيد الإنشاء.",
        icon = Icons.Filled.TrendingUp,
        accent = TrendXGradients.Ai,
        accentColor = TrendXColors.AiViolet,
        onClose = onClose,
        modifier = modifier
    )

@Composable
fun PredictionAccuracyScreen(onClose: () -> Unit, modifier: Modifier = Modifier) =
    PlaceholderHero(
        title = "دقة توقّعاتك",
        eyebrow = "كم مرة كنت محقاً قبل النتيجة؟",
        body = "تتبّع توقّعاتك وقارنها بالنتيجة النهائية. كل توقّع صحيح يكسبك نقاطاً مضاعفة. قيد الإنشاء.",
        icon = Icons.Filled.GpsFixed,
        accent = Brush.linearGradient(listOf(TrendXColors.Success, TrendXColors.AiCyan)),
        accentColor = TrendXColors.Success,
        onClose = onClose,
        modifier = modifier
    )

@Composable
private fun PlaceholderHero(
    title: String,
    eyebrow: String,
    body: String,
    icon: ImageVector,
    accent: Brush,
    accentColor: Color,
    onClose: () -> Unit,
    modifier: Modifier
) {
    DetailScreenScaffold(
        title = title,
        onClose = onClose,
        modifier = modifier
    ) {
        Box(modifier = Modifier.fillMaxSize().padding(20.dp),
            contentAlignment = Alignment.Center) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(18.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(elevation = 16.dp, shape = RoundedCornerShape(24.dp), clip = false,
                        ambientColor = accentColor, spotColor = accentColor)
                    .clip(RoundedCornerShape(24.dp))
                    .background(TrendXColors.Surface)
                    .border(1.dp, accentColor.copy(alpha = 0.18f), RoundedCornerShape(24.dp))
                    .padding(28.dp)
            ) {
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier
                        .shadow(elevation = 18.dp, shape = CircleShape, clip = false,
                            ambientColor = accentColor, spotColor = accentColor)
                        .size(84.dp)
                        .clip(CircleShape)
                        .background(accent)
                ) {
                    Icon(imageVector = icon, contentDescription = null,
                        tint = Color.White, modifier = Modifier.size(36.dp))
                }
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Text(text = eyebrow,
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 11.sp,
                            color = accentColor, letterSpacing = 0.6.sp))
                    Text(text = title,
                        style = TextStyle(fontWeight = FontWeight.Black, fontSize = 22.sp,
                            color = TrendXColors.Ink),
                        textAlign = TextAlign.Center)
                    Text(text = body,
                        style = TextStyle(fontWeight = FontWeight.Medium, fontSize = 13.sp,
                            color = TrendXColors.SecondaryInk, lineHeight = 19.sp),
                        textAlign = TextAlign.Center)
                }
            }
        }
    }
}
