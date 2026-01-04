package androidx.leanback.widget;

@android.annotation.SuppressLint({"AppCompatCustomView"})
/* loaded from: classes.dex */
class CheckableImageView extends android.widget.ImageView implements android.widget.Checkable {

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public static final int[] f590 = {android.R.attr.state_checked};

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public boolean f591;

    public CheckableImageView(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet, 0);
    }

    @Override // android.widget.Checkable
    public final boolean isChecked() {
        return this.f591;
    }

    @Override // android.widget.ImageView, android.view.View
    public final int[] onCreateDrawableState(int i) {
        int[] iArrOnCreateDrawableState = super.onCreateDrawableState(i + 1);
        if (this.f591) {
            android.view.View.mergeDrawableStates(iArrOnCreateDrawableState, f590);
        }
        return iArrOnCreateDrawableState;
    }

    @Override // android.widget.Checkable
    public final void setChecked(boolean z) {
        if (this.f591 != z) {
            this.f591 = z;
            refreshDrawableState();
        }
    }

    @Override // android.widget.Checkable
    public final void toggle() {
        setChecked(!this.f591);
    }
}
