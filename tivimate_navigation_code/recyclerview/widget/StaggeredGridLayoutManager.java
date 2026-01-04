package androidx.recyclerview.widget;

/* loaded from: classes.dex */
public class StaggeredGridLayoutManager extends p179.AbstractC2669 implements p179.InterfaceC2677 {

    /* renamed from: ʻٴ, reason: contains not printable characters */
    public final p179.C2718 f1534;

    /* renamed from: ʼʼ, reason: contains not printable characters */
    public final java.util.BitSet f1535;

    /* renamed from: ʼᐧ, reason: contains not printable characters */
    public final int f1536;

    /* renamed from: ʽʽ, reason: contains not printable characters */
    public final int f1537;

    /* renamed from: ʽﹳ, reason: contains not printable characters */
    public int f1538;

    /* renamed from: ˈٴ, reason: contains not printable characters */
    public boolean f1541;

    /* renamed from: ˉٴ, reason: contains not printable characters */
    public final p179.C2683 f1542;

    /* renamed from: ˊʻ, reason: contains not printable characters */
    public p179.C2668 f1543;

    /* renamed from: ˏי, reason: contains not printable characters */
    public final int f1544;

    /* renamed from: יـ, reason: contains not printable characters */
    public final p035.AbstractC1237 f1545;

    /* renamed from: ـˆ, reason: contains not printable characters */
    public boolean f1546;

    /* renamed from: ٴʼ, reason: contains not printable characters */
    public int[] f1547;

    /* renamed from: ٴᵢ, reason: contains not printable characters */
    public final android.graphics.Rect f1548;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public final p404.C4790 f1549;

    /* renamed from: ᴵᵔ, reason: contains not printable characters */
    public boolean f1550;

    /* renamed from: ᵎˊ, reason: contains not printable characters */
    public final androidx.leanback.widget.RunnableC0142 f1551;

    /* renamed from: ᵎⁱ, reason: contains not printable characters */
    public final boolean f1552;

    /* renamed from: ᵔﹳ, reason: contains not printable characters */
    public final p179.C2713[] f1553;

    /* renamed from: ﹳᐧ, reason: contains not printable characters */
    public final p035.AbstractC1237 f1555;

    /* renamed from: ʾᵎ, reason: contains not printable characters */
    public boolean f1540 = false;

    /* renamed from: ᵢˏ, reason: contains not printable characters */
    public int f1554 = -1;

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public int f1539 = Integer.MIN_VALUE;

    public StaggeredGridLayoutManager(android.content.Context context, android.util.AttributeSet attributeSet, int i, int i2) {
        this.f1536 = -1;
        this.f1546 = false;
        p404.C4790 c4790 = new p404.C4790(21, false);
        this.f1549 = c4790;
        this.f1537 = 2;
        this.f1548 = new android.graphics.Rect();
        this.f1542 = new p179.C2683(this);
        this.f1552 = true;
        this.f1551 = new androidx.leanback.widget.RunnableC0142(21, this);
        p179.C2725 c2725M5967 = p179.AbstractC2669.m5967(context, attributeSet, i, i2);
        int i3 = c2725M5967.f10386;
        if (i3 != 0 && i3 != 1) {
            throw new java.lang.IllegalArgumentException("invalid orientation.");
        }
        mo887(null);
        if (i3 != this.f1544) {
            this.f1544 = i3;
            p035.AbstractC1237 abstractC1237 = this.f1555;
            this.f1555 = this.f1545;
            this.f1545 = abstractC1237;
            m5982();
        }
        int i4 = c2725M5967.f10385;
        mo887(null);
        if (i4 != this.f1536) {
            c4790.m9569();
            m5982();
            this.f1536 = i4;
            this.f1535 = new java.util.BitSet(this.f1536);
            this.f1553 = new p179.C2713[this.f1536];
            for (int i5 = 0; i5 < this.f1536; i5++) {
                this.f1553[i5] = new p179.C2713(this, i5);
            }
            m5982();
        }
        boolean z = c2725M5967.f10383;
        mo887(null);
        p179.C2668 c2668 = this.f1543;
        if (c2668 != null && c2668.f10136 != z) {
            c2668.f10136 = z;
        }
        this.f1546 = z;
        m5982();
        p179.C2718 c2718 = new p179.C2718();
        c2718.f10349 = true;
        c2718.f10350 = 0;
        c2718.f10346 = 0;
        this.f1534 = c2718;
        this.f1555 = p035.AbstractC1237.m3817(this, this.f1544);
        this.f1545 = p035.AbstractC1237.m3817(this, 1 - this.f1544);
    }

    /* renamed from: ˉʽ, reason: contains not printable characters */
    public static int m988(int i, int i2, int i3) {
        int mode;
        return (!(i2 == 0 && i3 == 0) && ((mode = android.view.View.MeasureSpec.getMode(i)) == Integer.MIN_VALUE || mode == 1073741824)) ? android.view.View.MeasureSpec.makeMeasureSpec(java.lang.Math.max(0, (android.view.View.MeasureSpec.getSize(i) - i2) - i3), mode) : i;
    }

    /* renamed from: ʻʼ, reason: contains not printable characters */
    public final int m989(int i, p179.C2666 c2666, p179.C2723 c2723) {
        if (m5974() == 0 || i == 0) {
            return 0;
        }
        m1004(i, c2723);
        p179.C2718 c2718 = this.f1534;
        int iM1003 = m1003(c2666, c2718, c2723);
        if (c2718.f10348 >= iM1003) {
            i = i < 0 ? -iM1003 : iM1003;
        }
        this.f1555.mo3829(-i);
        this.f1541 = this.f1540;
        c2718.f10348 = 0;
        m1011(c2666, c2718);
        return i;
    }

    @Override // p179.AbstractC2669
    /* renamed from: ʻٴ */
    public final p179.C2700 mo468(android.view.ViewGroup.LayoutParams layoutParams) {
        return layoutParams instanceof android.view.ViewGroup.MarginLayoutParams ? new p179.C2740((android.view.ViewGroup.MarginLayoutParams) layoutParams) : new p179.C2740(layoutParams);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ʻᵎ */
    public final void mo469(p179.C2666 c2666, p179.C2723 c2723, android.view.View view, p158.C2535 c2535) {
        android.view.ViewGroup.LayoutParams layoutParams = view.getLayoutParams();
        if (!(layoutParams instanceof p179.C2740)) {
            m5985(view, c2535);
            return;
        }
        p179.C2740 c2740 = (p179.C2740) layoutParams;
        if (this.f1544 == 0) {
            p179.C2713 c2713 = c2740.f10459;
            c2535.m5678(p075.C1652.m4511(false, c2713 == null ? -1 : c2713.f10316, 1, -1, -1));
        } else {
            p179.C2713 c27132 = c2740.f10459;
            c2535.m5678(p075.C1652.m4511(false, -1, -1, c27132 == null ? -1 : c27132.f10316, 1));
        }
    }

    @Override // p179.AbstractC2669
    /* renamed from: ʼˈ */
    public final boolean mo886() {
        return this.f1546;
    }

    @Override // p179.AbstractC2669
    /* renamed from: ʼˎ */
    public final void mo470(int i, int i2, p179.C2723 c2723, p179.C2676 c2676) {
        p179.C2718 c2718;
        int iM6092;
        int iM6084;
        if (this.f1544 != 0) {
            i = i2;
        }
        if (m5974() == 0 || i == 0) {
            return;
        }
        m1004(i, c2723);
        int[] iArr = this.f1547;
        if (iArr == null || iArr.length < this.f1536) {
            this.f1547 = new int[this.f1536];
        }
        int i3 = 0;
        int i4 = 0;
        while (true) {
            int i5 = this.f1536;
            c2718 = this.f1534;
            if (i3 >= i5) {
                break;
            }
            if (c2718.f10344 == -1) {
                iM6092 = c2718.f10350;
                iM6084 = this.f1553[i3].m6084(iM6092);
            } else {
                iM6092 = this.f1553[i3].m6092(c2718.f10346);
                iM6084 = c2718.f10346;
            }
            int i6 = iM6092 - iM6084;
            if (i6 >= 0) {
                this.f1547[i4] = i6;
                i4++;
            }
            i3++;
        }
        java.util.Arrays.sort(this.f1547, 0, i4);
        for (int i7 = 0; i7 < i4; i7++) {
            int i8 = c2718.f10343;
            if (i8 < 0 || i8 >= c2723.m6109()) {
                return;
            }
            c2676.m6025(c2718.f10343, this.f1547[i7]);
            c2718.f10343 += c2718.f10344;
        }
    }

    @Override // p179.AbstractC2669
    /* renamed from: ʼᐧ */
    public final int mo859(p179.C2723 c2723) {
        if (m5974() == 0) {
            return 0;
        }
        boolean z = !this.f1552;
        return p179.AbstractC2741.m6140(c2723, this.f1555, m1012(z), m1014(z), this, this.f1552);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ʽ */
    public final void mo887(java.lang.String str) {
        if (this.f1543 == null) {
            super.mo887(str);
        }
    }

    /* JADX WARN: Removed duplicated region for block: B:108:0x01a8  */
    /* JADX WARN: Removed duplicated region for block: B:109:0x01aa  */
    /* JADX WARN: Removed duplicated region for block: B:123:0x01e1  */
    /* JADX WARN: Removed duplicated region for block: B:131:0x01fe  */
    /* JADX WARN: Removed duplicated region for block: B:254:0x0419  */
    /* renamed from: ʽʾ, reason: contains not printable characters */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct add '--show-bad-code' argument
    */
    public final void m990(p179.C2666 r17, p179.C2723 r18, boolean r19) {
        /*
            Method dump skipped, instructions count: 1076
            To view this dump add '--comments-level debug' option
        */
        throw new UnsupportedOperationException("Method not decompiled: androidx.recyclerview.widget.StaggeredGridLayoutManager.m990(ˋˋ.ʻˋ, ˋˋ.ᐧﹶ, boolean):void");
    }

    @Override // p179.AbstractC2669
    /* renamed from: ʽﹳ */
    public final p179.C2700 mo476(android.content.Context context, android.util.AttributeSet attributeSet) {
        return new p179.C2740(context, attributeSet);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ʾˊ, reason: contains not printable characters */
    public final void mo991(int i) {
        if (i == 0) {
            m1002();
        }
    }

    /* renamed from: ʿʽ, reason: contains not printable characters */
    public final void m992(int i, p179.C2666 c2666) {
        for (int iM5974 = m5974() - 1; iM5974 >= 0; iM5974--) {
            android.view.View viewM5981 = m5981(iM5974);
            if (this.f1555.mo3826(viewM5981) < i || this.f1555.mo3819(viewM5981) < i) {
                return;
            }
            p179.C2740 c2740 = (p179.C2740) viewM5981.getLayoutParams();
            c2740.getClass();
            if (((java.util.ArrayList) c2740.f10459.f10320).size() == 1) {
                return;
            }
            p179.C2713 c2713 = c2740.f10459;
            java.util.ArrayList arrayList = (java.util.ArrayList) c2713.f10320;
            int size = arrayList.size();
            android.view.View view = (android.view.View) arrayList.remove(size - 1);
            p179.C2740 c27402 = (p179.C2740) view.getLayoutParams();
            c27402.f10459 = null;
            if (c27402.f10283.m6007() || c27402.f10283.m6009()) {
                c2713.f10315 -= ((androidx.recyclerview.widget.StaggeredGridLayoutManager) c2713.f10317).f1555.mo3824(view);
            }
            if (size == 1) {
                c2713.f10318 = Integer.MIN_VALUE;
            }
            c2713.f10314 = Integer.MIN_VALUE;
            m5973(viewM5981, c2666);
        }
    }

    @Override // p179.AbstractC2669
    /* renamed from: ʿـ */
    public final int mo481(int i, p179.C2666 c2666, p179.C2723 c2723) {
        return m989(i, c2666, c2723);
    }

    /* renamed from: ˆʻ, reason: contains not printable characters */
    public final void m993(p179.C2713 c2713, int i, int i2) {
        int i3 = c2713.f10315;
        int i4 = c2713.f10316;
        if (i != -1) {
            int i5 = c2713.f10314;
            if (i5 == Integer.MIN_VALUE) {
                c2713.m6094();
                i5 = c2713.f10314;
            }
            if (i5 - i3 >= i2) {
                this.f1535.set(i4, false);
                return;
            }
            return;
        }
        int i6 = c2713.f10318;
        if (i6 == Integer.MIN_VALUE) {
            android.view.View view = (android.view.View) ((java.util.ArrayList) c2713.f10320).get(0);
            p179.C2740 c2740 = (p179.C2740) view.getLayoutParams();
            c2713.f10318 = ((androidx.recyclerview.widget.StaggeredGridLayoutManager) c2713.f10317).f1555.mo3826(view);
            c2740.getClass();
            i6 = c2713.f10318;
        }
        if (i6 + i3 <= i2) {
            this.f1535.set(i4, false);
        }
    }

    /* renamed from: ˆˎ, reason: contains not printable characters */
    public final void m994() {
        if (this.f1544 == 1 || !m1005()) {
            this.f1540 = this.f1546;
        } else {
            this.f1540 = !this.f1546;
        }
    }

    /* renamed from: ˆˑ, reason: contains not printable characters */
    public final boolean m995(int i) {
        if (this.f1544 == 0) {
            return (i == -1) != this.f1540;
        }
        return ((i == -1) == this.f1540) == m1005();
    }

    /* renamed from: ˆﹳ, reason: contains not printable characters */
    public final void m996(int i, p179.C2666 c2666) {
        while (m5974() > 0) {
            android.view.View viewM5981 = m5981(0);
            if (this.f1555.mo3821(viewM5981) > i || this.f1555.mo3823(viewM5981) > i) {
                return;
            }
            p179.C2740 c2740 = (p179.C2740) viewM5981.getLayoutParams();
            c2740.getClass();
            if (((java.util.ArrayList) c2740.f10459.f10320).size() == 1) {
                return;
            }
            p179.C2713 c2713 = c2740.f10459;
            java.util.ArrayList arrayList = (java.util.ArrayList) c2713.f10320;
            android.view.View view = (android.view.View) arrayList.remove(0);
            p179.C2740 c27402 = (p179.C2740) view.getLayoutParams();
            c27402.f10459 = null;
            if (arrayList.size() == 0) {
                c2713.f10314 = Integer.MIN_VALUE;
            }
            if (c27402.f10283.m6007() || c27402.f10283.m6009()) {
                c2713.f10315 -= ((androidx.recyclerview.widget.StaggeredGridLayoutManager) c2713.f10317).f1555.mo3824(view);
            }
            c2713.f10318 = Integer.MIN_VALUE;
            m5973(viewM5981, c2666);
        }
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˈʿ */
    public final int mo487(p179.C2666 c2666, p179.C2723 c2723) {
        if (this.f1544 == 0) {
            return java.lang.Math.min(this.f1536, c2723.m6109());
        }
        return -1;
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˈˏ */
    public final void mo488() {
        this.f1549.m9569();
        m5982();
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˈـ */
    public final boolean mo865() {
        return this.f1543 == null;
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˈⁱ, reason: contains not printable characters */
    public final void mo997(int i) {
        super.mo997(i);
        for (int i2 = 0; i2 < this.f1536; i2++) {
            p179.C2713 c2713 = this.f1553[i2];
            int i3 = c2713.f10318;
            if (i3 != Integer.MIN_VALUE) {
                c2713.f10318 = i3 + i;
            }
            int i4 = c2713.f10314;
            if (i4 != Integer.MIN_VALUE) {
                c2713.f10314 = i4 + i;
            }
        }
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˉʿ */
    public final int mo866(p179.C2723 c2723) {
        if (m5974() == 0) {
            return 0;
        }
        boolean z = !this.f1552;
        return p179.AbstractC2741.m6140(c2723, this.f1555, m1012(z), m1014(z), this, this.f1552);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˉˆ */
    public final int mo867(p179.C2723 c2723) {
        return m1006(c2723);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˉـ */
    public final void mo490(p179.AbstractC2727 abstractC2727) {
        this.f1549.m9569();
        for (int i = 0; i < this.f1536; i++) {
            this.f1553[i].m6093();
        }
    }

    /* renamed from: ˊˊ, reason: contains not printable characters */
    public final int m998(int i) {
        int iM6084 = this.f1553[0].m6084(i);
        for (int i2 = 1; i2 < this.f1536; i2++) {
            int iM60842 = this.f1553[i2].m6084(i);
            if (iM60842 < iM6084) {
                iM6084 = iM60842;
            }
        }
        return iM6084;
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˊˋ */
    public final boolean mo894() {
        return this.f1537 != 0;
    }

    /* renamed from: ˊﹳ, reason: contains not printable characters */
    public final void m999(android.view.View view, int i, int i2) {
        android.graphics.Rect rect = this.f1548;
        m5976(view, rect);
        p179.C2740 c2740 = (p179.C2740) view.getLayoutParams();
        int iM988 = m988(i, ((android.view.ViewGroup.MarginLayoutParams) c2740).leftMargin + rect.left, ((android.view.ViewGroup.MarginLayoutParams) c2740).rightMargin + rect.right);
        int iM9882 = m988(i2, ((android.view.ViewGroup.MarginLayoutParams) c2740).topMargin + rect.top, ((android.view.ViewGroup.MarginLayoutParams) c2740).bottomMargin + rect.bottom);
        if (m5972(view, iM988, iM9882, c2740)) {
            view.measure(iM988, iM9882);
        }
    }

    /* JADX WARN: Removed duplicated region for block: B:21:0x0034  */
    /* JADX WARN: Removed duplicated region for block: B:22:0x0036  */
    /* JADX WARN: Removed duplicated region for block: B:32:0x0056  */
    /* JADX WARN: Removed duplicated region for block: B:35:0x0068  */
    /* JADX WARN: Removed duplicated region for block: B:41:0x007d  */
    /* JADX WARN: Removed duplicated region for block: B:43:0x0092  */
    /* JADX WARN: Removed duplicated region for block: B:44:0x00a0  */
    /* JADX WARN: Removed duplicated region for block: B:47:0x00b5  */
    /* JADX WARN: Removed duplicated region for block: B:53:0x00c6  */
    /* JADX WARN: Removed duplicated region for block: B:56:0x00cc  */
    /* JADX WARN: Removed duplicated region for block: B:65:0x007a A[SYNTHETIC] */
    /* JADX WARN: Removed duplicated region for block: B:68:? A[RETURN, SYNTHETIC] */
    /* renamed from: ˊﾞ, reason: contains not printable characters */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct add '--show-bad-code' argument
    */
    public final void m1000(int r10, int r11, int r12) {
        /*
            Method dump skipped, instructions count: 223
            To view this dump add '--comments-level debug' option
        */
        throw new UnsupportedOperationException("Method not decompiled: androidx.recyclerview.widget.StaggeredGridLayoutManager.m1000(int, int, int):void");
    }

    /* renamed from: ˋـ, reason: contains not printable characters */
    public final void m1001(p179.C2666 c2666, p179.C2723 c2723, boolean z) {
        int iMo3818;
        int iM1017 = m1017(Integer.MIN_VALUE);
        if (iM1017 != Integer.MIN_VALUE && (iMo3818 = this.f1555.mo3818() - iM1017) > 0) {
            int i = iMo3818 - (-m989(-iMo3818, c2666, c2723));
            if (!z || i <= 0) {
                return;
            }
            this.f1555.mo3829(i);
        }
    }

    /* renamed from: ˎʾ, reason: contains not printable characters */
    public final boolean m1002() {
        int iM1010;
        if (m5974() != 0 && this.f1537 != 0 && this.f10151) {
            if (this.f1540) {
                iM1010 = m1008();
                m1010();
            } else {
                iM1010 = m1010();
                m1008();
            }
            if (iM1010 == 0 && m1007() != null) {
                this.f1549.m9569();
                this.f10157 = true;
                m5982();
                return true;
            }
        }
        return false;
    }

    /* JADX WARN: Type inference failed for: r8v2 */
    /* JADX WARN: Type inference failed for: r8v24 */
    /* JADX WARN: Type inference failed for: r8v3, types: [boolean, int] */
    /* renamed from: ˎˉ, reason: contains not printable characters */
    public final int m1003(p179.C2666 c2666, p179.C2718 c2718, p179.C2723 c2723) {
        p179.C2713 c2713;
        ?? r8;
        int iM6084;
        int iMo3824;
        int iMo3822;
        int iMo38242;
        int i;
        int i2;
        int i3;
        int i4 = 0;
        int i5 = 1;
        this.f1535.set(0, this.f1536, true);
        p179.C2718 c27182 = this.f1534;
        int i6 = c27182.f10342 ? c2718.f10345 == 1 ? Integer.MAX_VALUE : Integer.MIN_VALUE : c2718.f10345 == 1 ? c2718.f10346 + c2718.f10348 : c2718.f10350 - c2718.f10348;
        int i7 = c2718.f10345;
        for (int i8 = 0; i8 < this.f1536; i8++) {
            if (!((java.util.ArrayList) this.f1553[i8].f10320).isEmpty()) {
                m993(this.f1553[i8], i7, i6);
            }
        }
        int iMo3818 = this.f1540 ? this.f1555.mo3818() : this.f1555.mo3822();
        boolean z = false;
        while (true) {
            int i9 = c2718.f10343;
            if (i9 < 0 || i9 >= c2723.m6109() || (!c27182.f10342 && this.f1535.isEmpty())) {
                break;
            }
            android.view.View viewM5951 = c2666.m5951(c2718.f10343);
            c2718.f10343 += c2718.f10344;
            p179.C2740 c2740 = (p179.C2740) viewM5951.getLayoutParams();
            int iM6008 = c2740.f10283.m6008();
            p404.C4790 c4790 = this.f1549;
            int[] iArr = (int[]) c4790.f18036;
            int i10 = (iArr == null || iM6008 >= iArr.length) ? -1 : iArr[iM6008];
            if (i10 == -1) {
                if (m995(c2718.f10345)) {
                    i3 = this.f1536 - i5;
                    i2 = -1;
                    i = -1;
                } else {
                    i = i5;
                    i2 = this.f1536;
                    i3 = i4;
                }
                p179.C2713 c27132 = null;
                if (c2718.f10345 == i5) {
                    int iMo38222 = this.f1555.mo3822();
                    int i11 = Integer.MAX_VALUE;
                    while (i3 != i2) {
                        p179.C2713 c27133 = this.f1553[i3];
                        int iM6092 = c27133.m6092(iMo38222);
                        if (iM6092 < i11) {
                            i11 = iM6092;
                            c27132 = c27133;
                        }
                        i3 += i;
                    }
                } else {
                    int iMo38182 = this.f1555.mo3818();
                    int i12 = Integer.MIN_VALUE;
                    while (i3 != i2) {
                        p179.C2713 c27134 = this.f1553[i3];
                        int iM60842 = c27134.m6084(iMo38182);
                        if (iM60842 > i12) {
                            c27132 = c27134;
                            i12 = iM60842;
                        }
                        i3 += i;
                    }
                }
                c2713 = c27132;
                c4790.m9558(iM6008);
                ((int[]) c4790.f18036)[iM6008] = c2713.f10316;
            } else {
                c2713 = this.f1553[i10];
            }
            c2740.f10459 = c2713;
            if (c2718.f10345 == 1) {
                r8 = 0;
                m5992(-1, viewM5951, false);
            } else {
                r8 = 0;
                m5992(0, viewM5951, false);
            }
            if (this.f1544 == 1) {
                m999(viewM5951, p179.AbstractC2669.m5962(r8, this.f1538, this.f10156, r8, ((android.view.ViewGroup.MarginLayoutParams) c2740).width), p179.AbstractC2669.m5962(true, this.f10148, this.f10147, m5988() + m5989(), ((android.view.ViewGroup.MarginLayoutParams) c2740).height));
            } else {
                m999(viewM5951, p179.AbstractC2669.m5962(true, this.f10152, this.f10156, m5987() + m5984(), ((android.view.ViewGroup.MarginLayoutParams) c2740).width), p179.AbstractC2669.m5962(false, this.f1538, this.f10147, 0, ((android.view.ViewGroup.MarginLayoutParams) c2740).height));
            }
            if (c2718.f10345 == 1) {
                iMo3824 = c2713.m6092(iMo3818);
                iM6084 = this.f1555.mo3824(viewM5951) + iMo3824;
            } else {
                iM6084 = c2713.m6084(iMo3818);
                iMo3824 = iM6084 - this.f1555.mo3824(viewM5951);
            }
            if (c2718.f10345 == 1) {
                p179.C2713 c27135 = c2740.f10459;
                c27135.getClass();
                p179.C2740 c27402 = (p179.C2740) viewM5951.getLayoutParams();
                c27402.f10459 = c27135;
                java.util.ArrayList arrayList = (java.util.ArrayList) c27135.f10320;
                arrayList.add(viewM5951);
                c27135.f10314 = Integer.MIN_VALUE;
                if (arrayList.size() == 1) {
                    c27135.f10318 = Integer.MIN_VALUE;
                }
                if (c27402.f10283.m6007() || c27402.f10283.m6009()) {
                    c27135.f10315 = ((androidx.recyclerview.widget.StaggeredGridLayoutManager) c27135.f10317).f1555.mo3824(viewM5951) + c27135.f10315;
                }
            } else {
                p179.C2713 c27136 = c2740.f10459;
                c27136.getClass();
                p179.C2740 c27403 = (p179.C2740) viewM5951.getLayoutParams();
                c27403.f10459 = c27136;
                java.util.ArrayList arrayList2 = (java.util.ArrayList) c27136.f10320;
                arrayList2.add(0, viewM5951);
                c27136.f10318 = Integer.MIN_VALUE;
                if (arrayList2.size() == 1) {
                    c27136.f10314 = Integer.MIN_VALUE;
                }
                if (c27403.f10283.m6007() || c27403.f10283.m6009()) {
                    c27136.f10315 = ((androidx.recyclerview.widget.StaggeredGridLayoutManager) c27136.f10317).f1555.mo3824(viewM5951) + c27136.f10315;
                }
            }
            if (m1005() && this.f1544 == 1) {
                iMo38242 = this.f1545.mo3818() - (((this.f1536 - 1) - c2713.f10316) * this.f1538);
                iMo3822 = iMo38242 - this.f1545.mo3824(viewM5951);
            } else {
                iMo3822 = this.f1545.mo3822() + (c2713.f10316 * this.f1538);
                iMo38242 = this.f1545.mo3824(viewM5951) + iMo3822;
            }
            if (this.f1544 == 1) {
                p179.AbstractC2669.m5969(viewM5951, iMo3822, iMo3824, iMo38242, iM6084);
            } else {
                p179.AbstractC2669.m5969(viewM5951, iMo3824, iMo3822, iM6084, iMo38242);
            }
            m993(c2713, c27182.f10345, i6);
            m1011(c2666, c27182);
            if (c27182.f10347 && viewM5951.hasFocusable()) {
                this.f1535.set(c2713.f10316, false);
            }
            i5 = 1;
            z = true;
            i4 = 0;
        }
        if (!z) {
            m1011(c2666, c27182);
        }
        int iMo38223 = c27182.f10345 == -1 ? this.f1555.mo3822() - m998(this.f1555.mo3822()) : m1017(this.f1555.mo3818()) - this.f1555.mo3818();
        if (iMo38223 > 0) {
            return java.lang.Math.min(c2718.f10348, iMo38223);
        }
        return 0;
    }

    /* renamed from: ˎـ, reason: contains not printable characters */
    public final void m1004(int i, p179.C2723 c2723) {
        int iM1010;
        int i2;
        if (i > 0) {
            iM1010 = m1008();
            i2 = 1;
        } else {
            iM1010 = m1010();
            i2 = -1;
        }
        p179.C2718 c2718 = this.f1534;
        c2718.f10349 = true;
        m1016(iM1010, c2723);
        m1013(i2);
        c2718.f10343 = iM1010 + c2718.f10344;
        c2718.f10348 = java.lang.Math.abs(i);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˏי */
    public final p179.C2700 mo502() {
        return this.f1544 == 0 ? new p179.C2740(-2, -1) : new p179.C2740(-1, -2);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˏᵢ */
    public final void mo503(p179.C2666 c2666, p179.C2723 c2723, p158.C2535 c2535) {
        super.mo503(c2666, c2723, c2535);
        c2535.m5665("androidx.recyclerview.widget.StaggeredGridLayoutManager");
    }

    /* renamed from: ˏⁱ, reason: contains not printable characters */
    public final boolean m1005() {
        return this.f10154.getLayoutDirection() == 1;
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˑʼ */
    public final void mo873(androidx.recyclerview.widget.RecyclerView recyclerView, int i, int i2) {
        m1000(i, i2, 4);
    }

    /* renamed from: ˑˆ, reason: contains not printable characters */
    public final int m1006(p179.C2723 c2723) {
        if (m5974() == 0) {
            return 0;
        }
        boolean z = !this.f1552;
        return p179.AbstractC2741.m6139(c2723, this.f1555, m1012(z), m1014(z), this, this.f1552, this.f1540);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˑﹳ */
    public final boolean mo506() {
        return this.f1544 == 0;
    }

    @Override // p179.AbstractC2669
    /* renamed from: י */
    public final android.os.Parcelable mo508() {
        int iM6084;
        int iMo3822;
        int[] iArr;
        p179.C2668 c2668 = this.f1543;
        if (c2668 != null) {
            p179.C2668 c26682 = new p179.C2668();
            c26682.f10133 = c2668.f10133;
            c26682.f10134 = c2668.f10134;
            c26682.f10140 = c2668.f10140;
            c26682.f10135 = c2668.f10135;
            c26682.f10141 = c2668.f10141;
            c26682.f10137 = c2668.f10137;
            c26682.f10136 = c2668.f10136;
            c26682.f10142 = c2668.f10142;
            c26682.f10138 = c2668.f10138;
            c26682.f10139 = c2668.f10139;
            return c26682;
        }
        p179.C2668 c26683 = new p179.C2668();
        c26683.f10136 = this.f1546;
        c26683.f10142 = this.f1541;
        c26683.f10138 = this.f1550;
        p404.C4790 c4790 = this.f1549;
        if (c4790 == null || (iArr = (int[]) c4790.f18036) == null) {
            c26683.f10141 = 0;
        } else {
            c26683.f10137 = iArr;
            c26683.f10141 = iArr.length;
            c26683.f10139 = (java.util.ArrayList) c4790.f18034;
        }
        if (m5974() <= 0) {
            c26683.f10134 = -1;
            c26683.f10140 = -1;
            c26683.f10133 = 0;
            return c26683;
        }
        c26683.f10134 = this.f1541 ? m1008() : m1010();
        android.view.View viewM1014 = this.f1540 ? m1014(true) : m1012(true);
        c26683.f10140 = viewM1014 != null ? p179.AbstractC2669.m5963(viewM1014) : -1;
        int i = this.f1536;
        c26683.f10133 = i;
        c26683.f10135 = new int[i];
        for (int i2 = 0; i2 < this.f1536; i2++) {
            if (this.f1541) {
                iM6084 = this.f1553[i2].m6092(Integer.MIN_VALUE);
                if (iM6084 != Integer.MIN_VALUE) {
                    iMo3822 = this.f1555.mo3818();
                    iM6084 -= iMo3822;
                }
            } else {
                iM6084 = this.f1553[i2].m6084(Integer.MIN_VALUE);
                if (iM6084 != Integer.MIN_VALUE) {
                    iMo3822 = this.f1555.mo3822();
                    iM6084 -= iMo3822;
                }
            }
            c26683.f10135[i2] = iM6084;
        }
        return c26683;
    }

    @Override // p179.AbstractC2669
    /* renamed from: יˉ */
    public final void mo510(androidx.recyclerview.widget.RecyclerView recyclerView, int i) {
        p179.C2688 c2688 = new p179.C2688(recyclerView.getContext());
        c2688.f10247 = i;
        mo536(c2688);
    }

    /* JADX WARN: Removed duplicated region for block: B:51:0x00f4  */
    /* JADX WARN: Removed duplicated region for block: B:52:0x00f6  */
    /* JADX WARN: Removed duplicated region for block: B:54:0x00f9  */
    /* JADX WARN: Removed duplicated region for block: B:55:0x00fb  */
    /* JADX WARN: Removed duplicated region for block: B:68:0x00fe A[SYNTHETIC] */
    /* JADX WARN: Removed duplicated region for block: B:74:0x002c A[SYNTHETIC] */
    /* renamed from: ـʻ, reason: contains not printable characters */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct add '--show-bad-code' argument
    */
    public final android.view.View m1007() {
        /*
            Method dump skipped, instructions count: 257
            To view this dump add '--comments-level debug' option
        */
        throw new UnsupportedOperationException("Method not decompiled: androidx.recyclerview.widget.StaggeredGridLayoutManager.m1007():android.view.View");
    }

    @Override // p179.AbstractC2669
    /* renamed from: ـﹶ */
    public final void mo514(int i, int i2) {
        m1000(i, i2, 1);
    }

    /* renamed from: ٴʿ, reason: contains not printable characters */
    public final int m1008() {
        int iM5974 = m5974();
        if (iM5974 == 0) {
            return 0;
        }
        return p179.AbstractC2669.m5963(m5981(iM5974 - 1));
    }

    @Override // p179.AbstractC2669
    /* renamed from: ٴᴵ */
    public final void mo879(android.graphics.Rect rect, int i, int i2) {
        int iM5968;
        int iM59682;
        int iM5987 = m5987() + m5984();
        int iM5988 = m5988() + m5989();
        int i3 = this.f1544;
        int i4 = this.f1536;
        if (i3 == 1) {
            int iHeight = rect.height() + iM5988;
            androidx.recyclerview.widget.RecyclerView recyclerView = this.f10154;
            java.util.WeakHashMap weakHashMap = p186.AbstractC2823.f10603;
            iM59682 = p179.AbstractC2669.m5968(i2, iHeight, recyclerView.getMinimumHeight());
            iM5968 = p179.AbstractC2669.m5968(i, (this.f1538 * i4) + iM5987, this.f10154.getMinimumWidth());
        } else {
            int iWidth = rect.width() + iM5987;
            androidx.recyclerview.widget.RecyclerView recyclerView2 = this.f10154;
            java.util.WeakHashMap weakHashMap2 = p186.AbstractC2823.f10603;
            iM5968 = p179.AbstractC2669.m5968(i, iWidth, recyclerView2.getMinimumWidth());
            iM59682 = p179.AbstractC2669.m5968(i2, (this.f1538 * i4) + iM5988, this.f10154.getMinimumHeight());
        }
        this.f10154.setMeasuredDimension(iM5968, iM59682);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ٴﹳ */
    public final void mo517(p179.C2666 c2666, p179.C2723 c2723) {
        m990(c2666, c2723, true);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ٴﹶ */
    public final int mo907(p179.C2723 c2723) {
        if (m5974() == 0) {
            return 0;
        }
        boolean z = !this.f1552;
        return p179.AbstractC2741.m6141(c2723, this.f1555, m1012(z), m1014(z), this, this.f1552);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ᐧᴵ */
    public final void mo908(android.view.accessibility.AccessibilityEvent accessibilityEvent) {
        super.mo908(accessibilityEvent);
        if (m5974() > 0) {
            android.view.View viewM1012 = m1012(false);
            android.view.View viewM1014 = m1014(false);
            if (viewM1012 == null || viewM1014 == null) {
                return;
            }
            int iM5963 = p179.AbstractC2669.m5963(viewM1012);
            int iM59632 = p179.AbstractC2669.m5963(viewM1014);
            if (iM5963 < iM59632) {
                accessibilityEvent.setFromIndex(iM5963);
                accessibilityEvent.setToIndex(iM59632);
            } else {
                accessibilityEvent.setFromIndex(iM59632);
                accessibilityEvent.setToIndex(iM5963);
            }
        }
    }

    @Override // p179.AbstractC2669
    /* renamed from: ᐧﹶ */
    public final void mo520(android.os.Parcelable parcelable) {
        if (parcelable instanceof p179.C2668) {
            p179.C2668 c2668 = (p179.C2668) parcelable;
            this.f1543 = c2668;
            if (this.f1554 != -1) {
                c2668.f10134 = -1;
                c2668.f10140 = -1;
                c2668.f10135 = null;
                c2668.f10133 = 0;
                c2668.f10141 = 0;
                c2668.f10137 = null;
                c2668.f10139 = null;
            }
            m5982();
        }
    }

    /* JADX WARN: Removed duplicated region for block: B:23:0x0032  */
    /* JADX WARN: Removed duplicated region for block: B:29:0x003d  */
    @Override // p179.AbstractC2669
    /* renamed from: ᐧﾞ */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct add '--show-bad-code' argument
    */
    public final android.view.View mo881(android.view.View r8, int r9, p179.C2666 r10, p179.C2723 r11) {
        /*
            Method dump skipped, instructions count: 331
            To view this dump add '--comments-level debug' option
        */
        throw new UnsupportedOperationException("Method not decompiled: androidx.recyclerview.widget.StaggeredGridLayoutManager.mo881(android.view.View, int, ˋˋ.ʻˋ, ˋˋ.ᐧﹶ):android.view.View");
    }

    @Override // p179.AbstractC2669
    /* renamed from: ᴵˑ, reason: contains not printable characters */
    public final void mo1009(int i) {
        super.mo1009(i);
        for (int i2 = 0; i2 < this.f1536; i2++) {
            p179.C2713 c2713 = this.f1553[i2];
            int i3 = c2713.f10318;
            if (i3 != Integer.MIN_VALUE) {
                c2713.f10318 = i3 + i;
            }
            int i4 = c2713.f10314;
            if (i4 != Integer.MIN_VALUE) {
                c2713.f10314 = i4 + i;
            }
        }
    }

    @Override // p179.AbstractC2669
    /* renamed from: ᵎʻ */
    public final void mo523(p179.C2723 c2723) {
        this.f1554 = -1;
        this.f1539 = Integer.MIN_VALUE;
        this.f1543 = null;
        this.f1542.m6031();
    }

    @Override // p179.AbstractC2669
    /* renamed from: ᵎᵔ */
    public final void mo910(androidx.recyclerview.widget.RecyclerView recyclerView) {
        androidx.recyclerview.widget.RecyclerView recyclerView2 = this.f10154;
        if (recyclerView2 != null) {
            recyclerView2.removeCallbacks(this.f1551);
        }
        for (int i = 0; i < this.f1536; i++) {
            this.f1553[i].m6093();
        }
        recyclerView.requestLayout();
    }

    @Override // p179.AbstractC2669
    /* renamed from: ᵎﹶ */
    public final boolean mo524(p179.C2700 c2700) {
        return c2700 instanceof p179.C2740;
    }

    @Override // p179.AbstractC2669
    /* renamed from: ᵔʾ */
    public final int mo911(p179.C2723 c2723) {
        if (m5974() == 0) {
            return 0;
        }
        boolean z = !this.f1552;
        return p179.AbstractC2741.m6141(c2723, this.f1555, m1012(z), m1014(z), this, this.f1552);
    }

    /* renamed from: ᵔⁱ, reason: contains not printable characters */
    public final int m1010() {
        if (m5974() == 0) {
            return 0;
        }
        return p179.AbstractC2669.m5963(m5981(0));
    }

    /* renamed from: ᵢʻ, reason: contains not printable characters */
    public final void m1011(p179.C2666 c2666, p179.C2718 c2718) {
        if (!c2718.f10349 || c2718.f10342) {
            return;
        }
        if (c2718.f10348 == 0) {
            if (c2718.f10345 == -1) {
                m992(c2718.f10346, c2666);
                return;
            } else {
                m996(c2718.f10350, c2666);
                return;
            }
        }
        int i = 1;
        if (c2718.f10345 == -1) {
            int i2 = c2718.f10350;
            int iM6084 = this.f1553[0].m6084(i2);
            while (i < this.f1536) {
                int iM60842 = this.f1553[i].m6084(i2);
                if (iM60842 > iM6084) {
                    iM6084 = iM60842;
                }
                i++;
            }
            int i3 = i2 - iM6084;
            m992(i3 < 0 ? c2718.f10346 : c2718.f10346 - java.lang.Math.min(i3, c2718.f10348), c2666);
            return;
        }
        int i4 = c2718.f10346;
        int iM6092 = this.f1553[0].m6092(i4);
        while (i < this.f1536) {
            int iM60922 = this.f1553[i].m6092(i4);
            if (iM60922 < iM6092) {
                iM6092 = iM60922;
            }
            i++;
        }
        int i5 = iM6092 - c2718.f10346;
        m996(i5 < 0 ? c2718.f10350 : java.lang.Math.min(i5, c2718.f10348) + c2718.f10350, c2666);
    }

    /* renamed from: ᵢˋ, reason: contains not printable characters */
    public final android.view.View m1012(boolean z) {
        int iMo3822 = this.f1555.mo3822();
        int iMo3818 = this.f1555.mo3818();
        int iM5974 = m5974();
        android.view.View view = null;
        for (int i = 0; i < iM5974; i++) {
            android.view.View viewM5981 = m5981(i);
            int iMo3826 = this.f1555.mo3826(viewM5981);
            if (this.f1555.mo3821(viewM5981) > iMo3822 && iMo3826 < iMo3818) {
                if (iMo3826 >= iMo3822 || !z) {
                    return viewM5981;
                }
                if (view == null) {
                    view = viewM5981;
                }
            }
        }
        return view;
    }

    @Override // p179.AbstractC2669
    /* renamed from: ᵢˏ */
    public final int mo527(p179.C2666 c2666, p179.C2723 c2723) {
        if (this.f1544 == 1) {
            return java.lang.Math.min(this.f1536, c2723.m6109());
        }
        return -1;
    }

    /* renamed from: ᵢᐧ, reason: contains not printable characters */
    public final void m1013(int i) {
        p179.C2718 c2718 = this.f1534;
        c2718.f10345 = i;
        c2718.f10344 = this.f1540 != (i == -1) ? -1 : 1;
    }

    @Override // p179.AbstractC2669
    /* renamed from: ⁱי */
    public final int mo530(int i, p179.C2666 c2666, p179.C2723 c2723) {
        return m989(i, c2666, c2723);
    }

    /* JADX WARN: Removed duplicated region for block: B:6:0x000c  */
    @Override // p179.InterfaceC2677
    /* renamed from: ﹳٴ */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct add '--show-bad-code' argument
    */
    public final android.graphics.PointF mo916(int r4) {
        /*
            r3 = this;
            int r0 = r3.m5974()
            r1 = -1
            r2 = 1
            if (r0 != 0) goto Le
            boolean r4 = r3.f1540
            if (r4 == 0) goto L1b
        Lc:
            r1 = r2
            goto L1b
        Le:
            int r0 = r3.m1010()
            if (r4 >= r0) goto L16
            r4 = r2
            goto L17
        L16:
            r4 = 0
        L17:
            boolean r0 = r3.f1540
            if (r4 == r0) goto Lc
        L1b:
            android.graphics.PointF r4 = new android.graphics.PointF
            r4.<init>()
            if (r1 != 0) goto L24
            r4 = 0
            return r4
        L24:
            int r0 = r3.f1544
            r2 = 0
            if (r0 != 0) goto L2f
            float r0 = (float) r1
            r4.x = r0
            r4.y = r2
            return r4
        L2f:
            r4.x = r2
            float r0 = (float) r1
            r4.y = r0
            return r4
        */
        throw new UnsupportedOperationException("Method not decompiled: androidx.recyclerview.widget.StaggeredGridLayoutManager.mo916(int):android.graphics.PointF");
    }

    /* renamed from: ﹳᵢ, reason: contains not printable characters */
    public final android.view.View m1014(boolean z) {
        int iMo3822 = this.f1555.mo3822();
        int iMo3818 = this.f1555.mo3818();
        android.view.View view = null;
        for (int iM5974 = m5974() - 1; iM5974 >= 0; iM5974--) {
            android.view.View viewM5981 = m5981(iM5974);
            int iMo3826 = this.f1555.mo3826(viewM5981);
            int iMo3821 = this.f1555.mo3821(viewM5981);
            if (iMo3821 > iMo3822 && iMo3826 < iMo3818) {
                if (iMo3821 <= iMo3818 || !z) {
                    return viewM5981;
                }
                if (view == null) {
                    view = viewM5981;
                }
            }
        }
        return view;
    }

    @Override // p179.AbstractC2669
    /* renamed from: ﹳⁱ */
    public final void mo531(int i) {
        p179.C2668 c2668 = this.f1543;
        if (c2668 != null && c2668.f10134 != i) {
            c2668.f10135 = null;
            c2668.f10133 = 0;
            c2668.f10134 = -1;
            c2668.f10140 = -1;
        }
        this.f1554 = i;
        this.f1539 = Integer.MIN_VALUE;
        m5982();
    }

    @Override // p179.AbstractC2669
    /* renamed from: ﹳﹳ */
    public final void mo532(int i, int i2) {
        m1000(i, i2, 2);
    }

    /* renamed from: ﹶʽ, reason: contains not printable characters */
    public final void m1015(p179.C2666 c2666, p179.C2723 c2723, boolean z) {
        int iMo3822;
        int iM998 = m998(Integer.MAX_VALUE);
        if (iM998 != Integer.MAX_VALUE && (iMo3822 = iM998 - this.f1555.mo3822()) > 0) {
            int iM989 = iMo3822 - m989(iMo3822, c2666, c2723);
            if (!z || iM989 <= 0) {
                return;
            }
            this.f1555.mo3829(-iM989);
        }
    }

    @Override // p179.AbstractC2669
    /* renamed from: ﹶᐧ */
    public final void mo534(int i, int i2) {
        m1000(i, i2, 8);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ﾞʻ */
    public final int mo884(p179.C2723 c2723) {
        return m1006(c2723);
    }

    /* renamed from: ﾞˊ, reason: contains not printable characters */
    public final void m1016(int i, p179.C2723 c2723) {
        int iMo3827;
        int iMo38272;
        int i2;
        p179.C2718 c2718 = this.f1534;
        boolean z = false;
        c2718.f10348 = 0;
        c2718.f10343 = i;
        p179.C2688 c2688 = this.f10149;
        if (c2688 == null || !c2688.f10241 || (i2 = c2723.f10380) == -1) {
            iMo3827 = 0;
            iMo38272 = 0;
        } else {
            if (this.f1540 == (i2 < i)) {
                iMo3827 = this.f1555.mo3827();
                iMo38272 = 0;
            } else {
                iMo38272 = this.f1555.mo3827();
                iMo3827 = 0;
            }
        }
        androidx.recyclerview.widget.RecyclerView recyclerView = this.f10154;
        if (recyclerView == null || !recyclerView.f1481) {
            c2718.f10346 = this.f1555.mo3828() + iMo3827;
            c2718.f10350 = -iMo38272;
        } else {
            c2718.f10350 = this.f1555.mo3822() - iMo38272;
            c2718.f10346 = this.f1555.mo3818() + iMo3827;
        }
        c2718.f10347 = false;
        c2718.f10349 = true;
        if (this.f1555.mo3825() == 0 && this.f1555.mo3828() == 0) {
            z = true;
        }
        c2718.f10342 = z;
    }

    /* renamed from: ﾞˏ, reason: contains not printable characters */
    public final int m1017(int i) {
        int iM6092 = this.f1553[0].m6092(i);
        for (int i2 = 1; i2 < this.f1536; i2++) {
            int iM60922 = this.f1553[i2].m6092(i);
            if (iM60922 > iM6092) {
                iM6092 = iM60922;
            }
        }
        return iM6092;
    }

    @Override // p179.AbstractC2669
    /* renamed from: ﾞᴵ */
    public final boolean mo538() {
        return this.f1544 == 1;
    }
}
