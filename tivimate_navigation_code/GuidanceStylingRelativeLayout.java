package androidx.leanback.widget;

/* loaded from: classes.dex */
class GuidanceStylingRelativeLayout extends android.widget.RelativeLayout {

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public final float f640;

    public GuidanceStylingRelativeLayout(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet, 0);
        this.f640 = m539(context);
    }

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public static float m539(android.content.Context context) {
        android.content.res.TypedArray typedArrayObtainStyledAttributes = context.getTheme().obtainStyledAttributes(p272.AbstractC3483.f13671);
        float f = typedArrayObtainStyledAttributes.getFloat(46, 40.0f);
        typedArrayObtainStyledAttributes.recycle();
        return f;
    }

    @Override // android.widget.RelativeLayout, android.view.ViewGroup, android.view.View
    public final void onLayout(boolean z, int i, int i2, int i3, int i4) {
        super.onLayout(z, i, i2, i3, i4);
        android.view.View viewFindViewById = getRootView().findViewById(ar.tvplayer.tv.R.id._1qa_res_0x7f0b01bb);
        android.view.View viewFindViewById2 = getRootView().findViewById(ar.tvplayer.tv.R.id._74g_res_0x7f0b01b7);
        android.view.View viewFindViewById3 = getRootView().findViewById(ar.tvplayer.tv.R.id._72j_res_0x7f0b01b9);
        android.widget.ImageView imageView = (android.widget.ImageView) getRootView().findViewById(ar.tvplayer.tv.R.id._1kv_res_0x7f0b01ba);
        int measuredHeight = (int) ((getMeasuredHeight() * this.f640) / 100.0f);
        if (viewFindViewById != null && viewFindViewById.getParent() == this) {
            int baseline = (((measuredHeight - viewFindViewById.getBaseline()) - viewFindViewById2.getMeasuredHeight()) - viewFindViewById.getPaddingTop()) - viewFindViewById2.getTop();
            if (viewFindViewById2.getParent() == this) {
                viewFindViewById2.offsetTopAndBottom(baseline);
            }
            viewFindViewById.offsetTopAndBottom(baseline);
            if (viewFindViewById3 != null && viewFindViewById3.getParent() == this) {
                viewFindViewById3.offsetTopAndBottom(baseline);
            }
        }
        if (imageView == null || imageView.getParent() != this || imageView.getDrawable() == null) {
            return;
        }
        imageView.offsetTopAndBottom(measuredHeight - (imageView.getMeasuredHeight() / 2));
    }
}
