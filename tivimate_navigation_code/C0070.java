package androidx.leanback.app;

/* renamed from: androidx.leanback.app.ⁱˊ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C0070 implements androidx.leanback.widget.InterfaceC0136 {

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public final /* synthetic */ androidx.leanback.app.C0069 f537;

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final /* synthetic */ int f538;

    public /* synthetic */ C0070(androidx.leanback.app.C0069 c0069, int i) {
        this.f538 = i;
        this.f537 = c0069;
    }

    @Override // androidx.leanback.widget.InterfaceC0136
    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final void mo441(androidx.leanback.widget.C0095 c0095) {
        int iIndexOf;
        switch (this.f538) {
            case 0:
                androidx.leanback.app.C0069 c0069 = this.f537;
                c0069.m433(c0095);
                androidx.leanback.widget.C0117 c0117 = c0069.f530;
                if (c0117.f946 == null) {
                    c0095.getClass();
                    if (c0095.m585()) {
                        androidx.leanback.widget.C0117 c01172 = c0069.f530;
                        if (c01172.f938 == null && c01172.f946 == null && (iIndexOf = ((androidx.leanback.widget.C0108) c01172.f944.getAdapter()).f909.indexOf(c0095)) >= 0) {
                            c01172.f944.m653(iIndexOf, new androidx.leanback.widget.C0138(c01172));
                            break;
                        }
                    }
                } else if (c0117 != null && c0117.f944 != null) {
                    c0117.m620(true);
                    break;
                }
                break;
            default:
                androidx.leanback.widget.C0117 c01173 = this.f537.f530;
                if (c01173.f938 == null && c01173 != null && c01173.f944 != null) {
                    c01173.m620(true);
                    break;
                }
                break;
        }
    }
}
