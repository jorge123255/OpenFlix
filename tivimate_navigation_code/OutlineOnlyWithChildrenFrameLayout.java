package androidx.leanback.preference.internal;

/* loaded from: classes.dex */
public class OutlineOnlyWithChildrenFrameLayout extends android.widget.FrameLayout {

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public p110.C1948 f541;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public android.view.ViewOutlineProvider f542;

    public OutlineOnlyWithChildrenFrameLayout(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet);
    }

    @Override // android.widget.FrameLayout, android.view.ViewGroup, android.view.View
    public final void onLayout(boolean z, int i, int i2, int i3, int i4) {
        super.onLayout(z, i, i2, i3, i4);
        invalidateOutline();
    }

    @Override // android.view.View
    public void setOutlineProvider(android.view.ViewOutlineProvider viewOutlineProvider) {
        this.f542 = viewOutlineProvider;
        if (this.f541 == null) {
            this.f541 = new p110.C1948(this, 1);
        }
        super.setOutlineProvider(this.f541);
    }
}
