package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ـˆ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C0122 {

    /* renamed from: ʽ, reason: contains not printable characters */
    public int f958;

    /* renamed from: ˈ, reason: contains not printable characters */
    public int f959;

    /* renamed from: ˑﹳ, reason: contains not printable characters */
    public int f960;

    /* renamed from: ᵎﹶ, reason: contains not printable characters */
    public java.lang.Object f961;

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public long f962;

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public int f963;

    /* renamed from: ﾞᴵ, reason: contains not printable characters */
    public final java.lang.Object f964;

    public C0122() {
        this.f964 = new int[255];
        this.f961 = new p305.C3732(255);
    }

    public C0122(android.content.Context context) {
        this.f958 = 0;
        this.f959 = 1;
        this.f960 = 0;
        this.f964 = context;
        this.f963 = 112;
    }

    /* renamed from: ʽ, reason: contains not printable characters */
    public void m628(boolean z) {
        this.f963 = ((z ? 1 : 0) & 1) | (this.f963 & (~1));
        if (this.f958 != 0) {
            throw new java.lang.IllegalArgumentException("Editable actions cannot also be checked");
        }
    }

    /* renamed from: ˈ, reason: contains not printable characters */
    public boolean m629(p171.InterfaceC2622 interfaceC2622, boolean z) throws androidx.media3.common.ParserException, java.io.EOFException {
        boolean zMo4572;
        boolean zMo45722;
        int[] iArr = (int[]) this.f964;
        this.f963 = 0;
        this.f962 = 0L;
        this.f958 = 0;
        this.f959 = 0;
        this.f960 = 0;
        p305.C3732 c3732 = (p305.C3732) this.f961;
        c3732.m7886(27);
        try {
            zMo4572 = interfaceC2622.mo4572(c3732.f14534, 0, 27, z);
        } catch (java.io.EOFException e) {
            if (!z) {
                throw e;
            }
            zMo4572 = false;
        }
        if (zMo4572 && c3732.m7880() == 1332176723) {
            if (c3732.m7874() == 0) {
                this.f963 = c3732.m7874();
                this.f962 = c3732.m7899();
                c3732.m7876();
                c3732.m7876();
                c3732.m7876();
                int iM7874 = c3732.m7874();
                this.f958 = iM7874;
                this.f959 = iM7874 + 27;
                c3732.m7886(iM7874);
                try {
                    zMo45722 = interfaceC2622.mo4572(c3732.f14534, 0, this.f958, z);
                } catch (java.io.EOFException e2) {
                    if (!z) {
                        throw e2;
                    }
                    zMo45722 = false;
                }
                if (zMo45722) {
                    for (int i = 0; i < this.f958; i++) {
                        int iM78742 = c3732.m7874();
                        iArr[i] = iM78742;
                        this.f960 += iM78742;
                    }
                    return true;
                }
            } else if (!z) {
                throw androidx.media3.common.ParserException.m739("unsupported bit stream revision");
            }
        }
        return false;
    }

    /* JADX WARN: Code restructure failed: missing block: B:21:0x004d, code lost:
    
        if (r11 == (-1)) goto L24;
     */
    /* JADX WARN: Code restructure failed: missing block: B:23:0x0055, code lost:
    
        if (r10.getPosition() >= r11) goto L33;
     */
    /* JADX WARN: Code restructure failed: missing block: B:25:0x005c, code lost:
    
        if (r10.mo4580(1) == (-1)) goto L34;
     */
    /* JADX WARN: Code restructure failed: missing block: B:27:0x005f, code lost:
    
        return false;
     */
    /* renamed from: ˑﹳ, reason: contains not printable characters */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct add '--show-bad-code' argument
    */
    public boolean m630(p171.InterfaceC2622 r10, long r11) {
        /*
            r9 = this;
            java.lang.Object r0 = r9.f961
            ᐧˎ.ﹳᐧ r0 = (p305.C3732) r0
            long r1 = r10.getPosition()
            long r3 = r10.mo4577()
            int r1 = (r1 > r3 ? 1 : (r1 == r3 ? 0 : -1))
            r2 = 0
            r3 = 1
            if (r1 != 0) goto L14
            r1 = r3
            goto L15
        L14:
            r1 = r2
        L15:
            p305.AbstractC3731.m7849(r1)
            r1 = 4
            r0.m7886(r1)
        L1c:
            r4 = -1
            int r4 = (r11 > r4 ? 1 : (r11 == r4 ? 0 : -1))
            if (r4 == 0) goto L2d
            long r5 = r10.getPosition()
            r7 = 4
            long r5 = r5 + r7
            int r5 = (r5 > r11 ? 1 : (r5 == r11 ? 0 : -1))
            if (r5 >= 0) goto L4d
        L2d:
            byte[] r5 = r0.f14534
            boolean r5 = r10.mo4572(r5, r2, r1, r3)     // Catch: java.io.EOFException -> L34
            goto L35
        L34:
            r5 = r2
        L35:
            if (r5 == 0) goto L4d
            r0.m7896(r2)
            long r4 = r0.m7880()
            r6 = 1332176723(0x4f676753, double:6.58182753E-315)
            int r4 = (r4 > r6 ? 1 : (r4 == r6 ? 0 : -1))
            if (r4 != 0) goto L49
            r10.mo4600()
            return r3
        L49:
            r10.mo4595(r3)
            goto L1c
        L4d:
            if (r4 == 0) goto L57
            long r0 = r10.getPosition()
            int r0 = (r0 > r11 ? 1 : (r0 == r11 ? 0 : -1))
            if (r0 >= 0) goto L5f
        L57:
            int r0 = r10.mo4580(r3)
            r1 = -1
            if (r0 == r1) goto L5f
            goto L4d
        L5f:
            return r2
        */
        throw new UnsupportedOperationException("Method not decompiled: androidx.leanback.widget.C0122.m630(ˊﾞ.ʼᐧ, long):boolean");
    }

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public void m631(int i) {
        this.f960 = i;
        if (this.f958 != 0) {
            throw new java.lang.IllegalArgumentException("Editable actions cannot also be in check sets");
        }
    }

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public androidx.leanback.widget.C0095 m632() {
        androidx.leanback.widget.C0095 c0095 = new androidx.leanback.widget.C0095();
        c0095.f880 = -1L;
        new java.util.ArrayList();
        c0095.f880 = this.f962;
        c0095.f871 = (java.lang.String) this.f961;
        c0095.f882 = null;
        c0095.f873 = null;
        c0095.f877 = null;
        c0095.f879 = null;
        c0095.f878 = this.f958;
        c0095.f870 = 524289;
        c0095.f872 = 524289;
        c0095.f876 = 1;
        c0095.f881 = this.f959;
        c0095.f875 = this.f963;
        c0095.f874 = this.f960;
        return c0095;
    }

    /* renamed from: ﾞᴵ, reason: contains not printable characters */
    public void m633(int i) {
        this.f961 = ((android.content.Context) this.f964).getString(i);
    }
}
