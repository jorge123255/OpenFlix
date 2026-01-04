package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ʽʽ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class ViewOnFocusChangeListenerC0089 implements android.view.View.OnFocusChangeListener {

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public final /* synthetic */ androidx.leanback.widget.C0108 f844;

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public android.view.View f845;

    public ViewOnFocusChangeListenerC0089(androidx.leanback.widget.C0108 c0108, androidx.leanback.app.C0069 c0069) {
        this.f844 = c0108;
    }

    @Override // android.view.View.OnFocusChangeListener
    public final void onFocusChange(android.view.View view, boolean z) throws android.content.res.Resources.NotFoundException {
        androidx.leanback.widget.C0108 c0108 = this.f844;
        androidx.leanback.widget.C0117 c0117 = c0108.f918;
        androidx.leanback.widget.VerticalGridView verticalGridView = c0108.f910;
        if (verticalGridView.f1499) {
            androidx.leanback.widget.C0101 c0101 = (androidx.leanback.widget.C0101) verticalGridView.m946(view);
            if (z) {
                this.f845 = view;
                androidx.leanback.widget.C0095 c0095 = c0101.f896;
            } else if (this.f845 == view) {
                c0117.getClass();
                c0101.m590(false);
                this.f845 = null;
            }
            c0117.getClass();
        }
    }
}
