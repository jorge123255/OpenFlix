package androidx.leanback.widget;

/* loaded from: classes.dex */
public class SearchOrbView extends android.widget.FrameLayout implements android.view.View.OnClickListener {

    /* renamed from: ʼˈ, reason: contains not printable characters */
    public static final /* synthetic */ int f743 = 0;

    /* renamed from: ʽʽ, reason: contains not printable characters */
    public final android.view.View f744;

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public android.view.View.OnClickListener f745;

    /* renamed from: ˆﾞ, reason: contains not printable characters */
    public boolean f746;

    /* renamed from: ˈʿ, reason: contains not printable characters */
    public final android.animation.ArgbEvaluator f747;

    /* renamed from: ˈٴ, reason: contains not printable characters */
    public final android.widget.ImageView f748;

    /* renamed from: ˉٴ, reason: contains not printable characters */
    public final int f749;

    /* renamed from: ˊʻ, reason: contains not printable characters */
    public androidx.leanback.widget.C0116 f750;

    /* renamed from: ˊˋ, reason: contains not printable characters */
    public final androidx.leanback.widget.C0081 f751;

    /* renamed from: ˋᵔ, reason: contains not printable characters */
    public android.animation.ValueAnimator f752;

    /* renamed from: ˑٴ, reason: contains not printable characters */
    public final androidx.leanback.widget.C0081 f753;

    /* renamed from: ٴʼ, reason: contains not printable characters */
    public final float f754;

    /* renamed from: ٴᵢ, reason: contains not printable characters */
    public final float f755;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public final android.view.View f756;

    /* renamed from: ᴵᵔ, reason: contains not printable characters */
    public android.graphics.drawable.Drawable f757;

    /* renamed from: ᵎˊ, reason: contains not printable characters */
    public final float f758;

    /* renamed from: ᵎⁱ, reason: contains not printable characters */
    public final int f759;

    /* renamed from: ᵔי, reason: contains not printable characters */
    public android.animation.ValueAnimator f760;

    /* renamed from: ᵔٴ, reason: contains not printable characters */
    public boolean f761;

    public SearchOrbView(android.content.Context context, android.util.AttributeSet attributeSet) {
        this(context, attributeSet, ar.tvplayer.tv.R.attr.ob);
    }

    public SearchOrbView(android.content.Context context, android.util.AttributeSet attributeSet, int i) {
        super(context, attributeSet, i);
        this.f747 = new android.animation.ArgbEvaluator();
        this.f753 = new androidx.leanback.widget.C0081(0, this);
        this.f751 = new androidx.leanback.widget.C0081(1, this);
        android.content.res.Resources resources = context.getResources();
        android.view.View viewInflate = ((android.view.LayoutInflater) context.getSystemService("layout_inflater")).inflate(getLayoutResourceId(), (android.view.ViewGroup) this, true);
        this.f756 = viewInflate;
        this.f744 = viewInflate.findViewById(ar.tvplayer.tv.R.id._34m_res_0x7f0b0342);
        android.widget.ImageView imageView = (android.widget.ImageView) viewInflate.findViewById(ar.tvplayer.tv.R.id.icon);
        this.f748 = imageView;
        this.f755 = context.getResources().getFraction(ar.tvplayer.tv.R.fraction._21m_res_0x7f0a0007, 1, 1);
        this.f749 = context.getResources().getInteger(ar.tvplayer.tv.R.integer._4mr_res_0x7f0c0030);
        this.f759 = context.getResources().getInteger(ar.tvplayer.tv.R.integer._6n1_res_0x7f0c0031);
        float dimensionPixelSize = context.getResources().getDimensionPixelSize(ar.tvplayer.tv.R.dimen._3bl_res_0x7f0701cb);
        this.f758 = dimensionPixelSize;
        this.f754 = context.getResources().getDimensionPixelSize(ar.tvplayer.tv.R.dimen._1tl_res_0x7f0701d1);
        int[] iArr = p272.AbstractC3483.f13668;
        android.content.res.TypedArray typedArrayObtainStyledAttributes = context.obtainStyledAttributes(attributeSet, iArr, i, 0);
        p186.AbstractC2823.m6282(this, context, iArr, attributeSet, typedArrayObtainStyledAttributes, i);
        android.graphics.drawable.Drawable drawable = typedArrayObtainStyledAttributes.getDrawable(2);
        setOrbIcon(drawable == null ? resources.getDrawable(2131231113) : drawable);
        int color = typedArrayObtainStyledAttributes.getColor(1, resources.getColor(ar.tvplayer.tv.R.color._5g0_res_0x7f0600d1));
        setOrbColors(new androidx.leanback.widget.C0116(color, typedArrayObtainStyledAttributes.getColor(0, color), typedArrayObtainStyledAttributes.getColor(3, 0)));
        typedArrayObtainStyledAttributes.recycle();
        setFocusable(true);
        setClipChildren(false);
        setOnClickListener(this);
        setSoundEffectsEnabled(false);
        setSearchOrbZ(0.0f);
        p186.AbstractC2776.m6182(imageView, dimensionPixelSize);
    }

    public float getFocusedZoom() {
        return this.f755;
    }

    public int getLayoutResourceId() {
        return ar.tvplayer.tv.R.layout.lb_search_orb;
    }

    public int getOrbColor() {
        return this.f750.f927;
    }

    public androidx.leanback.widget.C0116 getOrbColors() {
        return this.f750;
    }

    public android.graphics.drawable.Drawable getOrbIcon() {
        return this.f757;
    }

    @Override // android.view.ViewGroup, android.view.View
    public final void onAttachedToWindow() {
        super.onAttachedToWindow();
        this.f761 = true;
        m553();
    }

    @Override // android.view.View.OnClickListener
    public final void onClick(android.view.View view) {
        android.view.View.OnClickListener onClickListener = this.f745;
        if (onClickListener != null) {
            onClickListener.onClick(view);
        }
    }

    @Override // android.view.ViewGroup, android.view.View
    public final void onDetachedFromWindow() {
        this.f761 = false;
        m553();
        super.onDetachedFromWindow();
    }

    @Override // android.view.View
    public final void onFocusChanged(boolean z, int i, android.graphics.Rect rect) {
        super.onFocusChanged(z, i, rect);
        m554(z);
    }

    public void setOnOrbClickedListener(android.view.View.OnClickListener onClickListener) {
        this.f745 = onClickListener;
    }

    public void setOrbColor(int i) {
        setOrbColors(new androidx.leanback.widget.C0116(i, i, 0));
    }

    public void setOrbColors(androidx.leanback.widget.C0116 c0116) {
        this.f750 = c0116;
        this.f748.setColorFilter(c0116.f925);
        if (this.f760 == null) {
            setOrbViewColor(this.f750.f927);
        } else {
            this.f746 = true;
            m553();
        }
    }

    public void setOrbIcon(android.graphics.drawable.Drawable drawable) {
        this.f757 = drawable;
        this.f748.setImageDrawable(drawable);
    }

    public void setOrbViewColor(int i) {
        android.view.View view = this.f744;
        if (view.getBackground() instanceof android.graphics.drawable.GradientDrawable) {
            ((android.graphics.drawable.GradientDrawable) view.getBackground()).setColor(i);
        }
    }

    public void setSearchOrbZ(float f) {
        float f2 = this.f754;
        float fM23 = android.support.v4.media.session.AbstractC0001.m23(this.f758, f2, f, f2);
        java.util.WeakHashMap weakHashMap = p186.AbstractC2823.f10603;
        p186.AbstractC2776.m6182(this.f744, fM23);
    }

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public final void m553() {
        android.animation.ValueAnimator valueAnimator = this.f760;
        if (valueAnimator != null) {
            valueAnimator.end();
            this.f760 = null;
        }
        if (this.f746 && this.f761) {
            android.animation.ValueAnimator valueAnimatorOfObject = android.animation.ValueAnimator.ofObject(this.f747, java.lang.Integer.valueOf(this.f750.f927), java.lang.Integer.valueOf(this.f750.f926), java.lang.Integer.valueOf(this.f750.f927));
            this.f760 = valueAnimatorOfObject;
            valueAnimatorOfObject.setRepeatCount(-1);
            this.f760.setDuration(this.f749 * 2);
            this.f760.addUpdateListener(this.f753);
            this.f760.start();
        }
    }

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final void m554(boolean z) {
        float f = z ? this.f755 : 1.0f;
        android.view.ViewPropertyAnimator viewPropertyAnimatorScaleY = this.f756.animate().scaleX(f).scaleY(f);
        long j = this.f759;
        viewPropertyAnimatorScaleY.setDuration(j).start();
        if (this.f752 == null) {
            android.animation.ValueAnimator valueAnimatorOfFloat = android.animation.ValueAnimator.ofFloat(0.0f, 1.0f);
            this.f752 = valueAnimatorOfFloat;
            valueAnimatorOfFloat.addUpdateListener(this.f751);
        }
        if (z) {
            this.f752.start();
        } else {
            this.f752.reverse();
        }
        this.f752.setDuration(j);
        this.f746 = z;
        m553();
    }
}
