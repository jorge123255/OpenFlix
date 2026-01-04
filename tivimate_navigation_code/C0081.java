package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ʻˋ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final /* synthetic */ class C0081 implements android.animation.ValueAnimator.AnimatorUpdateListener {

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public final /* synthetic */ java.lang.Object f836;

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final /* synthetic */ int f837;

    public /* synthetic */ C0081(int i, java.lang.Object obj) {
        this.f837 = i;
        this.f836 = obj;
    }

    @Override // android.animation.ValueAnimator.AnimatorUpdateListener
    public final void onAnimationUpdate(android.animation.ValueAnimator valueAnimator) {
        int i = this.f837;
        java.lang.Object obj = this.f836;
        switch (i) {
            case 0:
                androidx.leanback.widget.SearchOrbView searchOrbView = (androidx.leanback.widget.SearchOrbView) obj;
                int i2 = androidx.leanback.widget.SearchOrbView.f743;
                searchOrbView.getClass();
                searchOrbView.setOrbViewColor(((java.lang.Integer) valueAnimator.getAnimatedValue()).intValue());
                break;
            case 1:
                androidx.leanback.widget.SearchOrbView searchOrbView2 = (androidx.leanback.widget.SearchOrbView) obj;
                int i3 = androidx.leanback.widget.SearchOrbView.f743;
                searchOrbView2.getClass();
                searchOrbView2.setSearchOrbZ(valueAnimator.getAnimatedFraction());
                break;
            default:
                p044.C1338 c1338 = (p044.C1338) obj;
                c1338.getClass();
                c1338.f5181.setAlpha(((java.lang.Float) valueAnimator.getAnimatedValue()).floatValue());
                break;
        }
    }
}
