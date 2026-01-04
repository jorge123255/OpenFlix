package p011;

/* renamed from: ʻᐧ.ˈٴ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class ViewOnKeyListenerC0860 implements android.view.View.OnKeyListener {

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public final /* synthetic */ int f3674;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public final /* synthetic */ java.lang.Object f3675;

    public /* synthetic */ ViewOnKeyListenerC0860(int i, java.lang.Object obj) {
        this.f3674 = i;
        this.f3675 = obj;
    }

    @Override // android.view.View.OnKeyListener
    public final boolean onKey(android.view.View view, int i, android.view.KeyEvent keyEvent) {
        android.widget.SeekBar seekBar;
        switch (this.f3674) {
            case 0:
                if (keyEvent.getAction() != 0) {
                    return false;
                }
                androidx.preference.SeekBarPreference seekBarPreference = (androidx.preference.SeekBarPreference) this.f3675;
                if ((seekBarPreference.f1401 || (i != 21 && i != 22)) && i != 23 && i != 66 && (seekBar = seekBarPreference.f1402) != null) {
                    return seekBar.onKeyDown(i, keyEvent);
                }
                return false;
            default:
                if (i == 4) {
                    return ((p053.AbstractC1436) this.f3675).m6788().m6666(-1, 0);
                }
                return false;
        }
    }
}
