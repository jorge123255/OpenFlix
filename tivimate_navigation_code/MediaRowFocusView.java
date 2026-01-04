package androidx.leanback.widget;

/* loaded from: classes.dex */
class MediaRowFocusView extends android.view.View {

    /* renamed from: ʽʽ, reason: contains not printable characters */
    public int f671;

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public final android.graphics.Paint f672;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public final android.graphics.RectF f673;

    public MediaRowFocusView(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet);
        this.f673 = new android.graphics.RectF();
        android.graphics.Paint paint = new android.graphics.Paint();
        paint.setColor(context.getResources().getColor(ar.tvplayer.tv.R.color._2rd_res_0x7f0600e7));
        this.f672 = paint;
    }

    @Override // android.view.View
    public final void onDraw(android.graphics.Canvas canvas) {
        super.onDraw(canvas);
        int height = getHeight() / 2;
        this.f671 = height;
        int height2 = ((height * 2) - getHeight()) / 2;
        float f = -height2;
        float width = getWidth();
        float height3 = getHeight() + height2;
        android.graphics.RectF rectF = this.f673;
        rectF.set(0.0f, f, width, height3);
        int i = this.f671;
        canvas.drawRoundRect(rectF, i, i, this.f672);
    }
}
