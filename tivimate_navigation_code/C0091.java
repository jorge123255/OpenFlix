package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ʽⁱ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C0091 {

    /* renamed from: ʼˎ, reason: contains not printable characters */
    public int f848;

    /* renamed from: ʽ, reason: contains not printable characters */
    public int f849;

    /* renamed from: ˆʾ, reason: contains not printable characters */
    public int f850;

    /* renamed from: ˈ, reason: contains not printable characters */
    public int f851;

    /* renamed from: ٴﹶ, reason: contains not printable characters */
    public int f853;

    /* renamed from: ﾞʻ, reason: contains not printable characters */
    public boolean f858;

    /* renamed from: ˑﹳ, reason: contains not printable characters */
    public int f852 = 2;

    /* renamed from: ﾞᴵ, reason: contains not printable characters */
    public int f859 = 3;

    /* renamed from: ᵎﹶ, reason: contains not printable characters */
    public int f854 = 0;

    /* renamed from: ᵔᵢ, reason: contains not printable characters */
    public float f855 = 50.0f;

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public int f856 = Integer.MIN_VALUE;

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public int f857 = Integer.MAX_VALUE;

    public final java.lang.String toString() {
        return " min:" + this.f856 + " " + this.f851 + " max:" + this.f857 + " " + this.f849;
    }

    /* JADX WARN: Code restructure failed: missing block: B:17:0x0035, code lost:
    
        r6.f851 = r0 - r6.f850;
     */
    /* JADX WARN: Code restructure failed: missing block: B:27:0x0051, code lost:
    
        r6.f849 = (r4 - r6.f850) - r7;
     */
    /* renamed from: ʽ, reason: contains not printable characters */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct add '--show-bad-code' argument
    */
    public final void m575(int r7, int r8, int r9, int r10) {
        /*
            Method dump skipped, instructions count: 222
            To view this dump add '--comments-level debug' option
        */
        throw new UnsupportedOperationException("Method not decompiled: androidx.leanback.widget.C0091.m575(int, int, int, int):void");
    }

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public final int m576(int i) {
        int i2;
        int i3;
        int i4 = this.f848;
        int iM577 = m577();
        int i5 = this.f856;
        boolean z = i5 == Integer.MIN_VALUE;
        int i6 = this.f857;
        boolean z2 = i6 == Integer.MAX_VALUE;
        if (!z) {
            int i7 = this.f850;
            int i8 = iM577 - i7;
            if (this.f858 ? (this.f859 & 2) != 0 : (this.f859 & 1) != 0) {
                if (i - i5 <= i8) {
                    int i9 = i5 - i7;
                    return (z2 || i9 <= (i3 = this.f849)) ? i9 : i3;
                }
            }
        }
        if (!z2) {
            int i10 = this.f853;
            int i11 = (i4 - iM577) - i10;
            if (this.f858 ? (1 & this.f859) != 0 : (this.f859 & 2) != 0) {
                if (i6 - i <= i11) {
                    int i12 = i6 - (i4 - i10);
                    return (z || i12 >= (i2 = this.f851)) ? i12 : i2;
                }
            }
        }
        return i - iM577;
    }

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final int m577() {
        if (this.f858) {
            int i = this.f854;
            int i2 = i >= 0 ? this.f848 - i : -i;
            float f = this.f855;
            return f != -1.0f ? i2 - ((int) ((this.f848 * f) / 100.0f)) : i2;
        }
        int i3 = this.f854;
        if (i3 < 0) {
            i3 += this.f848;
        }
        float f2 = this.f855;
        return f2 != -1.0f ? i3 + ((int) ((this.f848 * f2) / 100.0f)) : i3;
    }
}
