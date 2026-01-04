package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ˏᵢ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class RunnableC0114 implements java.lang.Runnable {

    /* renamed from: ʽʽ, reason: contains not printable characters */
    public final java.lang.Object f922;

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public final /* synthetic */ int f923;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public final int f924;

    public /* synthetic */ RunnableC0114(int i, int i2, java.lang.Object obj) {
        this.f923 = i2;
        this.f922 = obj;
        this.f924 = i;
    }

    public RunnableC0114(java.util.List list, int i, java.lang.Throwable th) {
        this.f923 = 2;
        ˈˊ.ˉˆ.ﾞᴵ(list, "initCallbacks cannot be null");
        this.f922 = new java.util.ArrayList(list);
        this.f924 = i;
    }

    @Override // java.lang.Runnable
    public final void run() {
        switch (this.f923) {
            case 0:
                androidx.leanback.widget.SearchBar searchBar = (androidx.leanback.widget.SearchBar) this.f922;
                searchBar.f741.play(searchBar.f724.get(this.f924), 1.0f, 1.0f, 1, 0, 1.0f);
                break;
            case 1:
                ((com.google.android.material.datepicker.C0678) this.f922).f2767.mo656(this.f924);
                break;
            case 2:
                java.util.ArrayList arrayList = (java.util.ArrayList) this.f922;
                int size = arrayList.size();
                int i = 0;
                if (this.f924 == 1) {
                    while (i < size) {
                        ((p275.AbstractC3519) arrayList.get(i)).mo5338();
                        i++;
                    }
                    break;
                } else {
                    while (i < size) {
                        ((p275.AbstractC3519) arrayList.get(i)).mo5339();
                        i++;
                    }
                    break;
                }
            case 3:
                p143.AbstractC2392 abstractC2392 = (p143.AbstractC2392) ((ᐧﹳ.ʽ) this.f922).ᴵˊ;
                if (abstractC2392 != null) {
                    abstractC2392.mo5307(this.f924);
                    break;
                }
                break;
            default:
                ((p409.C4840) this.f922).m9636(this.f924);
                break;
        }
    }
}
