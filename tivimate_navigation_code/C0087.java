package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ʼᐧ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C0087 extends androidx.leanback.widget.AbstractC0146 {

    /* renamed from: יـ, reason: contains not printable characters */
    public final /* synthetic */ androidx.leanback.widget.GridLayoutManager f843;

    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public C0087(androidx.leanback.widget.GridLayoutManager gridLayoutManager) {
        super(gridLayoutManager);
        this.f843 = gridLayoutManager;
    }

    @Override // p179.C2688
    /* renamed from: ﾞᴵ, reason: contains not printable characters */
    public final android.graphics.PointF mo573(int i) {
        if (this.f10246.f1521.m5974() == 0) {
            return null;
        }
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f843;
        int iM5963 = p179.AbstractC2669.m5963(gridLayoutManager.m5981(0));
        int i2 = ((gridLayoutManager.f601 & 262144) == 0 ? i >= iM5963 : i <= iM5963) ? 1 : -1;
        return gridLayoutManager.f620 == 0 ? new android.graphics.PointF(i2, 0.0f) : new android.graphics.PointF(0.0f, i2);
    }
}
