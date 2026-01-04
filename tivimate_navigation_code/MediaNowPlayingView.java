package androidx.leanback.widget;

/* loaded from: classes.dex */
public class MediaNowPlayingView extends android.widget.LinearLayout {

    /* renamed from: ʽʽ, reason: contains not printable characters */
    public final android.widget.ImageView f665;

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public final android.widget.ImageView f666;

    /* renamed from: ˈٴ, reason: contains not printable characters */
    public final android.animation.ObjectAnimator f667;

    /* renamed from: ˊʻ, reason: contains not printable characters */
    public final android.animation.ObjectAnimator f668;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public final android.widget.ImageView f669;

    /* renamed from: ᴵᵔ, reason: contains not printable characters */
    public final android.animation.ObjectAnimator f670;

    public MediaNowPlayingView(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet);
        android.view.animation.LinearInterpolator linearInterpolator = new android.view.animation.LinearInterpolator();
        android.view.LayoutInflater.from(context).inflate(ar.tvplayer.tv.R.layout._61b_res_0x7f0e00bc, (android.view.ViewGroup) this, true);
        android.widget.ImageView imageView = (android.widget.ImageView) findViewById(ar.tvplayer.tv.R.id._4ui_res_0x7f0b0072);
        this.f666 = imageView;
        android.widget.ImageView imageView2 = (android.widget.ImageView) findViewById(ar.tvplayer.tv.R.id._6h2_res_0x7f0b0073);
        this.f669 = imageView2;
        android.widget.ImageView imageView3 = (android.widget.ImageView) findViewById(ar.tvplayer.tv.R.id._5ga_res_0x7f0b0074);
        this.f665 = imageView3;
        imageView.setPivotY(imageView.getDrawable().getIntrinsicHeight());
        imageView2.setPivotY(imageView2.getDrawable().getIntrinsicHeight());
        imageView3.setPivotY(imageView3.getDrawable().getIntrinsicHeight());
        setDropScale(imageView);
        setDropScale(imageView2);
        setDropScale(imageView3);
        android.animation.ObjectAnimator objectAnimatorOfFloat = android.animation.ObjectAnimator.ofFloat(imageView, "scaleY", 0.41666666f, 0.25f, 0.41666666f, 0.5833333f, 0.75f, 0.8333333f, 0.9166667f, 1.0f, 0.9166667f, 1.0f, 0.8333333f, 0.6666667f, 0.5f, 0.33333334f, 0.16666667f, 0.33333334f, 0.5f, 0.5833333f, 0.75f, 0.9166667f, 0.75f, 0.5833333f, 0.41666666f, 0.25f, 0.41666666f, 0.6666667f, 0.41666666f, 0.25f, 0.33333334f, 0.41666666f);
        this.f667 = objectAnimatorOfFloat;
        objectAnimatorOfFloat.setRepeatCount(-1);
        objectAnimatorOfFloat.setDuration(2320L);
        objectAnimatorOfFloat.setInterpolator(linearInterpolator);
        android.animation.ObjectAnimator objectAnimatorOfFloat2 = android.animation.ObjectAnimator.ofFloat(imageView2, "scaleY", 1.0f, 0.9166667f, 0.8333333f, 0.9166667f, 1.0f, 0.9166667f, 0.75f, 0.5833333f, 0.75f, 0.9166667f, 1.0f, 0.8333333f, 0.6666667f, 0.8333333f, 1.0f, 0.9166667f, 0.75f, 0.41666666f, 0.25f, 0.41666666f, 0.6666667f, 0.8333333f, 1.0f, 0.8333333f, 0.75f, 0.6666667f, 1.0f);
        this.f670 = objectAnimatorOfFloat2;
        objectAnimatorOfFloat2.setRepeatCount(-1);
        objectAnimatorOfFloat2.setDuration(2080L);
        objectAnimatorOfFloat2.setInterpolator(linearInterpolator);
        android.animation.ObjectAnimator objectAnimatorOfFloat3 = android.animation.ObjectAnimator.ofFloat(imageView3, "scaleY", 0.6666667f, 0.75f, 0.8333333f, 1.0f, 0.9166667f, 0.75f, 0.5833333f, 0.41666666f, 0.5833333f, 0.6666667f, 0.75f, 1.0f, 0.9166667f, 1.0f, 0.75f, 0.5833333f, 0.75f, 0.9166667f, 1.0f, 0.8333333f, 0.6666667f, 0.75f, 0.5833333f, 0.41666666f, 0.25f, 0.6666667f);
        this.f668 = objectAnimatorOfFloat3;
        objectAnimatorOfFloat3.setRepeatCount(-1);
        objectAnimatorOfFloat3.setDuration(2000L);
        objectAnimatorOfFloat3.setInterpolator(linearInterpolator);
    }

    public static void setDropScale(android.view.View view) {
        view.setScaleY(0.083333336f);
    }

    @Override // android.view.ViewGroup, android.view.View
    public final void onAttachedToWindow() {
        super.onAttachedToWindow();
        if (getVisibility() == 0) {
            m542();
        }
    }

    @Override // android.view.ViewGroup, android.view.View
    public final void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        m541();
    }

    @Override // android.view.View
    public void setVisibility(int i) {
        super.setVisibility(i);
        if (i == 8) {
            m541();
        } else {
            m542();
        }
    }

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public final void m541() {
        android.animation.ObjectAnimator objectAnimator = this.f667;
        boolean zIsStarted = objectAnimator.isStarted();
        android.widget.ImageView imageView = this.f666;
        if (zIsStarted) {
            objectAnimator.cancel();
            setDropScale(imageView);
        }
        android.animation.ObjectAnimator objectAnimator2 = this.f670;
        boolean zIsStarted2 = objectAnimator2.isStarted();
        android.widget.ImageView imageView2 = this.f669;
        if (zIsStarted2) {
            objectAnimator2.cancel();
            setDropScale(imageView2);
        }
        android.animation.ObjectAnimator objectAnimator3 = this.f668;
        boolean zIsStarted3 = objectAnimator3.isStarted();
        android.widget.ImageView imageView3 = this.f665;
        if (zIsStarted3) {
            objectAnimator3.cancel();
            setDropScale(imageView3);
        }
        imageView.setVisibility(8);
        imageView2.setVisibility(8);
        imageView3.setVisibility(8);
    }

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final void m542() {
        android.animation.ObjectAnimator objectAnimator = this.f667;
        if (!objectAnimator.isStarted()) {
            objectAnimator.start();
        }
        android.animation.ObjectAnimator objectAnimator2 = this.f670;
        if (!objectAnimator2.isStarted()) {
            objectAnimator2.start();
        }
        android.animation.ObjectAnimator objectAnimator3 = this.f668;
        if (!objectAnimator3.isStarted()) {
            objectAnimator3.start();
        }
        this.f666.setVisibility(0);
        this.f669.setVisibility(0);
        this.f665.setVisibility(0);
    }
}
