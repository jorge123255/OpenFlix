package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ﹳٴ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C0150 implements p179.InterfaceC2706 {

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final /* synthetic */ androidx.leanback.widget.AbstractC0145 f1016;

    public C0150(androidx.leanback.widget.AbstractC0145 abstractC0145) {
        this.f1016 = abstractC0145;
    }

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final void m668(p179.AbstractC2673 abstractC2673) {
        int i;
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1016.f1005;
        gridLayoutManager.getClass();
        int iM6017 = abstractC2673.m6017();
        if (iM6017 != -1) {
            androidx.leanback.widget.C0121 c0121 = gridLayoutManager.f627;
            android.view.View view = abstractC2673.f10176;
            int i2 = c0121.f956;
            if (i2 != 1) {
                if ((i2 == 2 || i2 == 3) && ((p179.C2713) c0121.f955) != null) {
                    java.lang.String string = java.lang.Integer.toString(iM6017);
                    android.util.SparseArray<android.os.Parcelable> sparseArray = new android.util.SparseArray<>();
                    view.saveHierarchyState(sparseArray);
                    ((p179.C2713) c0121.f955).m6095(string, sparseArray);
                    return;
                }
                return;
            }
            p179.C2713 c2713 = (p179.C2713) c0121.f955;
            if (c2713 != null) {
                synchronized (((ˋⁱ.ﾞᴵ) c2713.f10317)) {
                    i = c2713.f10314;
                }
                if (i != 0) {
                    ((p179.C2713) c0121.f955).m6086(java.lang.Integer.toString(iM6017));
                }
            }
        }
    }
}
