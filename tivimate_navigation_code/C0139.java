package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ᵎᵔ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C0139 {

    /* renamed from: ʼˎ, reason: contains not printable characters */
    public float f984;

    /* renamed from: ʽ, reason: contains not printable characters */
    public float f985;

    /* renamed from: ˆʾ, reason: contains not printable characters */
    public final /* synthetic */ androidx.leanback.widget.PagingIndicator f986;

    /* renamed from: ˈ, reason: contains not printable characters */
    public float f987;

    /* renamed from: ˑﹳ, reason: contains not printable characters */
    public float f988;

    /* renamed from: ᵎﹶ, reason: contains not printable characters */
    public float f989;

    /* renamed from: ᵔᵢ, reason: contains not printable characters */
    public float f990 = 1.0f;

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public int f991;

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public float f992;

    /* renamed from: ﾞᴵ, reason: contains not printable characters */
    public float f993;

    public C0139(androidx.leanback.widget.PagingIndicator pagingIndicator) {
        this.f986 = pagingIndicator;
        this.f984 = pagingIndicator.f683 ? 1.0f : -1.0f;
    }

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public final void m648() {
        this.f985 = 0.0f;
        this.f987 = 0.0f;
        androidx.leanback.widget.PagingIndicator pagingIndicator = this.f986;
        this.f988 = pagingIndicator.f696;
        float f = pagingIndicator.f682;
        this.f993 = f;
        this.f989 = f * pagingIndicator.f687;
        this.f992 = 0.0f;
        m649();
    }

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final void m649() {
        int iRound = java.lang.Math.round(this.f992 * 255.0f);
        androidx.leanback.widget.PagingIndicator pagingIndicator = this.f986;
        this.f991 = android.graphics.Color.argb(iRound, android.graphics.Color.red(pagingIndicator.f692), android.graphics.Color.green(pagingIndicator.f692), android.graphics.Color.blue(pagingIndicator.f692));
    }
}
