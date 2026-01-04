package androidx.leanback.widget;

/* loaded from: classes.dex */
public class SpeechOrbView extends androidx.leanback.widget.SearchOrbView {

    /* renamed from: ˈⁱ, reason: contains not printable characters */
    public androidx.leanback.widget.C0116 f776;

    /* renamed from: ˉـ, reason: contains not printable characters */
    public boolean f777;

    /* renamed from: ـˏ, reason: contains not printable characters */
    public final float f778;

    /* renamed from: ᴵˑ, reason: contains not printable characters */
    public int f779;

    /* renamed from: ﹳـ, reason: contains not printable characters */
    public androidx.leanback.widget.C0116 f780;

    public SpeechOrbView(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet, 0);
        this.f779 = 0;
        this.f777 = false;
        android.content.res.Resources resources = context.getResources();
        this.f778 = resources.getFraction(ar.tvplayer.tv.R.fraction._26a_res_0x7f0a0006, 1, 1);
        this.f776 = new androidx.leanback.widget.C0116(resources.getColor(ar.tvplayer.tv.R.color._10v_res_0x7f0600f8), resources.getColor(ar.tvplayer.tv.R.color._2rs_res_0x7f0600fa), resources.getColor(ar.tvplayer.tv.R.color.ne));
        this.f780 = new androidx.leanback.widget.C0116(resources.getColor(ar.tvplayer.tv.R.color._6n5_res_0x7f0600fb), resources.getColor(ar.tvplayer.tv.R.color._6n5_res_0x7f0600fb), 0);
        m556();
    }

    @Override // androidx.leanback.widget.SearchOrbView
    public int getLayoutResourceId() {
        return ar.tvplayer.tv.R.layout.lb_speech_orb;
    }

    public void setListeningOrbColors(androidx.leanback.widget.C0116 c0116) {
        this.f780 = c0116;
    }

    public void setNotListeningOrbColors(androidx.leanback.widget.C0116 c0116) {
        this.f776 = c0116;
    }

    public void setSoundLevel(int i) {
        if (this.f777) {
            int i2 = this.f779;
            if (i > i2) {
                this.f779 = ((i - i2) / 2) + i2;
            } else {
                this.f779 = (int) (i2 * 0.7f);
            }
            float focusedZoom = (((this.f778 - getFocusedZoom()) * this.f779) / 100.0f) + 1.0f;
            android.view.View view = this.f744;
            view.setScaleX(focusedZoom);
            view.setScaleY(focusedZoom);
        }
    }

    /* renamed from: ʽ, reason: contains not printable characters */
    public final void m556() {
        setOrbColors(this.f776);
        setOrbIcon(getResources().getDrawable(2131231126));
        m554(hasFocus());
        android.view.View view = this.f744;
        view.setScaleX(1.0f);
        view.setScaleY(1.0f);
        this.f777 = false;
    }
}
