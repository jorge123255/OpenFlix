package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ᴵʼ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class ViewOnFocusChangeListenerC0133 implements android.view.View.OnFocusChangeListener {

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public final /* synthetic */ androidx.leanback.widget.SearchBar f978;

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final /* synthetic */ int f979;

    public /* synthetic */ ViewOnFocusChangeListenerC0133(androidx.leanback.widget.SearchBar searchBar, int i) {
        this.f979 = i;
        this.f978 = searchBar;
    }

    @Override // android.view.View.OnFocusChangeListener
    public final void onFocusChange(android.view.View view, boolean z) {
        switch (this.f979) {
            case 0:
                androidx.leanback.widget.SearchBar searchBar = this.f978;
                if (z) {
                    searchBar.f738.post(new androidx.leanback.widget.RunnableC0082(searchBar, 1));
                } else {
                    searchBar.m551();
                }
                searchBar.m550(z);
                break;
            default:
                androidx.leanback.widget.SearchBar searchBar2 = this.f978;
                if (z) {
                    searchBar2.m551();
                    if (searchBar2.f737) {
                        searchBar2.m548();
                        searchBar2.f737 = false;
                    }
                } else {
                    searchBar2.m552();
                }
                searchBar2.m550(z);
                break;
        }
    }
}
