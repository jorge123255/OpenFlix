package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.י, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C0119 extends android.text.style.ReplacementSpan {

    /* renamed from: ʽʽ, reason: contains not printable characters */
    public final /* synthetic */ androidx.leanback.widget.AbstractC0093 f949;

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public final int f950;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public final int f951;

    public C0119(androidx.leanback.widget.AbstractC0093 abstractC0093, int i, int i2) {
        this.f949 = abstractC0093;
        this.f950 = i;
        this.f951 = i2;
    }

    @Override // android.text.style.ReplacementSpan
    public final void draw(android.graphics.Canvas canvas, java.lang.CharSequence charSequence, int i, int i2, float f, int i3, int i4, int i5, android.graphics.Paint paint) {
        int iMeasureText = (int) paint.measureText(charSequence, i, i2);
        androidx.leanback.widget.AbstractC0093 abstractC0093 = this.f949;
        int width = abstractC0093.f867.getWidth();
        int i6 = width * 2;
        int i7 = iMeasureText / i6;
        int i8 = (iMeasureText % i6) / 2;
        boolean z = 1 == abstractC0093.getLayoutDirection();
        abstractC0093.f865.setSeed(this.f950);
        int alpha = paint.getAlpha();
        for (int i9 = 0; i9 < i7 && this.f951 + i9 < abstractC0093.f866; i9++) {
            float f2 = (width / 2) + (i9 * i6) + i8;
            float f3 = z ? ((f + iMeasureText) - f2) - width : f + f2;
            paint.setAlpha((abstractC0093.f865.nextInt(4) + 1) * 63);
            if (abstractC0093.f865.nextBoolean()) {
                canvas.drawBitmap(abstractC0093.f864, f3, i4 - r13.getHeight(), paint);
            } else {
                canvas.drawBitmap(abstractC0093.f867, f3, i4 - r13.getHeight(), paint);
            }
        }
        paint.setAlpha(alpha);
    }

    @Override // android.text.style.ReplacementSpan
    public final int getSize(android.graphics.Paint paint, java.lang.CharSequence charSequence, int i, int i2, android.graphics.Paint.FontMetricsInt fontMetricsInt) {
        return (int) paint.measureText(charSequence, i, i2);
    }
}
