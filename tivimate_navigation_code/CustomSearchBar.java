package androidx.leanback.widget;

/* loaded from: classes.dex */
public final class CustomSearchBar extends androidx.leanback.widget.SearchBar {
    public CustomSearchBar(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet, 0);
    }

    @Override // androidx.leanback.widget.SearchBar, android.view.View
    public final void onFinishInflate() throws android.content.res.Resources.NotFoundException {
        android.view.View viewFindViewById = findViewById(ar.tvplayer.tv.R.id._2f3_res_0x7f0b0248);
        if (viewFindViewById != null) {
            viewFindViewById.setBackgroundResource(ar.tvplayer.tv.R.drawable._3s0_res_0x7f080095);
        }
        super.onFinishInflate();
    }

    @Override // androidx.leanback.widget.SearchBar
    /* renamed from: ʽ, reason: contains not printable characters */
    public final void mo458() {
    }

    @Override // androidx.leanback.widget.SearchBar
    /* renamed from: ˈ, reason: contains not printable characters */
    public final void mo459() {
    }

    @Override // androidx.leanback.widget.SearchBar
    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public final void mo460() {
    }
}
