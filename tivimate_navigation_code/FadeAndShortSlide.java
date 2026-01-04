package androidx.leanback.transition;

/* loaded from: classes.dex */
public class FadeAndShortSlide extends android.transition.Visibility {

    /* renamed from: ʽʽ, reason: contains not printable characters */
    public float f549;

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public com.google.android.gms.internal.measurement.ᵎ f550;

    /* renamed from: ˈٴ, reason: contains not printable characters */
    public final androidx.leanback.transition.C0073 f551;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public android.transition.Visibility f552;

    /* renamed from: ᴵᵔ, reason: contains not printable characters */
    public static final android.view.animation.DecelerateInterpolator f547 = new android.view.animation.DecelerateInterpolator();

    /* renamed from: ˊʻ, reason: contains not printable characters */
    public static final androidx.leanback.transition.C0078 f544 = new androidx.leanback.transition.C0078(0);

    /* renamed from: ٴᵢ, reason: contains not printable characters */
    public static final androidx.leanback.transition.C0078 f546 = new androidx.leanback.transition.C0078(1);

    /* renamed from: ˉٴ, reason: contains not printable characters */
    public static final androidx.leanback.transition.C0078 f543 = new androidx.leanback.transition.C0078(2);

    /* renamed from: ᵎⁱ, reason: contains not printable characters */
    public static final androidx.leanback.transition.C0078 f548 = new androidx.leanback.transition.C0078(3);

    /* renamed from: ٴʼ, reason: contains not printable characters */
    public static final androidx.leanback.transition.C0078 f545 = new androidx.leanback.transition.C0078(4);

    public FadeAndShortSlide(int i) {
        this.f552 = new android.transition.Fade();
        this.f549 = -1.0f;
        this.f551 = new androidx.leanback.transition.C0073(this);
        m442(i);
    }

    public FadeAndShortSlide(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet);
        this.f552 = new android.transition.Fade();
        this.f549 = -1.0f;
        this.f551 = new androidx.leanback.transition.C0073(this);
        android.content.res.TypedArray typedArrayObtainStyledAttributes = context.obtainStyledAttributes(attributeSet, p272.AbstractC3483.f13669);
        m442(typedArrayObtainStyledAttributes.getInt(3, 8388611));
        typedArrayObtainStyledAttributes.recycle();
    }

    @Override // android.transition.Transition
    public final android.transition.Transition addListener(android.transition.Transition.TransitionListener transitionListener) {
        this.f552.addListener(transitionListener);
        return super.addListener(transitionListener);
    }

    @Override // android.transition.Visibility, android.transition.Transition
    public final void captureEndValues(android.transition.TransitionValues transitionValues) {
        this.f552.captureEndValues(transitionValues);
        super.captureEndValues(transitionValues);
        int[] iArr = new int[2];
        transitionValues.view.getLocationOnScreen(iArr);
        transitionValues.values.put("android:fadeAndShortSlideTransition:screenPosition", iArr);
    }

    @Override // android.transition.Visibility, android.transition.Transition
    public final void captureStartValues(android.transition.TransitionValues transitionValues) {
        this.f552.captureStartValues(transitionValues);
        super.captureStartValues(transitionValues);
        int[] iArr = new int[2];
        transitionValues.view.getLocationOnScreen(iArr);
        transitionValues.values.put("android:fadeAndShortSlideTransition:screenPosition", iArr);
    }

    @Override // android.transition.Transition
    public final android.transition.Transition clone() {
        androidx.leanback.transition.FadeAndShortSlide fadeAndShortSlide = (androidx.leanback.transition.FadeAndShortSlide) super.clone();
        fadeAndShortSlide.f552 = (android.transition.Visibility) this.f552.clone();
        return fadeAndShortSlide;
    }

    @Override // android.transition.Visibility
    public final android.animation.Animator onAppear(android.view.ViewGroup viewGroup, android.view.View view, android.transition.TransitionValues transitionValues, android.transition.TransitionValues transitionValues2) {
        if (transitionValues2 == null || viewGroup == view) {
            return null;
        }
        int[] iArr = (int[]) transitionValues2.values.get("android:fadeAndShortSlideTransition:screenPosition");
        int i = iArr[0];
        int i2 = iArr[1];
        float translationX = view.getTranslationX();
        android.animation.ObjectAnimator objectAnimator = ʽٴ.ˈ.ﾞᴵ(view, transitionValues2, i, i2, this.f550.ʼˎ(this, viewGroup, view, iArr), this.f550.ˆʾ(this, viewGroup, view, iArr), translationX, view.getTranslationY(), f547, this);
        android.animation.Animator animatorOnAppear = this.f552.onAppear(viewGroup, view, transitionValues, transitionValues2);
        if (objectAnimator == null) {
            return animatorOnAppear;
        }
        if (animatorOnAppear == null) {
            return objectAnimator;
        }
        android.animation.AnimatorSet animatorSet = new android.animation.AnimatorSet();
        animatorSet.play(objectAnimator).with(animatorOnAppear);
        return animatorSet;
    }

    @Override // android.transition.Visibility
    public final android.animation.Animator onDisappear(android.view.ViewGroup viewGroup, android.view.View view, android.transition.TransitionValues transitionValues, android.transition.TransitionValues transitionValues2) {
        if (transitionValues == null || viewGroup == view) {
            return null;
        }
        int[] iArr = (int[]) transitionValues.values.get("android:fadeAndShortSlideTransition:screenPosition");
        android.animation.ObjectAnimator objectAnimator = ʽٴ.ˈ.ﾞᴵ(view, transitionValues, iArr[0], iArr[1], view.getTranslationX(), view.getTranslationY(), this.f550.ʼˎ(this, viewGroup, view, iArr), this.f550.ˆʾ(this, viewGroup, view, iArr), f547, this);
        android.animation.Animator animatorOnDisappear = this.f552.onDisappear(viewGroup, view, transitionValues, transitionValues2);
        if (objectAnimator == null) {
            return animatorOnDisappear;
        }
        if (animatorOnDisappear == null) {
            return objectAnimator;
        }
        android.animation.AnimatorSet animatorSet = new android.animation.AnimatorSet();
        animatorSet.play(objectAnimator).with(animatorOnDisappear);
        return animatorSet;
    }

    @Override // android.transition.Transition
    public final android.transition.Transition removeListener(android.transition.Transition.TransitionListener transitionListener) {
        this.f552.removeListener(transitionListener);
        return super.removeListener(transitionListener);
    }

    @Override // android.transition.Transition
    public final void setEpicenterCallback(android.transition.Transition.EpicenterCallback epicenterCallback) {
        this.f552.setEpicenterCallback(epicenterCallback);
        super.setEpicenterCallback(epicenterCallback);
    }

    /* renamed from: ˈ, reason: contains not printable characters */
    public final void m442(int i) {
        if (i == 48) {
            this.f550 = f545;
            return;
        }
        if (i == 80) {
            this.f550 = f548;
            return;
        }
        if (i == 112) {
            this.f550 = this.f551;
            return;
        }
        if (i == 8388611) {
            this.f550 = f544;
        } else if (i == 8388613) {
            this.f550 = f546;
        } else {
            if (i != 8388615) {
                throw new java.lang.IllegalArgumentException("Invalid slide direction");
            }
            this.f550 = f543;
        }
    }

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public final float m443(android.view.ViewGroup viewGroup) {
        float f = this.f549;
        return f >= 0.0f ? f : viewGroup.getHeight() / 4;
    }

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final float m444(android.view.ViewGroup viewGroup) {
        float f = this.f549;
        return f >= 0.0f ? f : viewGroup.getWidth() / 4;
    }
}
