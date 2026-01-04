package p053;

/* renamed from: ʽᵔ.ʽ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C1432 extends p179.AbstractC2727 {

    /* renamed from: ˈ, reason: contains not printable characters */
    public final /* synthetic */ int f5595 = 1;

    /* renamed from: ˑﹳ, reason: contains not printable characters */
    public final java.lang.CharSequence[] f5596;

    /* renamed from: ᵎﹶ, reason: contains not printable characters */
    public final /* synthetic */ java.lang.Object f5597;

    /* renamed from: ᵔᵢ, reason: contains not printable characters */
    public java.lang.Object f5598;

    /* renamed from: ﾞᴵ, reason: contains not printable characters */
    public final java.lang.CharSequence[] f5599;

    public C1432(p053.C1434 c1434, java.lang.CharSequence[] charSequenceArr, java.lang.CharSequence[] charSequenceArr2, java.lang.CharSequence charSequence) {
        this.f5597 = c1434;
        this.f5596 = charSequenceArr;
        this.f5599 = charSequenceArr2;
        this.f5598 = charSequence;
    }

    public C1432(p053.C1434 c1434, java.lang.CharSequence[] charSequenceArr, java.lang.CharSequence[] charSequenceArr2, java.util.Set set) {
        this.f5597 = c1434;
        this.f5596 = charSequenceArr;
        this.f5599 = charSequenceArr2;
        this.f5598 = new java.util.HashSet(set);
    }

    public C1432(p312.C3860 c3860, java.lang.String[] strArr, android.graphics.drawable.Drawable[] drawableArr) {
        this.f5597 = c3860;
        this.f5596 = strArr;
        this.f5599 = new java.lang.String[strArr.length];
        this.f5598 = drawableArr;
    }

    /* renamed from: ᵔʾ, reason: contains not printable characters */
    public boolean m4197(int i) {
        p312.C3860 c3860 = (p312.C3860) this.f5597;
        ʽⁱ.ᵎﹶ r1 = c3860.f15025;
        if (r1 == null) {
            return false;
        }
        if (i == 0) {
            return r1.ᐧﹶ(13);
        }
        if (i != 1) {
            return true;
        }
        return r1.ᐧﹶ(30) && c3860.f15025.ᐧﹶ(29);
    }

    @Override // p179.AbstractC2727
    /* renamed from: ᵔᵢ */
    public final p179.AbstractC2673 mo610(android.view.ViewGroup viewGroup, int i) {
        switch (this.f5595) {
            case 0:
                return new p053.ViewOnClickListenerC1433(p035.AbstractC1220.m3789(viewGroup, ar.tvplayer.tv.R.layout._48_res_0x7f0e00d0, viewGroup, false), this);
            case 1:
                return new p053.ViewOnClickListenerC1433(p035.AbstractC1220.m3789(viewGroup, ar.tvplayer.tv.R.layout.qo, viewGroup, false), this);
            default:
                p312.C3860 c3860 = (p312.C3860) this.f5597;
                return new p312.C3855(c3860, android.view.LayoutInflater.from(c3860.getContext()).inflate(ar.tvplayer.tv.R.layout._513_res_0x7f0e003f, viewGroup, false));
        }
    }

    @Override // p179.AbstractC2727
    /* renamed from: ⁱˊ */
    public long mo2393(int i) {
        switch (this.f5595) {
            case 2:
                return i;
            default:
                return super.mo2393(i);
        }
    }

    @Override // p179.AbstractC2727
    /* renamed from: ﹳٴ */
    public final int mo611() {
        switch (this.f5595) {
            case 0:
                return this.f5596.length;
            case 1:
                return this.f5596.length;
            default:
                return ((java.lang.String[]) this.f5596).length;
        }
    }

    @Override // p179.AbstractC2727
    /* renamed from: ﾞᴵ */
    public final void mo612(p179.AbstractC2673 abstractC2673, int i) {
        switch (this.f5595) {
            case 0:
                p053.ViewOnClickListenerC1433 viewOnClickListenerC1433 = (p053.ViewOnClickListenerC1433) abstractC2673;
                viewOnClickListenerC1433.f5602.setChecked(((java.util.HashSet) this.f5598).contains(this.f5599[i].toString()));
                viewOnClickListenerC1433.f5600.setText(this.f5596[i]);
                break;
            case 1:
                p053.ViewOnClickListenerC1433 viewOnClickListenerC14332 = (p053.ViewOnClickListenerC1433) abstractC2673;
                viewOnClickListenerC14332.f5602.setChecked(android.text.TextUtils.equals(this.f5599[i].toString(), (java.lang.CharSequence) this.f5598));
                viewOnClickListenerC14332.f5600.setText(this.f5596[i]);
                break;
            default:
                p312.C3855 c3855 = (p312.C3855) abstractC2673;
                android.view.View view = c3855.f10176;
                if (m4197(i)) {
                    view.setLayoutParams(new p179.C2700(-1, -2));
                } else {
                    view.setLayoutParams(new p179.C2700(0, 0));
                }
                android.widget.TextView textView = c3855.f14910;
                android.widget.ImageView imageView = c3855.f14909;
                android.widget.TextView textView2 = c3855.f14907;
                textView.setText(((java.lang.String[]) this.f5596)[i]);
                java.lang.String str = ((java.lang.String[]) this.f5599)[i];
                if (str == null) {
                    textView2.setVisibility(8);
                } else {
                    textView2.setText(str);
                }
                android.graphics.drawable.Drawable drawable = ((android.graphics.drawable.Drawable[]) this.f5598)[i];
                if (drawable != null) {
                    imageView.setImageDrawable(drawable);
                    break;
                } else {
                    imageView.setVisibility(8);
                    break;
                }
        }
    }
}
