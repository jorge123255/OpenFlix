package androidx.recyclerview.widget;

/* loaded from: classes.dex */
public class LinearLayoutManager extends p179.AbstractC2669 implements p179.InterfaceC2677 {

    /* renamed from: ʻٴ, reason: contains not printable characters */
    public boolean f1433;

    /* renamed from: ʼʼ, reason: contains not printable characters */
    public int f1434;

    /* renamed from: ʼᐧ, reason: contains not printable characters */
    public int f1435;

    /* renamed from: ʽʽ, reason: contains not printable characters */
    public int f1436;

    /* renamed from: ʽﹳ, reason: contains not printable characters */
    public boolean f1437;

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public final p179.C2697 f1438;

    /* renamed from: ʾᵎ, reason: contains not printable characters */
    public int f1439;

    /* renamed from: ˈٴ, reason: contains not printable characters */
    public final int[] f1440;

    /* renamed from: ˏי, reason: contains not printable characters */
    public final boolean f1441;

    /* renamed from: יـ, reason: contains not printable characters */
    public boolean f1442;

    /* renamed from: ـˆ, reason: contains not printable characters */
    public final boolean f1443;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public final p179.C2732 f1444;

    /* renamed from: ᵔﹳ, reason: contains not printable characters */
    public p179.C2717 f1445;

    /* renamed from: ᵢˏ, reason: contains not printable characters */
    public p179.C2735 f1446;

    /* renamed from: ﹳᐧ, reason: contains not printable characters */
    public p035.AbstractC1237 f1447;

    public LinearLayoutManager(int i) {
        this.f1435 = 1;
        this.f1441 = false;
        this.f1437 = false;
        this.f1433 = false;
        this.f1443 = true;
        this.f1439 = -1;
        this.f1434 = Integer.MIN_VALUE;
        this.f1446 = null;
        this.f1438 = new p179.C2697();
        this.f1444 = new p179.C2732();
        this.f1436 = 2;
        this.f1440 = new int[2];
        m892(i);
        mo887(null);
        if (this.f1441) {
            this.f1441 = false;
            m5982();
        }
    }

    @android.annotation.SuppressLint({"UnknownNullness"})
    public LinearLayoutManager(android.content.Context context, android.util.AttributeSet attributeSet, int i, int i2) {
        this.f1435 = 1;
        this.f1441 = false;
        this.f1437 = false;
        this.f1433 = false;
        this.f1443 = true;
        this.f1439 = -1;
        this.f1434 = Integer.MIN_VALUE;
        this.f1446 = null;
        this.f1438 = new p179.C2697();
        this.f1444 = new p179.C2732();
        this.f1436 = 2;
        this.f1440 = new int[2];
        p179.C2725 c2725M5967 = p179.AbstractC2669.m5967(context, attributeSet, i, i2);
        m892(c2725M5967.f10386);
        boolean z = c2725M5967.f10383;
        mo887(null);
        if (z != this.f1441) {
            this.f1441 = z;
            m5982();
        }
        mo876(c2725M5967.f10384);
    }

    /* renamed from: ʻʼ, reason: contains not printable characters */
    public final void m885(p179.C2666 c2666, p179.C2717 c2717) {
        if (!c2717.f10339 || c2717.f10340) {
            return;
        }
        int i = c2717.f10336;
        int i2 = c2717.f10330;
        if (c2717.f10341 == -1) {
            int iM5974 = m5974();
            if (i < 0) {
                return;
            }
            int iMo3828 = (this.f1447.mo3828() - i) + i2;
            if (this.f1437) {
                for (int i3 = 0; i3 < iM5974; i3++) {
                    android.view.View viewM5981 = m5981(i3);
                    if (this.f1447.mo3826(viewM5981) < iMo3828 || this.f1447.mo3819(viewM5981) < iMo3828) {
                        m915(c2666, 0, i3);
                        return;
                    }
                }
                return;
            }
            int i4 = iM5974 - 1;
            for (int i5 = i4; i5 >= 0; i5--) {
                android.view.View viewM59812 = m5981(i5);
                if (this.f1447.mo3826(viewM59812) < iMo3828 || this.f1447.mo3819(viewM59812) < iMo3828) {
                    m915(c2666, i4, i5);
                    return;
                }
            }
            return;
        }
        if (i < 0) {
            return;
        }
        int i6 = i - i2;
        int iM59742 = m5974();
        if (!this.f1437) {
            for (int i7 = 0; i7 < iM59742; i7++) {
                android.view.View viewM59813 = m5981(i7);
                if (this.f1447.mo3821(viewM59813) > i6 || this.f1447.mo3823(viewM59813) > i6) {
                    m915(c2666, 0, i7);
                    return;
                }
            }
            return;
        }
        int i8 = iM59742 - 1;
        for (int i9 = i8; i9 >= 0; i9--) {
            android.view.View viewM59814 = m5981(i9);
            if (this.f1447.mo3821(viewM59814) > i6 || this.f1447.mo3823(viewM59814) > i6) {
                m915(c2666, i8, i9);
                return;
            }
        }
    }

    @Override // p179.AbstractC2669
    /* renamed from: ʼˈ, reason: contains not printable characters */
    public final boolean mo886() {
        return this.f1441;
    }

    @Override // p179.AbstractC2669
    /* renamed from: ʼˎ */
    public final void mo470(int i, int i2, p179.C2723 c2723, p179.C2676 c2676) {
        if (this.f1435 != 0) {
            i = i2;
        }
        if (m5974() == 0 || i == 0) {
            return;
        }
        m918();
        m909(i > 0 ? 1 : -1, java.lang.Math.abs(i), true, c2723);
        mo874(c2723, this.f1445, c2676);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ʼᐧ */
    public int mo859(p179.C2723 c2723) {
        return m914(c2723);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ʽ, reason: contains not printable characters */
    public final void mo887(java.lang.String str) {
        if (this.f1446 == null) {
            super.mo887(str);
        }
    }

    /* renamed from: ʽʾ, reason: contains not printable characters */
    public final int m888(int i, p179.C2666 c2666, p179.C2723 c2723, boolean z) {
        int iMo3818;
        int iMo38182 = this.f1447.mo3818() - i;
        if (iMo38182 <= 0) {
            return 0;
        }
        int i2 = -m890(-iMo38182, c2666, c2723);
        int i3 = i + i2;
        if (!z || (iMo3818 = this.f1447.mo3818() - i3) <= 0) {
            return i2;
        }
        this.f1447.mo3829(iMo3818);
        return iMo3818 + i2;
    }

    /* renamed from: ʿʽ, reason: contains not printable characters */
    public final boolean m889() {
        return this.f10154.getLayoutDirection() == 1;
    }

    @Override // p179.AbstractC2669
    /* renamed from: ʿـ */
    public int mo481(int i, p179.C2666 c2666, p179.C2723 c2723) {
        if (this.f1435 == 1) {
            return 0;
        }
        return m890(i, c2666, c2723);
    }

    /* renamed from: ˆʻ, reason: contains not printable characters */
    public final int m890(int i, p179.C2666 c2666, p179.C2723 c2723) {
        if (m5974() != 0 && i != 0) {
            m918();
            this.f1445.f10339 = true;
            int i2 = i > 0 ? 1 : -1;
            int iAbs = java.lang.Math.abs(i);
            m909(i2, iAbs, true, c2723);
            p179.C2717 c2717 = this.f1445;
            int iM912 = m912(c2666, c2717, c2723, false) + c2717.f10336;
            if (iM912 >= 0) {
                if (iAbs > iM912) {
                    i = i2 * iM912;
                }
                this.f1447.mo3829(-i);
                this.f1445.f10332 = i;
                return i;
            }
        }
        return 0;
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˆʾ */
    public final void mo483(int i, p179.C2676 c2676) {
        boolean z;
        int i2;
        p179.C2735 c2735 = this.f1446;
        if (c2735 == null || (i2 = c2735.f10446) < 0) {
            m919();
            z = this.f1437;
            i2 = this.f1439;
            if (i2 == -1) {
                i2 = z ? i - 1 : 0;
            }
        } else {
            z = c2735.f10445;
        }
        int i3 = z ? -1 : 1;
        for (int i4 = 0; i4 < this.f1436 && i2 >= 0 && i2 < i; i4++) {
            c2676.m6025(i2, 0);
            i2 += i3;
        }
    }

    /* renamed from: ˆˎ */
    public void mo863(p179.C2666 c2666, p179.C2723 c2723, p179.C2697 c2697, int i) {
    }

    /* renamed from: ˆˑ, reason: contains not printable characters */
    public final int m891(int i, p179.C2666 c2666, p179.C2723 c2723, boolean z) {
        int iMo3822;
        int iMo38222 = i - this.f1447.mo3822();
        if (iMo38222 <= 0) {
            return 0;
        }
        int i2 = -m890(iMo38222, c2666, c2723);
        int i3 = i + i2;
        if (!z || (iMo3822 = i3 - this.f1447.mo3822()) <= 0) {
            return i2;
        }
        this.f1447.mo3829(-iMo3822);
        return i2 - iMo3822;
    }

    /* renamed from: ˆﹳ */
    public void mo864(p179.C2666 c2666, p179.C2723 c2723, p179.C2717 c2717, p179.C2732 c2732) {
        int iM5984;
        int i;
        int i2;
        int iMo3831;
        android.view.View viewM6098 = c2717.m6098(c2666);
        if (viewM6098 == null) {
            c2732.f10429 = true;
            return;
        }
        p179.C2700 c2700 = (p179.C2700) viewM6098.getLayoutParams();
        if (c2717.f10335 == null) {
            if (this.f1437 == (c2717.f10341 == -1)) {
                m5992(-1, viewM6098, false);
            } else {
                m5992(0, viewM6098, false);
            }
        } else {
            if (this.f1437 == (c2717.f10341 == -1)) {
                m5992(-1, viewM6098, true);
            } else {
                m5992(0, viewM6098, true);
            }
        }
        p179.C2700 c27002 = (p179.C2700) viewM6098.getLayoutParams();
        android.graphics.Rect rectM947 = this.f10154.m947(viewM6098);
        int i3 = rectM947.left + rectM947.right;
        int i4 = rectM947.top + rectM947.bottom;
        int iM5962 = p179.AbstractC2669.m5962(mo506(), this.f10152, this.f10156, m5987() + m5984() + ((android.view.ViewGroup.MarginLayoutParams) c27002).leftMargin + ((android.view.ViewGroup.MarginLayoutParams) c27002).rightMargin + i3, ((android.view.ViewGroup.MarginLayoutParams) c27002).width);
        int iM59622 = p179.AbstractC2669.m5962(mo538(), this.f10148, this.f10147, m5988() + m5989() + ((android.view.ViewGroup.MarginLayoutParams) c27002).topMargin + ((android.view.ViewGroup.MarginLayoutParams) c27002).bottomMargin + i4, ((android.view.ViewGroup.MarginLayoutParams) c27002).height);
        if (m5972(viewM6098, iM5962, iM59622, c27002)) {
            viewM6098.measure(iM5962, iM59622);
        }
        c2732.f10430 = this.f1447.mo3824(viewM6098);
        if (this.f1435 == 1) {
            if (m889()) {
                iMo3831 = this.f10152 - m5987();
                iM5984 = iMo3831 - this.f1447.mo3831(viewM6098);
            } else {
                iM5984 = m5984();
                iMo3831 = this.f1447.mo3831(viewM6098) + iM5984;
            }
            if (c2717.f10341 == -1) {
                i = c2717.f10338;
                i2 = i - c2732.f10430;
            } else {
                i2 = c2717.f10338;
                i = c2732.f10430 + i2;
            }
        } else {
            int iM5989 = m5989();
            int iMo38312 = this.f1447.mo3831(viewM6098) + iM5989;
            if (c2717.f10341 == -1) {
                int i5 = c2717.f10338;
                int i6 = i5 - c2732.f10430;
                iMo3831 = i5;
                i = iMo38312;
                iM5984 = i6;
                i2 = iM5989;
            } else {
                int i7 = c2717.f10338;
                int i8 = c2732.f10430 + i7;
                iM5984 = i7;
                i = iMo38312;
                i2 = iM5989;
                iMo3831 = i8;
            }
        }
        p179.AbstractC2669.m5969(viewM6098, iM5984, i2, iMo3831, i);
        if (c2700.f10283.m6007() || c2700.f10283.m6009()) {
            c2732.f10427 = true;
        }
        c2732.f10428 = viewM6098.hasFocusable();
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˈـ */
    public boolean mo865() {
        return this.f1446 == null && this.f1442 == this.f1433;
    }

    /* renamed from: ˉʽ, reason: contains not printable characters */
    public final void m892(int i) {
        if (i != 0 && i != 1) {
            throw new java.lang.IllegalArgumentException(p307.AbstractC3740.m7932(i, "invalid orientation:"));
        }
        mo887(null);
        if (i != this.f1435 || this.f1447 == null) {
            p035.AbstractC1237 abstractC1237M3817 = p035.AbstractC1237.m3817(this, i);
            this.f1447 = abstractC1237M3817;
            this.f1438.f10275 = abstractC1237M3817;
            this.f1435 = i;
            m5982();
        }
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˉʿ */
    public int mo866(p179.C2723 c2723) {
        return m914(c2723);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˉˆ */
    public int mo867(p179.C2723 c2723) {
        return m917(c2723);
    }

    /* renamed from: ˊˊ, reason: contains not printable characters */
    public final int m893() {
        android.view.View viewM902 = m902(0, m5974(), false);
        if (viewM902 == null) {
            return -1;
        }
        return p179.AbstractC2669.m5963(viewM902);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˊˋ, reason: contains not printable characters */
    public final boolean mo894() {
        return true;
    }

    /* JADX WARN: Removed duplicated region for block: B:33:0x0075  */
    /* JADX WARN: Removed duplicated region for block: B:35:0x0079  */
    /* renamed from: ˊﹳ */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct add '--show-bad-code' argument
    */
    public android.view.View mo869(p179.C2666 r17, p179.C2723 r18, boolean r19, boolean r20) {
        /*
            r16 = this;
            r0 = r16
            r0.m918()
            int r1 = r0.m5974()
            r2 = 0
            r3 = 1
            if (r20 == 0) goto L15
            int r1 = r0.m5974()
            int r1 = r1 - r3
            r4 = -1
            r5 = r4
            goto L18
        L15:
            r4 = r1
            r1 = r2
            r5 = r3
        L18:
            int r6 = r18.m6109()
            ʼﾞ.ᵎⁱ r7 = r0.f1447
            int r7 = r7.mo3822()
            ʼﾞ.ᵎⁱ r8 = r0.f1447
            int r8 = r8.mo3818()
            r9 = 0
            r10 = r9
            r11 = r10
        L2b:
            if (r1 == r4) goto L7c
            android.view.View r12 = r0.m5981(r1)
            int r13 = p179.AbstractC2669.m5963(r12)
            ʼﾞ.ᵎⁱ r14 = r0.f1447
            int r14 = r14.mo3826(r12)
            ʼﾞ.ᵎⁱ r15 = r0.f1447
            int r15 = r15.mo3821(r12)
            if (r13 < 0) goto L7a
            if (r13 >= r6) goto L7a
            android.view.ViewGroup$LayoutParams r13 = r12.getLayoutParams()
            ˋˋ.ˊᵔ r13 = (p179.C2700) r13
            ˋˋ.ʼـ r13 = r13.f10283
            boolean r13 = r13.m6007()
            if (r13 == 0) goto L57
            if (r11 != 0) goto L7a
            r11 = r12
            goto L7a
        L57:
            if (r15 > r7) goto L5d
            if (r14 >= r7) goto L5d
            r13 = r3
            goto L5e
        L5d:
            r13 = r2
        L5e:
            if (r14 < r8) goto L64
            if (r15 <= r8) goto L64
            r14 = r3
            goto L65
        L64:
            r14 = r2
        L65:
            if (r13 != 0) goto L6b
            if (r14 == 0) goto L6a
            goto L6b
        L6a:
            return r12
        L6b:
            if (r19 == 0) goto L73
            if (r14 == 0) goto L70
            goto L75
        L70:
            if (r9 != 0) goto L7a
            goto L79
        L73:
            if (r13 == 0) goto L77
        L75:
            r10 = r12
            goto L7a
        L77:
            if (r9 != 0) goto L7a
        L79:
            r9 = r12
        L7a:
            int r1 = r1 + r5
            goto L2b
        L7c:
            if (r9 == 0) goto L7f
            return r9
        L7f:
            if (r10 == 0) goto L82
            return r10
        L82:
            return r11
        */
        throw new UnsupportedOperationException("Method not decompiled: androidx.recyclerview.widget.LinearLayoutManager.mo869(ˋˋ.ʻˋ, ˋˋ.ᐧﹶ, boolean, boolean):android.view.View");
    }

    /* renamed from: ˊﾞ, reason: contains not printable characters */
    public final int m895() {
        android.view.View viewM902 = m902(m5974() - 1, -1, false);
        if (viewM902 == null) {
            return -1;
        }
        return p179.AbstractC2669.m5963(viewM902);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˋˊ, reason: contains not printable characters */
    public final boolean mo896() {
        if (this.f10147 != 1073741824 && this.f10156 != 1073741824) {
            int iM5974 = m5974();
            for (int i = 0; i < iM5974; i++) {
                android.view.ViewGroup.LayoutParams layoutParams = m5981(i).getLayoutParams();
                if (layoutParams.width < 0 && layoutParams.height < 0) {
                    return true;
                }
            }
        }
        return false;
    }

    /* renamed from: ˋـ, reason: contains not printable characters */
    public final int m897(int i) {
        return i != 1 ? i != 2 ? i != 17 ? i != 33 ? i != 66 ? (i == 130 && this.f1435 == 1) ? 1 : Integer.MIN_VALUE : this.f1435 == 0 ? 1 : Integer.MIN_VALUE : this.f1435 == 1 ? -1 : Integer.MIN_VALUE : this.f1435 == 0 ? -1 : Integer.MIN_VALUE : (this.f1435 != 1 && m889()) ? -1 : 1 : (this.f1435 != 1 && m889()) ? 1 : -1;
    }

    /* renamed from: ˎʼ, reason: contains not printable characters */
    public final void m898(int i, int i2) {
        this.f1445.f10331 = i2 - this.f1447.mo3822();
        p179.C2717 c2717 = this.f1445;
        c2717.f10333 = i;
        c2717.f10334 = this.f1437 ? 1 : -1;
        c2717.f10341 = -1;
        c2717.f10338 = i2;
        c2717.f10336 = Integer.MIN_VALUE;
    }

    /* renamed from: ˎʾ, reason: contains not printable characters */
    public void mo899(p179.C2723 c2723, int[] iArr) {
        int i;
        int iMo3827 = c2723.f10380 != -1 ? this.f1447.mo3827() : 0;
        if (this.f1445.f10341 == -1) {
            i = 0;
        } else {
            i = iMo3827;
            iMo3827 = 0;
        }
        iArr[0] = iMo3827;
        iArr[1] = i;
    }

    /* renamed from: ˎˉ, reason: contains not printable characters */
    public final int m900(p179.C2723 c2723) {
        if (m5974() == 0) {
            return 0;
        }
        m918();
        p035.AbstractC1237 abstractC1237 = this.f1447;
        boolean z = !this.f1443;
        return p179.AbstractC2741.m6141(c2723, abstractC1237, m920(z), m906(z), this, this.f1443);
    }

    /* renamed from: ˎـ, reason: contains not printable characters */
    public final android.view.View m901() {
        return m5981(this.f1437 ? 0 : m5974() - 1);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˏי */
    public p179.C2700 mo502() {
        return new p179.C2700(-2, -2);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˏᵢ */
    public void mo503(p179.C2666 c2666, p179.C2723 c2723, p158.C2535 c2535) {
        super.mo503(c2666, c2723, c2535);
        p179.AbstractC2727 abstractC2727 = this.f10154.f1474;
        if (abstractC2727 == null || abstractC2727.mo611() <= 0) {
            return;
        }
        c2535.m5675(p158.C2526.f9617);
    }

    /* renamed from: ˏⁱ, reason: contains not printable characters */
    public final android.view.View m902(int i, int i2, boolean z) {
        m918();
        int i3 = z ? 24579 : 320;
        return this.f1435 == 0 ? this.f10144.ˉˆ(i, i2, i3, 320) : this.f10146.ˉˆ(i, i2, i3, 320);
    }

    /* JADX WARN: Removed duplicated region for block: B:19:0x0048  */
    @Override // p179.AbstractC2669
    /* renamed from: ˑ */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct add '--show-bad-code' argument
    */
    public boolean mo872(int r5, android.os.Bundle r6) {
        /*
            r4 = this;
            boolean r0 = super.mo872(r5, r6)
            r1 = 1
            if (r0 == 0) goto L8
            return r1
        L8:
            r0 = 16908343(0x1020037, float:2.3877383E-38)
            r2 = 0
            if (r5 != r0) goto L56
            if (r6 == 0) goto L56
            int r5 = r4.f1435
            r0 = -1
            if (r5 != r1) goto L2e
            java.lang.String r5 = "android.view.accessibility.action.ARGUMENT_ROW_INT"
            int r5 = r6.getInt(r5, r0)
            if (r5 >= 0) goto L1e
            goto L56
        L1e:
            androidx.recyclerview.widget.RecyclerView r6 = r4.f10154
            ˋˋ.ʻˋ r3 = r6.f1464
            ˋˋ.ᐧﹶ r6 = r6.f1516
            int r6 = r4.mo487(r3, r6)
            int r6 = r6 - r1
            int r5 = java.lang.Math.min(r5, r6)
            goto L46
        L2e:
            java.lang.String r5 = "android.view.accessibility.action.ARGUMENT_COLUMN_INT"
            int r5 = r6.getInt(r5, r0)
            if (r5 >= 0) goto L37
            goto L56
        L37:
            androidx.recyclerview.widget.RecyclerView r6 = r4.f10154
            ˋˋ.ʻˋ r3 = r6.f1464
            ˋˋ.ᐧﹶ r6 = r6.f1516
            int r6 = r4.mo527(r3, r6)
            int r6 = r6 - r1
            int r5 = java.lang.Math.min(r5, r6)
        L46:
            if (r5 < 0) goto L56
            r4.f1439 = r5
            r4.f1434 = r2
            ˋˋ.ᵔי r5 = r4.f1446
            if (r5 == 0) goto L52
            r5.f10446 = r0
        L52:
            r4.m5982()
            return r1
        L56:
            return r2
        */
        throw new UnsupportedOperationException("Method not decompiled: androidx.recyclerview.widget.LinearLayoutManager.mo872(int, android.os.Bundle):boolean");
    }

    /* renamed from: ˑˆ */
    public void mo874(p179.C2723 c2723, p179.C2717 c2717, p179.C2676 c2676) {
        int i = c2717.f10333;
        if (i < 0 || i >= c2723.m6109()) {
            return;
        }
        c2676.m6025(i, java.lang.Math.max(0, c2717.f10336));
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˑﹳ */
    public final boolean mo506() {
        return this.f1435 == 0;
    }

    /* renamed from: ˑﹶ, reason: contains not printable characters */
    public final void m903(int i, int i2) {
        this.f1445.f10331 = this.f1447.mo3818() - i2;
        p179.C2717 c2717 = this.f1445;
        c2717.f10334 = this.f1437 ? -1 : 1;
        c2717.f10333 = i;
        c2717.f10341 = 1;
        c2717.f10338 = i2;
        c2717.f10336 = Integer.MIN_VALUE;
    }

    @Override // p179.AbstractC2669
    /* renamed from: י */
    public final android.os.Parcelable mo508() {
        p179.C2735 c2735 = this.f1446;
        if (c2735 != null) {
            p179.C2735 c27352 = new p179.C2735();
            c27352.f10446 = c2735.f10446;
            c27352.f10447 = c2735.f10447;
            c27352.f10445 = c2735.f10445;
            return c27352;
        }
        p179.C2735 c27353 = new p179.C2735();
        if (m5974() <= 0) {
            c27353.f10446 = -1;
            return c27353;
        }
        m918();
        boolean z = this.f1442 ^ this.f1437;
        c27353.f10445 = z;
        if (z) {
            android.view.View viewM901 = m901();
            c27353.f10447 = this.f1447.mo3818() - this.f1447.mo3821(viewM901);
            c27353.f10446 = p179.AbstractC2669.m5963(viewM901);
            return c27353;
        }
        android.view.View viewM913 = m913();
        c27353.f10446 = p179.AbstractC2669.m5963(viewM913);
        c27353.f10447 = this.f1447.mo3826(viewM913) - this.f1447.mo3822();
        return c27353;
    }

    /* renamed from: יʿ */
    public void mo876(boolean z) {
        mo887(null);
        if (this.f1433 == z) {
            return;
        }
        this.f1433 = z;
        m5982();
    }

    @Override // p179.AbstractC2669
    /* renamed from: יˉ */
    public void mo510(androidx.recyclerview.widget.RecyclerView recyclerView, int i) {
        p179.C2688 c2688 = new p179.C2688(recyclerView.getContext());
        c2688.f10247 = i;
        mo536(c2688);
    }

    @Override // p179.AbstractC2669
    /* renamed from: יـ, reason: contains not printable characters */
    public final android.view.View mo904(int i) {
        int iM5974 = m5974();
        if (iM5974 == 0) {
            return null;
        }
        int iM5963 = i - p179.AbstractC2669.m5963(m5981(0));
        if (iM5963 >= 0 && iM5963 < iM5974) {
            android.view.View viewM5981 = m5981(iM5963);
            if (p179.AbstractC2669.m5963(viewM5981) == i) {
                return viewM5981;
            }
        }
        return super.mo904(i);
    }

    /* renamed from: ـʻ, reason: contains not printable characters */
    public final android.view.View m905(int i, int i2) {
        int i3;
        int i4;
        m918();
        if (i2 <= i && i2 >= i) {
            return m5981(i);
        }
        if (this.f1447.mo3826(m5981(i)) < this.f1447.mo3822()) {
            i3 = 16644;
            i4 = 16388;
        } else {
            i3 = 4161;
            i4 = 4097;
        }
        return this.f1435 == 0 ? this.f10144.ˉˆ(i, i2, i3, i4) : this.f10146.ˉˆ(i, i2, i3, i4);
    }

    /* renamed from: ٴʿ, reason: contains not printable characters */
    public final android.view.View m906(boolean z) {
        return this.f1437 ? m902(0, m5974(), z) : m902(m5974() - 1, -1, z);
    }

    /* JADX WARN: Removed duplicated region for block: B:111:0x01d9  */
    /* JADX WARN: Removed duplicated region for block: B:135:0x022b  */
    /* JADX WARN: Removed duplicated region for block: B:95:0x0194  */
    @Override // p179.AbstractC2669
    /* renamed from: ٴﹳ */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct add '--show-bad-code' argument
    */
    public void mo517(p179.C2666 r18, p179.C2723 r19) {
        /*
            Method dump skipped, instructions count: 1085
            To view this dump add '--comments-level debug' option
        */
        throw new UnsupportedOperationException("Method not decompiled: androidx.recyclerview.widget.LinearLayoutManager.mo517(ˋˋ.ʻˋ, ˋˋ.ᐧﹶ):void");
    }

    @Override // p179.AbstractC2669
    /* renamed from: ٴﹶ, reason: contains not printable characters */
    public final int mo907(p179.C2723 c2723) {
        return m900(c2723);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ᐧᴵ, reason: contains not printable characters */
    public final void mo908(android.view.accessibility.AccessibilityEvent accessibilityEvent) {
        super.mo908(accessibilityEvent);
        if (m5974() > 0) {
            accessibilityEvent.setFromIndex(m893());
            accessibilityEvent.setToIndex(m895());
        }
    }

    @Override // p179.AbstractC2669
    /* renamed from: ᐧﹶ */
    public final void mo520(android.os.Parcelable parcelable) {
        if (parcelable instanceof p179.C2735) {
            p179.C2735 c2735 = (p179.C2735) parcelable;
            this.f1446 = c2735;
            if (this.f1439 != -1) {
                c2735.f10446 = -1;
            }
            m5982();
        }
    }

    @Override // p179.AbstractC2669
    /* renamed from: ᐧﾞ */
    public android.view.View mo881(android.view.View view, int i, p179.C2666 c2666, p179.C2723 c2723) {
        int iM897;
        m919();
        if (m5974() != 0 && (iM897 = m897(i)) != Integer.MIN_VALUE) {
            m918();
            m909(iM897, (int) (this.f1447.mo3827() * 0.33333334f), false, c2723);
            p179.C2717 c2717 = this.f1445;
            c2717.f10336 = Integer.MIN_VALUE;
            c2717.f10339 = false;
            m912(c2666, c2717, c2723, true);
            android.view.View viewM905 = iM897 == -1 ? this.f1437 ? m905(m5974() - 1, -1) : m905(0, m5974()) : this.f1437 ? m905(0, m5974()) : m905(m5974() - 1, -1);
            android.view.View viewM913 = iM897 == -1 ? m913() : m901();
            if (!viewM913.hasFocusable()) {
                return viewM905;
            }
            if (viewM905 != null) {
                return viewM913;
            }
        }
        return null;
    }

    /* renamed from: ᴵٴ, reason: contains not printable characters */
    public final void m909(int i, int i2, boolean z, p179.C2723 c2723) {
        int iMo3822;
        this.f1445.f10340 = this.f1447.mo3825() == 0 && this.f1447.mo3828() == 0;
        this.f1445.f10341 = i;
        int[] iArr = this.f1440;
        iArr[0] = 0;
        iArr[1] = 0;
        mo899(c2723, iArr);
        int iMax = java.lang.Math.max(0, iArr[0]);
        int iMax2 = java.lang.Math.max(0, iArr[1]);
        boolean z2 = i == 1;
        p179.C2717 c2717 = this.f1445;
        int i3 = z2 ? iMax2 : iMax;
        c2717.f10337 = i3;
        if (!z2) {
            iMax = iMax2;
        }
        c2717.f10330 = iMax;
        if (z2) {
            c2717.f10337 = this.f1447.mo3820() + i3;
            android.view.View viewM901 = m901();
            p179.C2717 c27172 = this.f1445;
            c27172.f10334 = this.f1437 ? -1 : 1;
            int iM5963 = p179.AbstractC2669.m5963(viewM901);
            p179.C2717 c27173 = this.f1445;
            c27172.f10333 = iM5963 + c27173.f10334;
            c27173.f10338 = this.f1447.mo3821(viewM901);
            iMo3822 = this.f1447.mo3821(viewM901) - this.f1447.mo3818();
        } else {
            android.view.View viewM913 = m913();
            p179.C2717 c27174 = this.f1445;
            c27174.f10337 = this.f1447.mo3822() + c27174.f10337;
            p179.C2717 c27175 = this.f1445;
            c27175.f10334 = this.f1437 ? 1 : -1;
            int iM59632 = p179.AbstractC2669.m5963(viewM913);
            p179.C2717 c27176 = this.f1445;
            c27175.f10333 = iM59632 + c27176.f10334;
            c27176.f10338 = this.f1447.mo3826(viewM913);
            iMo3822 = (-this.f1447.mo3826(viewM913)) + this.f1447.mo3822();
        }
        p179.C2717 c27177 = this.f1445;
        c27177.f10331 = i2;
        if (z) {
            c27177.f10331 = i2 - iMo3822;
        }
        c27177.f10336 = iMo3822;
    }

    @Override // p179.AbstractC2669
    /* renamed from: ᵎʻ */
    public void mo523(p179.C2723 c2723) {
        this.f1446 = null;
        this.f1439 = -1;
        this.f1434 = Integer.MIN_VALUE;
        this.f1438.m6066();
    }

    @Override // p179.AbstractC2669
    /* renamed from: ᵎᵔ, reason: contains not printable characters */
    public final void mo910(androidx.recyclerview.widget.RecyclerView recyclerView) {
    }

    @Override // p179.AbstractC2669
    /* renamed from: ᵔʾ, reason: contains not printable characters */
    public final int mo911(p179.C2723 c2723) {
        return m900(c2723);
    }

    /* renamed from: ᵔⁱ, reason: contains not printable characters */
    public final int m912(p179.C2666 c2666, p179.C2717 c2717, p179.C2723 c2723, boolean z) {
        int i;
        int i2 = c2717.f10331;
        int i3 = c2717.f10336;
        if (i3 != Integer.MIN_VALUE) {
            if (i2 < 0) {
                c2717.f10336 = i3 + i2;
            }
            m885(c2666, c2717);
        }
        int i4 = c2717.f10331 + c2717.f10337;
        while (true) {
            if ((!c2717.f10340 && i4 <= 0) || (i = c2717.f10333) < 0 || i >= c2723.m6109()) {
                break;
            }
            p179.C2732 c2732 = this.f1444;
            c2732.f10430 = 0;
            c2732.f10429 = false;
            c2732.f10427 = false;
            c2732.f10428 = false;
            mo864(c2666, c2723, c2717, c2732);
            if (!c2732.f10429) {
                int i5 = c2717.f10338;
                int i6 = c2732.f10430;
                c2717.f10338 = (c2717.f10341 * i6) + i5;
                if (!c2732.f10427 || c2717.f10335 != null || !c2723.f10376) {
                    c2717.f10331 -= i6;
                    i4 -= i6;
                }
                int i7 = c2717.f10336;
                if (i7 != Integer.MIN_VALUE) {
                    int i8 = i7 + i6;
                    c2717.f10336 = i8;
                    int i9 = c2717.f10331;
                    if (i9 < 0) {
                        c2717.f10336 = i8 + i9;
                    }
                    m885(c2666, c2717);
                }
                if (z && c2732.f10428) {
                    break;
                }
            } else {
                break;
            }
        }
        return i2 - c2717.f10331;
    }

    /* renamed from: ᵢʻ, reason: contains not printable characters */
    public final android.view.View m913() {
        return m5981(this.f1437 ? m5974() - 1 : 0);
    }

    /* renamed from: ᵢˋ, reason: contains not printable characters */
    public final int m914(p179.C2723 c2723) {
        if (m5974() == 0) {
            return 0;
        }
        m918();
        p035.AbstractC1237 abstractC1237 = this.f1447;
        boolean z = !this.f1443;
        return p179.AbstractC2741.m6140(c2723, abstractC1237, m920(z), m906(z), this, this.f1443);
    }

    /* renamed from: ᵢᐧ, reason: contains not printable characters */
    public final void m915(p179.C2666 c2666, int i, int i2) {
        if (i == i2) {
            return;
        }
        if (i2 <= i) {
            while (i > i2) {
                m5975(i, c2666);
                i--;
            }
        } else {
            for (int i3 = i2 - 1; i3 >= i; i3--) {
                m5975(i3, c2666);
            }
        }
    }

    @Override // p179.AbstractC2669
    /* renamed from: ⁱי */
    public int mo530(int i, p179.C2666 c2666, p179.C2723 c2723) {
        if (this.f1435 == 0) {
            return 0;
        }
        return m890(i, c2666, c2723);
    }

    @Override // p179.InterfaceC2677
    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final android.graphics.PointF mo916(int i) {
        if (m5974() == 0) {
            return null;
        }
        int i2 = (i < p179.AbstractC2669.m5963(m5981(0))) != this.f1437 ? -1 : 1;
        return this.f1435 == 0 ? new android.graphics.PointF(i2, 0.0f) : new android.graphics.PointF(0.0f, i2);
    }

    /* renamed from: ﹳᵢ, reason: contains not printable characters */
    public final int m917(p179.C2723 c2723) {
        if (m5974() == 0) {
            return 0;
        }
        m918();
        p035.AbstractC1237 abstractC1237 = this.f1447;
        boolean z = !this.f1443;
        return p179.AbstractC2741.m6139(c2723, abstractC1237, m920(z), m906(z), this, this.f1443, this.f1437);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ﹳⁱ */
    public final void mo531(int i) {
        this.f1439 = i;
        this.f1434 = Integer.MIN_VALUE;
        p179.C2735 c2735 = this.f1446;
        if (c2735 != null) {
            c2735.f10446 = -1;
        }
        m5982();
    }

    /* renamed from: ﹶʽ, reason: contains not printable characters */
    public final void m918() {
        if (this.f1445 == null) {
            p179.C2717 c2717 = new p179.C2717();
            c2717.f10339 = true;
            c2717.f10337 = 0;
            c2717.f10330 = 0;
            c2717.f10335 = null;
            this.f1445 = c2717;
        }
    }

    @Override // p179.AbstractC2669
    /* renamed from: ﾞʻ */
    public int mo884(p179.C2723 c2723) {
        return m917(c2723);
    }

    /* renamed from: ﾞˊ, reason: contains not printable characters */
    public final void m919() {
        if (this.f1435 == 1 || !m889()) {
            this.f1437 = this.f1441;
        } else {
            this.f1437 = !this.f1441;
        }
    }

    /* renamed from: ﾞˏ, reason: contains not printable characters */
    public final android.view.View m920(boolean z) {
        return this.f1437 ? m902(m5974() - 1, -1, z) : m902(0, m5974(), z);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ﾞᴵ */
    public final boolean mo538() {
        return this.f1435 == 1;
    }
}
