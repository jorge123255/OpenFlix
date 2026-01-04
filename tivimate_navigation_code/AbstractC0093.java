package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ʾˊ, reason: contains not printable characters */
/* loaded from: classes.dex */
public abstract class AbstractC0093 extends android.widget.EditText {

    /* renamed from: ˊʻ, reason: contains not printable characters */
    public static final java.util.regex.Pattern f862 = java.util.regex.Pattern.compile("\\S+");

    /* renamed from: ٴᵢ, reason: contains not printable characters */
    public static final androidx.leanback.widget.C0097 f863 = new androidx.leanback.widget.C0097(java.lang.Integer.class, "streamPosition", 3);

    /* renamed from: ʽʽ, reason: contains not printable characters */
    public android.graphics.Bitmap f864;

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public final java.util.Random f865;

    /* renamed from: ˈٴ, reason: contains not printable characters */
    public int f866;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public android.graphics.Bitmap f867;

    /* renamed from: ᴵᵔ, reason: contains not printable characters */
    public android.animation.ObjectAnimator f868;

    public AbstractC0093(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet, ar.tvplayer.tv.R.style.m1);
        this.f865 = new java.util.Random();
    }

    public int getStreamPosition() {
        return this.f866;
    }

    @Override // android.view.View
    public final void onFinishInflate() {
        super.onFinishInflate();
        this.f867 = android.graphics.Bitmap.createScaledBitmap(android.graphics.BitmapFactory.decodeResource(getResources(), ar.tvplayer.tv.R.drawable._5f3_res_0x7f0801a8), (int) (r0.getWidth() * 1.3f), (int) (r0.getHeight() * 1.3f), false);
        this.f864 = android.graphics.Bitmap.createScaledBitmap(android.graphics.BitmapFactory.decodeResource(getResources(), ar.tvplayer.tv.R.drawable._4es_res_0x7f0801aa), (int) (r0.getWidth() * 1.3f), (int) (r0.getHeight() * 1.3f), false);
        this.f866 = -1;
        android.animation.ObjectAnimator objectAnimator = this.f868;
        if (objectAnimator != null) {
            objectAnimator.cancel();
        }
        setText("");
    }

    @Override // android.view.View
    public final void onInitializeAccessibilityNodeInfo(android.view.accessibility.AccessibilityNodeInfo accessibilityNodeInfo) {
        super.onInitializeAccessibilityNodeInfo(accessibilityNodeInfo);
        accessibilityNodeInfo.setClassName("androidx.leanback.widget.StreamingTextView");
    }

    @Override // android.widget.TextView
    public void setCustomSelectionActionModeCallback(android.view.ActionMode.Callback callback) {
        super.setCustomSelectionActionModeCallback(ﹳٴ.ﹳٴ.ˉـ(callback, this));
    }

    public void setStreamPosition(int i) {
        this.f866 = i;
        invalidate();
    }
}
