package com.openflix.ui.screens

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.openflix.ui.theme.OpenFlixColors
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.*
import kotlin.random.Random

/*
 * Cinematic splash screen — Netflix-caliber intro animation.
 *
 * Timeline:
 *   0.0s  - Black screen, star field fades in
 *   0.3s  - Bright point of light ignites at center
 *   0.6s  - Light point expands into the "O" ring which DRAWS ITSELF
 *   1.2s  - O ring complete, play triangle materializes inside
 *   1.4s  - SHOCKWAVE ripple expands outward from logo
 *   1.5s  - Ember particles burst and drift upward
 *   1.8s  - "OpenFlix" revealed with horizontal light-wipe
 *   2.2s  - Status text fades in
 *   Continuous: star twinkle, ember drift, subtle logo glow pulse
 */
@Composable
fun SplashScreen(
    statusText: String = "Discovering servers...",
    onAnimationComplete: () -> Unit = {}
) {
    // ── Star field ──
    val starsAlpha = remember { Animatable(0f) }

    // ── Center ignition point ──
    val ignitionAlpha = remember { Animatable(0f) }
    val ignitionScale = remember { Animatable(0f) }

    // ── O ring self-draw (0 = nothing, 1 = full circle) ──
    val ringSweep = remember { Animatable(0f) }
    val ringAlpha = remember { Animatable(0f) }
    val ringGlow = remember { Animatable(0f) }

    // ── Play triangle ──
    val triangleAlpha = remember { Animatable(0f) }
    val triangleScale = remember { Animatable(0.3f) }

    // ── Shockwave ──
    val shockwaveProgress = remember { Animatable(0f) }
    val shockwaveAlpha = remember { Animatable(0f) }

    // ── Ember particles ──
    val embersAlpha = remember { Animatable(0f) }

    // ── Text reveal (0 = hidden, 1 = fully revealed) ──
    val textReveal = remember { Animatable(0f) }
    val textGlow = remember { Animatable(0f) }

    // ── Status ──
    val statusAlpha = remember { Animatable(0f) }

    // ── Continuous animations ──
    val infiniteTransition = rememberInfiniteTransition(label = "ambient")

    val starTwinkle by infiniteTransition.animateFloat(
        initialValue = 0f, targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(3000, easing = LinearEasing), RepeatMode.Restart),
        label = "twinkle"
    )

    val glowPulse by infiniteTransition.animateFloat(
        initialValue = 0.5f, targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(2000, easing = EaseInOutSine), RepeatMode.Reverse),
        label = "glow"
    )

    val emberTime by infiniteTransition.animateFloat(
        initialValue = 0f, targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(5000, easing = LinearEasing), RepeatMode.Restart),
        label = "emberTime"
    )

    val ringRotation by infiniteTransition.animateFloat(
        initialValue = 0f, targetValue = 360f,
        animationSpec = infiniteRepeatable(tween(20000, easing = LinearEasing), RepeatMode.Restart),
        label = "ringRot"
    )

    // ── Stable random data ──
    val stars = remember { List(80) { Star(Random.nextFloat(), Random.nextFloat(), 0.5f + Random.nextFloat() * 2f, Random.nextFloat(), 0.3f + Random.nextFloat() * 0.7f) } }
    val embers = remember { List(50) { Ember(Random.nextFloat() * 360f, 0.05f + Random.nextFloat() * 0.4f, 1f + Random.nextFloat() * 3f, 0.3f + Random.nextFloat() * 0.7f, Random.nextFloat(), 0.5f + Random.nextFloat()) } }

    // ── Animation sequence ──
    LaunchedEffect(Unit) {
        // 0.0s — Stars fade in
        launch { starsAlpha.animateTo(1f, tween(800, easing = EaseOutCubic)) }

        delay(300)

        // 0.3s — Ignition: bright point of light at center
        launch { ignitionAlpha.animateTo(1f, tween(200, easing = EaseOutCubic)) }
        launch { ignitionScale.animateTo(1f, tween(400, easing = EaseOutCubic)) }

        delay(300)

        // 0.6s — Ring starts drawing itself + ignition fades
        launch { ignitionAlpha.animateTo(0.2f, tween(600)) }
        launch { ringAlpha.animateTo(1f, tween(200)) }
        launch {
            ringSweep.animateTo(
                360f,
                tween(700, easing = CubicBezierEasing(0.25f, 0.1f, 0.25f, 1f))
            )
        }
        launch { ringGlow.animateTo(1f, tween(500, delayMillis = 200)) }

        delay(650)

        // 1.2s — Play triangle materializes
        launch { triangleAlpha.animateTo(1f, tween(300, easing = EaseOutCubic)) }
        launch {
            triangleScale.animateTo(1f, spring(dampingRatio = 0.6f, stiffness = 300f))
        }

        delay(200)

        // 1.4s — SHOCKWAVE
        launch { shockwaveAlpha.animateTo(0.8f, tween(100)) }
        launch {
            shockwaveProgress.animateTo(1f, tween(800, easing = EaseOutCubic))
        }
        launch {
            delay(200)
            shockwaveAlpha.animateTo(0f, tween(600, easing = EaseInCubic))
        }

        // 1.5s — Embers burst
        delay(100)
        launch { embersAlpha.animateTo(1f, tween(300)) }

        // Ignition fully fades
        launch { ignitionAlpha.animateTo(0f, tween(400)) }

        delay(300)

        // 1.8s — Text light-wipe reveal
        launch { textReveal.animateTo(1f, tween(600, easing = EaseOutCubic)) }
        launch {
            textGlow.animateTo(1f, tween(200))
            delay(300)
            textGlow.animateTo(0f, tween(400))
        }

        delay(400)

        // 2.2s — Status
        statusAlpha.animateTo(1f, tween(400, easing = EaseOutCubic))

        onAnimationComplete()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF060610)),
        contentAlignment = Alignment.Center
    ) {
        // ═══ Layer 1: Star field ═══
        Canvas(modifier = Modifier.fillMaxSize().alpha(starsAlpha.value)) {
            stars.forEach { star ->
                val twinklePhase = (starTwinkle + star.phase) % 1f
                val brightness = star.alpha * (0.3f + 0.7f * sin(twinklePhase * 2 * PI.toFloat()).coerceAtLeast(0f))
                drawCircle(
                    color = Color.White.copy(alpha = brightness),
                    radius = star.size,
                    center = Offset(star.x * size.width, star.y * size.height)
                )
            }
        }

        // ═══ Layer 2: Center ignition ═══
        Canvas(modifier = Modifier.fillMaxSize().alpha(ignitionAlpha.value)) {
            val center = Offset(size.width / 2, size.height / 2)
            val s = ignitionScale.value.coerceAtLeast(0.01f)

            // Core bright point
            val coreRadius = (30f * s).coerceAtLeast(0.1f)
            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(
                        Color.White,
                        Color(0xFFB39DFF),
                        Color(0xFF6138F5).copy(alpha = 0.5f),
                        Color.Transparent
                    ),
                    center = center,
                    radius = coreRadius
                ),
                center = center,
                radius = coreRadius
            )

            // Horizontal lens flare
            drawLine(
                brush = Brush.horizontalGradient(
                    colors = listOf(
                        Color.Transparent,
                        Color(0xFF9B7AFF).copy(alpha = 0.4f * s),
                        Color.White.copy(alpha = 0.6f * s),
                        Color(0xFF9B7AFF).copy(alpha = 0.4f * s),
                        Color.Transparent
                    ),
                    startX = center.x - 200f * s,
                    endX = center.x + 200f * s
                ),
                start = Offset(center.x - 200f * s, center.y),
                end = Offset(center.x + 200f * s, center.y),
                strokeWidth = 2f
            )

            // Vertical lens flare (shorter)
            drawLine(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        Color.Transparent,
                        Color(0xFF9B7AFF).copy(alpha = 0.3f * s),
                        Color.White.copy(alpha = 0.5f * s),
                        Color(0xFF9B7AFF).copy(alpha = 0.3f * s),
                        Color.Transparent
                    ),
                    startY = center.y - 120f * s,
                    endY = center.y + 120f * s
                ),
                start = Offset(center.x, center.y - 120f * s),
                end = Offset(center.x, center.y + 120f * s),
                strokeWidth = 1.5f
            )
        }

        // ═══ Layer 3: Self-drawing O ring + logo ═══
        Canvas(modifier = Modifier.size(180.dp).alpha(ringAlpha.value)) {
            if (size.width < 1f || size.height < 1f) return@Canvas
            val cx = size.width / 2
            val cy = size.height / 2
            val radius = size.width * 0.42f
            val strokeW = size.width * 0.065f
            val sweep = ringSweep.value

            // Ambient glow behind ring
            if (ringGlow.value > 0f) {
                val glowR = (radius * 1.8f).coerceAtLeast(0.1f)
                drawCircle(
                    brush = Brush.radialGradient(
                        colors = listOf(
                            Color(0xFF6138F5).copy(alpha = 0.25f * ringGlow.value * glowPulse),
                            Color(0xFF6138F5).copy(alpha = 0.08f * ringGlow.value),
                            Color.Transparent
                        ),
                        center = Offset(cx, cy),
                        radius = glowR
                    ),
                    center = Offset(cx, cy),
                    radius = glowR
                )
            }

            // The self-drawing ring
            if (sweep > 0f) {
                drawArc(
                    brush = Brush.sweepGradient(
                        colors = listOf(
                            Color(0xFF9B7AFF),
                            Color(0xFF7B5CF7),
                            Color(0xFF6138F5),
                            Color(0xFF7B5CF7),
                            Color(0xFF9B7AFF)
                        ),
                        center = Offset(cx, cy)
                    ),
                    startAngle = -90f,
                    sweepAngle = sweep,
                    useCenter = false,
                    topLeft = Offset(cx - radius, cy - radius),
                    size = Size(radius * 2, radius * 2),
                    style = Stroke(width = strokeW, cap = StrokeCap.Round)
                )

                // Bright tip at the drawing edge
                if (sweep < 355f && strokeW > 0.1f) {
                    val tipAngle = (-90f + sweep) * PI.toFloat() / 180f
                    val tipX = cx + cos(tipAngle) * radius
                    val tipY = cy + sin(tipAngle) * radius
                    val tipR = (strokeW * 2f).coerceAtLeast(0.1f)
                    drawCircle(
                        brush = Brush.radialGradient(
                            colors = listOf(
                                Color.White.copy(alpha = 0.9f),
                                Color(0xFFB39DFF).copy(alpha = 0.5f),
                                Color.Transparent
                            ),
                            center = Offset(tipX, tipY),
                            radius = tipR
                        ),
                        center = Offset(tipX, tipY),
                        radius = tipR
                    )
                }
            }

            // Inner glow fill (fades in as ring completes)
            val fillAlpha = (sweep / 360f).coerceIn(0f, 1f) * 0.15f
            val fillR = (radius * 0.85f).coerceAtLeast(0.1f)
            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(
                        Color(0xFF6138F5).copy(alpha = fillAlpha),
                        Color.Transparent
                    ),
                    center = Offset(cx, cy),
                    radius = fillR
                ),
                center = Offset(cx, cy),
                radius = fillR
            )

            // Play triangle
            if (triangleAlpha.value > 0f) {
                val triScale = triangleScale.value
                val triSize = size.width * 0.18f * triScale
                val triLeft = cx - triSize * 0.3f
                val path = Path().apply {
                    moveTo(triLeft, cy - triSize)
                    lineTo(triLeft + triSize * 1.3f, cy)
                    lineTo(triLeft, cy + triSize)
                    close()
                }
                drawPath(
                    path = path,
                    brush = Brush.linearGradient(
                        colors = listOf(
                            Color(0xFFB39DFF).copy(alpha = triangleAlpha.value),
                            Color(0xFF7B5CF7).copy(alpha = triangleAlpha.value)
                        )
                    )
                )
            }

            // Subtle rotating accent arcs (after ring is complete)
            if (ringGlow.value > 0.5f) {
                val accentAlpha = (ringGlow.value - 0.5f) * 2f * glowPulse * 0.4f
                rotate(ringRotation, pivot = Offset(cx, cy)) {
                    drawArc(
                        color = Color(0xFF9B7AFF).copy(alpha = accentAlpha),
                        startAngle = 0f,
                        sweepAngle = 60f,
                        useCenter = false,
                        topLeft = Offset(cx - radius - 8f, cy - radius - 8f),
                        size = Size((radius + 8f) * 2, (radius + 8f) * 2),
                        style = Stroke(width = 1.5f, cap = StrokeCap.Round)
                    )
                    drawArc(
                        color = Color(0xFF6138F5).copy(alpha = accentAlpha * 0.6f),
                        startAngle = 180f,
                        sweepAngle = 40f,
                        useCenter = false,
                        topLeft = Offset(cx - radius - 14f, cy - radius - 14f),
                        size = Size((radius + 14f) * 2, (radius + 14f) * 2),
                        style = Stroke(width = 1f, cap = StrokeCap.Round)
                    )
                }
            }
        }

        // ═══ Layer 4: Shockwave ═══
        Canvas(modifier = Modifier.fillMaxSize().alpha(shockwaveAlpha.value)) {
            val center = Offset(size.width / 2, size.height / 2)
            val maxRadius = size.minDimension * 0.6f
            val progress = shockwaveProgress.value
            val currentRadius = (maxRadius * progress).coerceAtLeast(0.1f)

            // Shockwave ring
            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(
                        Color.Transparent,
                        Color(0xFF9B7AFF).copy(alpha = 0.3f * (1f - progress)),
                        Color(0xFF6138F5).copy(alpha = 0.15f * (1f - progress)),
                        Color.Transparent
                    ),
                    center = center,
                    radius = currentRadius
                ),
                center = center,
                radius = currentRadius,
                style = Stroke(width = 4f * (1f - progress * 0.5f))
            )

            // Second shockwave (delayed, thinner)
            val progress2 = (progress - 0.15f).coerceAtLeast(0f) / 0.85f
            if (progress2 > 0f) {
                val r2 = (maxRadius * 0.8f * progress2).coerceAtLeast(0.1f)
                drawCircle(
                    color = Color(0xFF7B5CF7).copy(alpha = 0.15f * (1f - progress2)),
                    center = center,
                    radius = r2,
                    style = Stroke(width = 2f)
                )
            }
        }

        // ═══ Layer 5: Ember particles ═══
        Canvas(modifier = Modifier.fillMaxSize().alpha(embersAlpha.value)) {
            val center = Offset(size.width / 2, size.height / 2)
            val maxDist = size.minDimension * 0.4f

            embers.forEach { ember ->
                val time = (emberTime + ember.phase) % 1f
                val angle = ember.angle * PI.toFloat() / 180f
                val baseDist = ember.distance * maxDist

                // Embers drift outward and upward over time
                val driftX = cos(angle) * baseDist + sin(time * PI.toFloat() * 2f) * 15f
                val driftY = sin(angle) * baseDist - time * 80f * ember.speed // drift upward

                val px = center.x + driftX
                val py = center.y + driftY

                // Fade out as they drift
                val life = 1f - time
                val fadeAlpha = ember.alpha * life * life

                if (fadeAlpha > 0.02f) {
                    // Ember core
                    drawCircle(
                        color = Color(0xFFB39DFF).copy(alpha = fadeAlpha),
                        radius = ember.size * life,
                        center = Offset(px, py)
                    )
                    // Ember glow
                    drawCircle(
                        color = Color(0xFF6138F5).copy(alpha = fadeAlpha * 0.3f),
                        radius = ember.size * life * 3f,
                        center = Offset(px, py)
                    )
                }
            }
        }

        // ═══ Text layers ═══
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.align(Alignment.Center).padding(top = 240.dp)
        ) {
            // "OpenFlix" with light-wipe reveal
            Box {
                // Main text (clipped by reveal progress)
                Text(
                    text = "OpenFlix",
                    fontSize = 38.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 3.sp,
                    color = OpenFlixColors.TextPrimary,
                    modifier = Modifier
                        .alpha(textReveal.value)
                )

                // Light wipe glow overlay (travels across text)
                if (textGlow.value > 0f) {
                    Canvas(modifier = Modifier.matchParentSize()) {
                        val wipeX = textReveal.value * size.width * 1.5f - size.width * 0.25f
                        drawRect(
                            brush = Brush.horizontalGradient(
                                colors = listOf(
                                    Color.Transparent,
                                    Color(0xFF9B7AFF).copy(alpha = 0.3f * textGlow.value),
                                    Color.White.copy(alpha = 0.2f * textGlow.value),
                                    Color(0xFF9B7AFF).copy(alpha = 0.3f * textGlow.value),
                                    Color.Transparent
                                ),
                                startX = wipeX - 60f,
                                endX = wipeX + 60f
                            ),
                            size = size
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(48.dp))

            // Status text
            Text(
                text = statusText,
                fontSize = 14.sp,
                color = OpenFlixColors.TextTertiary,
                modifier = Modifier.alpha(statusAlpha.value)
            )
        }
    }
}

// ── Data classes ──

private data class Star(
    val x: Float, val y: Float, val size: Float, val phase: Float, val alpha: Float
)

private data class Ember(
    val angle: Float, val distance: Float, val size: Float, val alpha: Float,
    val phase: Float, val speed: Float
)

// ── Easing curves ──
private val EaseInOutSine = CubicBezierEasing(0.37f, 0f, 0.63f, 1f)
private val EaseInOutCubic = CubicBezierEasing(0.645f, 0.045f, 0.355f, 1.0f)
private val EaseOutCubic = CubicBezierEasing(0.215f, 0.61f, 0.355f, 1.0f)
private val EaseInCubic = CubicBezierEasing(0.55f, 0.055f, 0.675f, 0.19f)
