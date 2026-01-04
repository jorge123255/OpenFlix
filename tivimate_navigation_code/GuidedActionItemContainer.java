package androidx.leanback.widget;

/* loaded from: classes.dex */
class GuidedActionItemContainer extends androidx.leanback.widget.AbstractC0104 {

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public boolean f649;

    public GuidedActionItemContainer(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet, 0);
        new android.graphics.Rect();
        if (context.getApplicationInfo().targetSdkVersion < 23) {
            android.content.res.TypedArray typedArrayObtainStyledAttributes = context.obtainStyledAttributes(attributeSet, new int[]{android.R.attr.foreground});
            android.graphics.drawable.Drawable drawable = typedArrayObtainStyledAttributes.getDrawable(0);
            if (drawable != null) {
                setForeground(drawable);
            }
            typedArrayObtainStyledAttributes.recycle();
        }
        this.f649 = true;
    }

    @Override // android.view.ViewGroup, android.view.ViewParent
    public final android.view.View focusSearch(android.view.View view, int i) {
        if (this.f649 || !ˈˆ.ﾞᴵ.ˈٴ(this, view)) {
            return super.focusSearch(view, i);
        }
        android.view.View viewFocusSearch = super.focusSearch(view, i);
        if (ˈˆ.ﾞᴵ.ˈٴ(this, viewFocusSearch)) {
            return viewFocusSearch;
        }
        return null;
    }
}
