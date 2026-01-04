package androidx.leanback.transition;

/* renamed from: androidx.leanback.transition.ᵎﹶ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C0076 extends android.animation.AnimatorListenerAdapter {

    /* renamed from: ʽ, reason: contains not printable characters */
    public final android.view.View f574;

    /* renamed from: ˈ, reason: contains not printable characters */
    public final float f575;

    /* renamed from: ˑﹳ, reason: contains not printable characters */
    public final float f576;

    /* renamed from: ᵎﹶ, reason: contains not printable characters */
    public final android.util.Property f577;

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public float f578;

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public boolean f579 = false;

    /* renamed from: ﾞᴵ, reason: contains not printable characters */
    public final int f580;

    public C0076(android.view.View view, android.util.Property property, float f, float f2, int i) {
        this.f577 = property;
        this.f574 = view;
        this.f576 = f;
        this.f575 = f2;
        this.f580 = i;
        view.setVisibility(0);
    }

    @Override // android.animation.AnimatorListenerAdapter, android.animation.Animator.AnimatorListener
    public final void onAnimationCancel(android.animation.Animator animator) {
        android.view.View view = this.f574;
        view.setTag(ar.tvplayer.tv.R.id._12o_res_0x7f0b024f, new float[]{view.getTranslationX(), view.getTranslationY()});
        this.f577.set(view, java.lang.Float.valueOf(this.f576));
        this.f579 = true;
    }

    @Override // android.animation.AnimatorListenerAdapter, android.animation.Animator.AnimatorListener
    public final void onAnimationEnd(android.animation.Animator animator) {
        boolean z = this.f579;
        android.view.View view = this.f574;
        if (!z) {
            this.f577.set(view, java.lang.Float.valueOf(this.f576));
        }
        view.setVisibility(this.f580);
    }

    @Override // android.animation.AnimatorListenerAdapter, android.animation.Animator.AnimatorPauseListener
    public final void onAnimationPause(android.animation.Animator animator) {
        android.util.Property property = this.f577;
        android.view.View view = this.f574;
        this.f578 = ((java.lang.Float) property.get(view)).floatValue();
        property.set(view, java.lang.Float.valueOf(this.f575));
        view.setVisibility(this.f580);
    }

    @Override // android.animation.AnimatorListenerAdapter, android.animation.Animator.AnimatorPauseListener
    public final void onAnimationResume(android.animation.Animator animator) {
        java.lang.Float fValueOf = java.lang.Float.valueOf(this.f578);
        android.util.Property property = this.f577;
        android.view.View view = this.f574;
        property.set(view, fValueOf);
        view.setVisibility(0);
    }
}
