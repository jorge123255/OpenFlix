package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ᵔٴ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C0144 extends android.animation.AnimatorListenerAdapter {

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public final /* synthetic */ java.lang.Object f999;

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final /* synthetic */ int f1000;

    public /* synthetic */ C0144(int i, java.lang.Object obj) {
        this.f1000 = i;
        this.f999 = obj;
    }

    @Override // android.animation.AnimatorListenerAdapter, android.animation.Animator.AnimatorListener
    public void onAnimationCancel(android.animation.Animator animator) {
        switch (this.f1000) {
            case 5:
                androidx.appcompat.widget.ActionBarOverlayLayout actionBarOverlayLayout = (androidx.appcompat.widget.ActionBarOverlayLayout) this.f999;
                actionBarOverlayLayout.f122 = null;
                actionBarOverlayLayout.f118 = false;
                break;
            case p223.C3056.STRING_SET_FIELD_NUMBER /* 6 */:
            default:
                super.onAnimationCancel(animator);
                break;
            case p223.C3056.DOUBLE_FIELD_NUMBER /* 7 */:
                ((androidx.media3.ui.AspectRatioFrameLayout) this.f999).f1257 = null;
                break;
        }
    }

    @Override // android.animation.AnimatorListenerAdapter, android.animation.Animator.AnimatorListener
    public final void onAnimationEnd(android.animation.Animator animator) {
        switch (this.f1000) {
            case 0:
                ((androidx.leanback.widget.C0101) this.f999).f893 = null;
                break;
            case 1:
                p005.C0833 c0833 = (p005.C0833) this.f999;
                java.util.ArrayList arrayList = new java.util.ArrayList(c0833.f3571);
                int size = arrayList.size();
                for (int i = 0; i < size; i++) {
                    android.content.res.ColorStateList colorStateList = ((p381.C4549) arrayList.get(i)).f17058.f17039;
                    if (colorStateList != null) {
                        c0833.setTintList(colorStateList);
                    }
                }
                break;
            case 2:
                p044.C1338 c1338 = (p044.C1338) this.f999;
                c1338.m4011();
                c1338.f5173.start();
                break;
            case 3:
                ((com.google.android.material.behavior.HideBottomViewOnScrollBehavior) this.f999).f2541 = null;
                break;
            case 4:
                ((com.google.android.material.behavior.HideViewOnScrollBehavior) this.f999).f2552 = null;
                break;
            case 5:
                androidx.appcompat.widget.ActionBarOverlayLayout actionBarOverlayLayout = (androidx.appcompat.widget.ActionBarOverlayLayout) this.f999;
                actionBarOverlayLayout.f122 = null;
                actionBarOverlayLayout.f118 = false;
                break;
            case p223.C3056.STRING_SET_FIELD_NUMBER /* 6 */:
                ((p230.AbstractC3143) this.f999).m6899();
                animator.removeListener(this);
                break;
            default:
                ((androidx.media3.ui.AspectRatioFrameLayout) this.f999).f1257 = null;
                break;
        }
    }

    @Override // android.animation.AnimatorListenerAdapter, android.animation.Animator.AnimatorListener
    public void onAnimationStart(android.animation.Animator animator) {
        switch (this.f1000) {
            case 1:
                p005.C0833 c0833 = (p005.C0833) this.f999;
                java.util.ArrayList arrayList = new java.util.ArrayList(c0833.f3571);
                int size = arrayList.size();
                for (int i = 0; i < size; i++) {
                    p381.C4547 c4547 = ((p381.C4549) arrayList.get(i)).f17058;
                    android.content.res.ColorStateList colorStateList = c4547.f17039;
                    if (colorStateList != null) {
                        c0833.setTint(colorStateList.getColorForState(c4547.f17037, colorStateList.getDefaultColor()));
                    }
                }
                break;
            default:
                super.onAnimationStart(animator);
                break;
        }
    }
}
