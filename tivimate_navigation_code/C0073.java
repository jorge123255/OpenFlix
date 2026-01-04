package androidx.leanback.transition;

/* renamed from: androidx.leanback.transition.ʽ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C0073 extends com.google.android.gms.internal.measurement.ᵎ {

    /* renamed from: ʽʽ, reason: contains not printable characters */
    public final /* synthetic */ androidx.leanback.transition.FadeAndShortSlide f571;

    public C0073(androidx.leanback.transition.FadeAndShortSlide fadeAndShortSlide) {
        this.f571 = fadeAndShortSlide;
    }

    /* renamed from: ˆʾ, reason: contains not printable characters */
    public final float m446(androidx.leanback.transition.FadeAndShortSlide fadeAndShortSlide, android.view.ViewGroup viewGroup, android.view.View view, int[] iArr) {
        int iCenterY;
        int height = (view.getHeight() / 2) + iArr[1];
        viewGroup.getLocationOnScreen(iArr);
        android.graphics.Rect epicenter = this.f571.getEpicenter();
        if (epicenter == null) {
            iCenterY = (viewGroup.getHeight() / 2) + iArr[1];
        } else {
            iCenterY = epicenter.centerY();
        }
        if (height < iCenterY) {
            return view.getTranslationY() - fadeAndShortSlide.m443(viewGroup);
        }
        return fadeAndShortSlide.m443(viewGroup) + view.getTranslationY();
    }
}
