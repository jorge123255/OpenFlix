package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ᵔﹳ, reason: contains not printable characters */
/* loaded from: classes.dex */
public abstract class AbstractC0146 extends p179.C2688 {

    /* renamed from: ᵔﹳ, reason: contains not printable characters */
    public boolean f1008;

    /* renamed from: ﹳᐧ, reason: contains not printable characters */
    public final /* synthetic */ androidx.leanback.widget.GridLayoutManager f1009;

    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public AbstractC0146(androidx.leanback.widget.GridLayoutManager gridLayoutManager) {
        super(gridLayoutManager.f639.getContext());
        this.f1009 = gridLayoutManager;
    }

    @Override // p179.C2688
    /* renamed from: ʼˎ, reason: contains not printable characters */
    public final void mo658(android.view.View view, p179.C2715 c2715) {
        int i;
        int i2;
        int[] iArr = androidx.leanback.widget.GridLayoutManager.f594;
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1009;
        if (gridLayoutManager.m537(view, null, iArr)) {
            if (gridLayoutManager.f620 == 0) {
                i = iArr[0];
                i2 = iArr[1];
            } else {
                i = iArr[1];
                i2 = iArr[0];
            }
            int iCeil = (int) java.lang.Math.ceil(mo660((int) java.lang.Math.sqrt((i2 * i2) + (i * i))) / 0.3356d);
            c2715.f10328 = i;
            c2715.f10327 = i2;
            c2715.f10323 = iCeil;
            c2715.f10325 = this.f10237;
            c2715.f10329 = true;
        }
    }

    @Override // p179.C2688
    /* renamed from: ˈ, reason: contains not printable characters */
    public final float mo659(android.util.DisplayMetrics displayMetrics) {
        return super.mo659(displayMetrics) * this.f1009.f600;
    }

    @Override // p179.C2688
    /* renamed from: ˑﹳ, reason: contains not printable characters */
    public final int mo660(int i) {
        int iMo660 = super.mo660(i);
        int i2 = ((androidx.leanback.widget.C0091) this.f1009.f606.ˈٴ).f848;
        if (i2 > 0) {
            float f = (30.0f / i2) * i;
            if (iMo660 < f) {
                return (int) f;
            }
        }
        return iMo660;
    }

    /* renamed from: ٴﹶ */
    public void mo622() {
        android.view.View viewMo904 = this.f10246.f1521.mo904(this.f10247);
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1009;
        if (viewMo904 == null) {
            int i = this.f10247;
            if (i >= 0) {
                gridLayoutManager.m509(i, 0, false);
                return;
            }
            return;
        }
        int i2 = gridLayoutManager.f613;
        int i3 = this.f10247;
        if (i2 != i3) {
            gridLayoutManager.f613 = i3;
        }
        if (gridLayoutManager.m5978()) {
            gridLayoutManager.f601 |= 32;
            viewMo904.requestFocus();
            gridLayoutManager.f601 &= -33;
        }
        gridLayoutManager.m505();
        gridLayoutManager.m497();
    }

    @Override // p179.C2688
    /* renamed from: ᵔᵢ, reason: contains not printable characters */
    public final void mo661() {
        super.mo661();
        if (!this.f1008) {
            mo622();
        }
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1009;
        if (gridLayoutManager.f612 == this) {
            gridLayoutManager.f612 = null;
        }
        if (gridLayoutManager.f633 == this) {
            gridLayoutManager.f633 = null;
        }
    }
}
