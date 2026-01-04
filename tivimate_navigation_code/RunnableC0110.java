package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ˊᵔ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class RunnableC0110 implements java.lang.Runnable {

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public final /* synthetic */ int f920;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public final /* synthetic */ androidx.leanback.widget.C0134 f921;

    public /* synthetic */ RunnableC0110(androidx.leanback.widget.C0134 c0134, int i) {
        this.f920 = i;
        this.f921 = c0134;
    }

    @Override // java.lang.Runnable
    public final void run() {
        androidx.leanback.widget.InterfaceC0102 interfaceC0102;
        switch (this.f920) {
            case 0:
                androidx.leanback.widget.SearchBar searchBar = (androidx.leanback.widget.SearchBar) this.f921.f980;
                if (!android.text.TextUtils.isEmpty(searchBar.f736) && (interfaceC0102 = searchBar.f719) != null) {
                    ﾞᵔ.ˉٴ.ʽᐧ((ﾞᵔ.ˉٴ) ((p384.C4603) interfaceC0102).f17126, searchBar.f736, true);
                    break;
                }
                break;
            case 1:
                ʼⁱ.ʽ r0 = ((ﾞᵔ.ˉٴ) ((p384.C4603) ((androidx.leanback.widget.SearchBar) this.f921.f980).f719).f17126).m6803();
                ʼⁱ.ʽ r02 = r0 instanceof ʼⁱ.ʽ ? r0 : null;
                if (r02 != null) {
                    r02.ـˆ(false);
                    break;
                }
                break;
            default:
                androidx.leanback.widget.SearchBar searchBar2 = (androidx.leanback.widget.SearchBar) this.f921.f980;
                searchBar2.f737 = true;
                searchBar2.f718.requestFocus();
                break;
        }
    }
}
