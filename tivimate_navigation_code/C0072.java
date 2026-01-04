package androidx.leanback.transition;

/* renamed from: androidx.leanback.transition.ʼˎ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C0072 extends android.animation.AnimatorListenerAdapter implements android.transition.Transition.TransitionListener {

    /* renamed from: ʼˎ, reason: contains not printable characters */
    public final float f562;

    /* renamed from: ʽ, reason: contains not printable characters */
    public final int f563;

    /* renamed from: ˈ, reason: contains not printable characters */
    public final int f564;

    /* renamed from: ˑﹳ, reason: contains not printable characters */
    public int[] f565;

    /* renamed from: ᵎﹶ, reason: contains not printable characters */
    public float f566;

    /* renamed from: ᵔᵢ, reason: contains not printable characters */
    public final float f567;

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public final android.view.View f568;

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final android.view.View f569;

    /* renamed from: ﾞᴵ, reason: contains not printable characters */
    public float f570;

    public C0072(android.view.View view, android.view.View view2, int i, int i2, float f, float f2) {
        this.f568 = view;
        this.f569 = view2;
        this.f563 = i - java.lang.Math.round(view.getTranslationX());
        this.f564 = i2 - java.lang.Math.round(view.getTranslationY());
        this.f567 = f;
        this.f562 = f2;
        int[] iArr = (int[]) view2.getTag(ar.tvplayer.tv.R.id._114_res_0x7f0b03b8);
        this.f565 = iArr;
        if (iArr != null) {
            view2.setTag(ar.tvplayer.tv.R.id._114_res_0x7f0b03b8, null);
        }
    }

    @Override // android.animation.AnimatorListenerAdapter, android.animation.Animator.AnimatorListener
    public final void onAnimationCancel(android.animation.Animator animator) {
        if (this.f565 == null) {
            this.f565 = new int[2];
        }
        int[] iArr = this.f565;
        float f = this.f563;
        android.view.View view = this.f568;
        iArr[0] = java.lang.Math.round(view.getTranslationX() + f);
        this.f565[1] = java.lang.Math.round(view.getTranslationY() + this.f564);
        this.f569.setTag(ar.tvplayer.tv.R.id._114_res_0x7f0b03b8, this.f565);
    }

    @Override // android.animation.AnimatorListenerAdapter, android.animation.Animator.AnimatorListener
    public final void onAnimationEnd(android.animation.Animator animator) {
    }

    @Override // android.animation.AnimatorListenerAdapter, android.animation.Animator.AnimatorPauseListener
    public final void onAnimationPause(android.animation.Animator animator) {
        android.view.View view = this.f568;
        this.f570 = view.getTranslationX();
        this.f566 = view.getTranslationY();
        view.setTranslationX(this.f567);
        view.setTranslationY(this.f562);
    }

    @Override // android.animation.AnimatorListenerAdapter, android.animation.Animator.AnimatorPauseListener
    public final void onAnimationResume(android.animation.Animator animator) {
        float f = this.f570;
        android.view.View view = this.f568;
        view.setTranslationX(f);
        view.setTranslationY(this.f566);
    }

    @Override // android.transition.Transition.TransitionListener
    public final void onTransitionCancel(android.transition.Transition transition) {
    }

    @Override // android.transition.Transition.TransitionListener
    public final void onTransitionEnd(android.transition.Transition transition) {
        float f = this.f567;
        android.view.View view = this.f568;
        view.setTranslationX(f);
        view.setTranslationY(this.f562);
    }

    @Override // android.transition.Transition.TransitionListener
    public final void onTransitionPause(android.transition.Transition transition) {
    }

    @Override // android.transition.Transition.TransitionListener
    public final void onTransitionResume(android.transition.Transition transition) {
    }

    @Override // android.transition.Transition.TransitionListener
    public final void onTransitionStart(android.transition.Transition transition) {
    }
}
