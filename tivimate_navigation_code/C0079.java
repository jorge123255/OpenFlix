package androidx.leanback.transition;

/* renamed from: androidx.leanback.transition.ﹳٴ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C0079 extends android.transition.ChangeBounds {

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public final java.util.HashMap f585 = new java.util.HashMap();

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public final android.util.SparseIntArray f586 = new android.util.SparseIntArray();

    /* renamed from: ʽʽ, reason: contains not printable characters */
    public final java.util.HashMap f584 = new java.util.HashMap();

    @Override // android.transition.ChangeBounds, android.transition.Transition
    public final android.animation.Animator createAnimator(android.view.ViewGroup viewGroup, android.transition.TransitionValues transitionValues, android.transition.TransitionValues transitionValues2) {
        android.view.View view;
        int iIntValue;
        android.animation.Animator animatorCreateAnimator = super.createAnimator(viewGroup, transitionValues, transitionValues2);
        if (animatorCreateAnimator != null && transitionValues2 != null && (view = transitionValues2.view) != null) {
            java.lang.Integer num = (java.lang.Integer) this.f585.get(view);
            if (num != null) {
                iIntValue = num.intValue();
            } else {
                int i = this.f586.get(view.getId(), -1);
                if (i != -1) {
                    iIntValue = i;
                } else {
                    java.lang.Integer num2 = (java.lang.Integer) this.f584.get(view.getClass().getName());
                    iIntValue = num2 != null ? num2.intValue() : 0;
                }
            }
            animatorCreateAnimator.setStartDelay(iIntValue);
        }
        return animatorCreateAnimator;
    }
}
