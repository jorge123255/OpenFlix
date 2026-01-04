package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ˈٴ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class ViewOnKeyListenerC0103 implements android.view.View.OnKeyListener {

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public boolean f897 = false;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public final /* synthetic */ androidx.leanback.widget.C0108 f898;

    public ViewOnKeyListenerC0103(androidx.leanback.widget.C0108 c0108) {
        this.f898 = c0108;
    }

    @Override // android.view.View.OnKeyListener
    public final boolean onKey(android.view.View view, int i, android.view.KeyEvent keyEvent) throws android.content.res.Resources.NotFoundException {
        androidx.leanback.widget.C0108 c0108 = this.f898;
        androidx.leanback.widget.C0117 c0117 = c0108.f918;
        if (view != null && keyEvent != null) {
            androidx.leanback.widget.VerticalGridView verticalGridView = c0108.f910;
            if (verticalGridView.f1499 && (i == 23 || i == 66 || i == 160 || i == 99 || i == 100)) {
                androidx.leanback.widget.C0101 c0101 = (androidx.leanback.widget.C0101) verticalGridView.m946(view);
                androidx.leanback.widget.C0095 c0095 = c0101.f896;
                if (!c0095.m580() || (c0095.f875 & 8) == 8) {
                    keyEvent.getAction();
                    return true;
                }
                int action = keyEvent.getAction();
                if (action != 0) {
                    if (action == 1 && this.f897) {
                        this.f897 = false;
                        c0117.m619(c0101, false);
                        return false;
                    }
                } else if (!this.f897) {
                    this.f897 = true;
                    c0117.m619(c0101, true);
                    return false;
                }
            }
        }
        return false;
    }
}
