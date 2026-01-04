package androidx.leanback.transition;

/* loaded from: classes.dex */
public class ParallaxTransition extends android.transition.Visibility {
    static {
        new android.view.animation.LinearInterpolator();
    }

    public ParallaxTransition(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet);
    }

    @Override // android.transition.Visibility
    public final android.animation.Animator onAppear(android.view.ViewGroup viewGroup, android.view.View view, android.transition.TransitionValues transitionValues, android.transition.TransitionValues transitionValues2) {
        if (transitionValues2 == null || view.getTag(ar.tvplayer.tv.R.id._5fc_res_0x7f0b0243) == null) {
            return null;
        }
        throw new java.lang.ClassCastException();
    }

    @Override // android.transition.Visibility
    public final android.animation.Animator onDisappear(android.view.ViewGroup viewGroup, android.view.View view, android.transition.TransitionValues transitionValues, android.transition.TransitionValues transitionValues2) {
        if (transitionValues == null || view.getTag(ar.tvplayer.tv.R.id._5fc_res_0x7f0b0243) == null) {
            return null;
        }
        throw new java.lang.ClassCastException();
    }
}
