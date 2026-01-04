package androidx.leanback.transition;

/* loaded from: classes.dex */
class SlideKitkat extends android.transition.Visibility {

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public final androidx.leanback.transition.InterfaceC0080 f561;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public static final android.view.animation.DecelerateInterpolator f558 = new android.view.animation.DecelerateInterpolator();

    /* renamed from: ʽʽ, reason: contains not printable characters */
    public static final android.view.animation.AccelerateInterpolator f553 = new android.view.animation.AccelerateInterpolator();

    /* renamed from: ˈٴ, reason: contains not printable characters */
    public static final androidx.leanback.transition.C0074 f554 = new androidx.leanback.transition.C0074(0);

    /* renamed from: ᴵᵔ, reason: contains not printable characters */
    public static final androidx.leanback.transition.C0075 f559 = new androidx.leanback.transition.C0075(0);

    /* renamed from: ˊʻ, reason: contains not printable characters */
    public static final androidx.leanback.transition.C0074 f556 = new androidx.leanback.transition.C0074(1);

    /* renamed from: ٴᵢ, reason: contains not printable characters */
    public static final androidx.leanback.transition.C0075 f557 = new androidx.leanback.transition.C0075(1);

    /* renamed from: ˉٴ, reason: contains not printable characters */
    public static final androidx.leanback.transition.C0074 f555 = new androidx.leanback.transition.C0074(2);

    /* renamed from: ᵎⁱ, reason: contains not printable characters */
    public static final androidx.leanback.transition.C0074 f560 = new androidx.leanback.transition.C0074(3);

    public SlideKitkat(android.content.Context context, android.util.AttributeSet attributeSet) {
        android.content.res.TypedArray typedArrayObtainStyledAttributes = context.obtainStyledAttributes(attributeSet, p272.AbstractC3483.f13669);
        int i = typedArrayObtainStyledAttributes.getInt(3, 80);
        if (i == 3) {
            this.f561 = f554;
        } else if (i == 5) {
            this.f561 = f556;
        } else if (i == 48) {
            this.f561 = f559;
        } else if (i == 80) {
            this.f561 = f557;
        } else if (i == 8388611) {
            this.f561 = f555;
        } else {
            if (i != 8388613) {
                throw new java.lang.IllegalArgumentException("Invalid slide direction");
            }
            this.f561 = f560;
        }
        long j = typedArrayObtainStyledAttributes.getInt(1, -1);
        if (j >= 0) {
            setDuration(j);
        }
        long j2 = typedArrayObtainStyledAttributes.getInt(2, -1);
        if (j2 > 0) {
            setStartDelay(j2);
        }
        int resourceId = typedArrayObtainStyledAttributes.getResourceId(0, 0);
        if (resourceId > 0) {
            setInterpolator(android.view.animation.AnimationUtils.loadInterpolator(context, resourceId));
        }
        typedArrayObtainStyledAttributes.recycle();
    }

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public static android.animation.ObjectAnimator m445(android.view.View view, android.util.Property property, float f, float f2, float f3, android.animation.TimeInterpolator timeInterpolator, int i) {
        float[] fArr = (float[]) view.getTag(ar.tvplayer.tv.R.id._12o_res_0x7f0b024f);
        if (fArr != null) {
            f = android.view.View.TRANSLATION_Y == property ? fArr[1] : fArr[0];
            view.setTag(ar.tvplayer.tv.R.id._12o_res_0x7f0b024f, null);
        }
        android.animation.ObjectAnimator objectAnimatorOfFloat = android.animation.ObjectAnimator.ofFloat(view, (android.util.Property<android.view.View, java.lang.Float>) property, f, f2);
        androidx.leanback.transition.C0076 c0076 = new androidx.leanback.transition.C0076(view, property, f3, f2, i);
        objectAnimatorOfFloat.addListener(c0076);
        objectAnimatorOfFloat.addPauseListener(c0076);
        objectAnimatorOfFloat.setInterpolator(timeInterpolator);
        return objectAnimatorOfFloat;
    }

    @Override // android.transition.Visibility
    public final android.animation.Animator onAppear(android.view.ViewGroup viewGroup, android.transition.TransitionValues transitionValues, int i, android.transition.TransitionValues transitionValues2, int i2) {
        android.view.View view = transitionValues2 != null ? transitionValues2.view : null;
        if (view == null) {
            return null;
        }
        float fM455 = this.f561.m455(view);
        return m445(view, this.f561.m456(), this.f561.m457(view), fM455, fM455, f558, 0);
    }

    @Override // android.transition.Visibility
    public final android.animation.Animator onDisappear(android.view.ViewGroup viewGroup, android.transition.TransitionValues transitionValues, int i, android.transition.TransitionValues transitionValues2, int i2) {
        android.view.View view = transitionValues != null ? transitionValues.view : null;
        if (view == null) {
            return null;
        }
        float fM455 = this.f561.m455(view);
        return m445(view, this.f561.m456(), fM455, this.f561.m457(view), fM455, f553, 4);
    }
}
