package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ˈʿ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C0101 extends p179.AbstractC2673 implements androidx.leanback.widget.InterfaceC0129 {

    /* renamed from: ʿ, reason: contains not printable characters */
    public final android.view.View f886;

    /* renamed from: ʿᵢ, reason: contains not printable characters */
    public final android.widget.ImageView f887;

    /* renamed from: ˈⁱ, reason: contains not printable characters */
    public final android.view.View f888;

    /* renamed from: ˉـ, reason: contains not printable characters */
    public final android.widget.TextView f889;

    /* renamed from: ˏᵢ, reason: contains not printable characters */
    public final boolean f890;

    /* renamed from: ᐧᴵ, reason: contains not printable characters */
    public int f891;

    /* renamed from: ᐧﾞ, reason: contains not printable characters */
    public final android.widget.ImageView f892;

    /* renamed from: ᴵʼ, reason: contains not printable characters */
    public android.animation.Animator f893;

    /* renamed from: ᴵˑ, reason: contains not printable characters */
    public final android.widget.TextView f894;

    /* renamed from: ᵎᵔ, reason: contains not printable characters */
    public final android.widget.ImageView f895;

    /* renamed from: ﹳـ, reason: contains not printable characters */
    public androidx.leanback.widget.C0095 f896;

    public C0101(android.view.View view, boolean z) {
        super(view);
        this.f891 = 0;
        androidx.leanback.widget.C0099 c0099 = new androidx.leanback.widget.C0099(0, this);
        this.f888 = view.findViewById(ar.tvplayer.tv.R.id._28m_res_0x7f0b01c1);
        this.f894 = (android.widget.TextView) view.findViewById(ar.tvplayer.tv.R.id._2br_res_0x7f0b01c4);
        this.f886 = view.findViewById(ar.tvplayer.tv.R.id._4fn_res_0x7f0b01bc);
        this.f889 = (android.widget.TextView) view.findViewById(ar.tvplayer.tv.R.id._7dt_res_0x7f0b01c2);
        this.f887 = (android.widget.ImageView) view.findViewById(ar.tvplayer.tv.R.id.r1);
        this.f895 = (android.widget.ImageView) view.findViewById(ar.tvplayer.tv.R.id._6va_res_0x7f0b01bf);
        this.f892 = (android.widget.ImageView) view.findViewById(ar.tvplayer.tv.R.id._2up_res_0x7f0b01c0);
        this.f890 = z;
        view.setAccessibilityDelegate(c0099);
    }

    /* renamed from: יـ, reason: contains not printable characters */
    public final void m590(boolean z) throws android.content.res.Resources.NotFoundException {
        android.animation.Animator animator = this.f893;
        if (animator != null) {
            animator.cancel();
            this.f893 = null;
        }
        int i = z ? ar.tvplayer.tv.R.attr._1mh_res_0x7f0402d9 : ar.tvplayer.tv.R.attr._2vj_res_0x7f0402dd;
        android.view.View view = this.f10176;
        android.content.Context context = view.getContext();
        android.util.TypedValue typedValue = new android.util.TypedValue();
        if (context.getTheme().resolveAttribute(i, typedValue, true)) {
            android.animation.Animator animatorLoadAnimator = android.animation.AnimatorInflater.loadAnimator(context, typedValue.resourceId);
            this.f893 = animatorLoadAnimator;
            animatorLoadAnimator.setTarget(view);
            this.f893.addListener(new androidx.leanback.widget.C0144(0, this));
            this.f893.start();
        }
    }
}
