package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ˉʿ, reason: contains not printable characters */
/* loaded from: classes.dex */
public abstract class AbstractC0105 {

    /* renamed from: ʽ, reason: contains not printable characters */
    public boolean f900;

    /* renamed from: ˈ, reason: contains not printable characters */
    public int f901;

    /* renamed from: ˑﹳ, reason: contains not printable characters */
    public int f902;

    /* renamed from: ᵔᵢ, reason: contains not printable characters */
    public p179.C2676[] f904;

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public androidx.leanback.widget.ˉˆ f905;

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final java.lang.Object[] f906 = new java.lang.Object[1];

    /* renamed from: ﾞᴵ, reason: contains not printable characters */
    public int f907 = -1;

    /* renamed from: ᵎﹶ, reason: contains not printable characters */
    public int f903 = -1;

    /* renamed from: ʼˎ, reason: contains not printable characters */
    public int f899 = -1;

    /* renamed from: ʼˎ, reason: contains not printable characters */
    public final int m591(boolean z, int[] iArr) {
        return mo600(this.f900 ? this.f903 : this.f907, z, iArr);
    }

    /* renamed from: ʽ, reason: contains not printable characters */
    public final boolean m592(int i) {
        return this.f903 >= 0 && (!this.f900 ? m598(false, null) < i - this.f901 : m591(true, null) > i + this.f901);
    }

    /* renamed from: ˆʾ, reason: contains not printable characters */
    public abstract p179.C2676[] mo593(int i, int i2);

    /* renamed from: ˈ, reason: contains not printable characters */
    public final boolean m594(int i) {
        return this.f903 >= 0 && (!this.f900 ? m591(true, null) > i + this.f901 : m598(false, null) < i - this.f901);
    }

    /* renamed from: ˉʿ, reason: contains not printable characters */
    public abstract boolean mo595(int i, boolean z);

    /* renamed from: ˑﹳ, reason: contains not printable characters */
    public void mo596(int i, int i2, p179.C2676 c2676) {
    }

    /* renamed from: ٴﹶ, reason: contains not printable characters */
    public abstract androidx.leanback.widget.ﾞʻ mo597(int i);

    /* renamed from: ᵎﹶ, reason: contains not printable characters */
    public final int m598(boolean z, int[] iArr) {
        return mo604(this.f900 ? this.f907 : this.f903, z, iArr);
    }

    /* renamed from: ᵔʾ, reason: contains not printable characters */
    public final void m599(int i) {
        if (i <= 0) {
            throw new java.lang.IllegalArgumentException();
        }
        if (this.f902 == i) {
            return;
        }
        this.f902 = i;
        this.f904 = new p179.C2676[i];
        for (int i2 = 0; i2 < this.f902; i2++) {
            this.f904[i2] = new p179.C2676();
        }
    }

    /* renamed from: ᵔᵢ, reason: contains not printable characters */
    public abstract int mo600(int i, boolean z, int[] iArr);

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public abstract boolean mo601(int i, boolean z);

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final boolean m602() {
        return mo601(this.f900 ? Integer.MAX_VALUE : Integer.MIN_VALUE, true);
    }

    /* renamed from: ﾞʻ, reason: contains not printable characters */
    public void mo603(int i) {
        int i2;
        if (i >= 0 && (i2 = this.f903) >= 0) {
            if (i2 >= i) {
                this.f903 = i - 1;
            }
            if (this.f903 < this.f907) {
                this.f903 = -1;
                this.f907 = -1;
            }
            if (this.f907 < 0) {
                this.f899 = i;
            }
        }
    }

    /* renamed from: ﾞᴵ, reason: contains not printable characters */
    public abstract int mo604(int i, boolean z, int[] iArr);
}
