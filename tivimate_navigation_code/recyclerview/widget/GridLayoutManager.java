package androidx.recyclerview.widget;

/* loaded from: classes.dex */
public class GridLayoutManager extends androidx.recyclerview.widget.LinearLayoutManager {

    /* renamed from: ˑٴ, reason: contains not printable characters */
    public static final java.util.Set f1421 = j$.util.DesugarCollections.unmodifiableSet(new java.util.HashSet(java.util.Arrays.asList(17, 66, 33, 130)));

    /* renamed from: ˆﾞ, reason: contains not printable characters */
    public int f1422;

    /* renamed from: ˈʿ, reason: contains not printable characters */
    public int f1423;

    /* renamed from: ˉٴ, reason: contains not printable characters */
    public android.view.View[] f1424;

    /* renamed from: ˊʻ, reason: contains not printable characters */
    public int f1425;

    /* renamed from: ٴʼ, reason: contains not printable characters */
    public final android.util.SparseIntArray f1426;

    /* renamed from: ٴᵢ, reason: contains not printable characters */
    public int[] f1427;

    /* renamed from: ᴵᵔ, reason: contains not printable characters */
    public boolean f1428;

    /* renamed from: ᵎˊ, reason: contains not printable characters */
    public final ﹶﾞ.ⁱי f1429;

    /* renamed from: ᵎⁱ, reason: contains not printable characters */
    public final android.util.SparseIntArray f1430;

    /* renamed from: ᵔי, reason: contains not printable characters */
    public final android.graphics.Rect f1431;

    /* renamed from: ᵔٴ, reason: contains not printable characters */
    public int f1432;

    public GridLayoutManager(int i) {
        super(1);
        this.f1428 = false;
        this.f1425 = -1;
        this.f1430 = new android.util.SparseIntArray();
        this.f1426 = new android.util.SparseIntArray();
        this.f1429 = new ﹶﾞ.ⁱי(24);
        this.f1431 = new android.graphics.Rect();
        this.f1422 = -1;
        this.f1432 = -1;
        this.f1423 = -1;
        m875(i);
    }

    public GridLayoutManager(android.content.Context context, android.util.AttributeSet attributeSet, int i, int i2) {
        super(context, attributeSet, i, i2);
        this.f1428 = false;
        this.f1425 = -1;
        this.f1430 = new android.util.SparseIntArray();
        this.f1426 = new android.util.SparseIntArray();
        this.f1429 = new ﹶﾞ.ⁱי(24);
        this.f1431 = new android.graphics.Rect();
        this.f1422 = -1;
        this.f1432 = -1;
        this.f1423 = -1;
        m875(p179.AbstractC2669.m5967(context, attributeSet, i, i2).f10385);
    }

    /* renamed from: ʻˆ, reason: contains not printable characters */
    public final void m858(int i) {
        int i2;
        int[] iArr = this.f1427;
        int i3 = this.f1425;
        if (iArr == null || iArr.length != i3 + 1 || iArr[iArr.length - 1] != i) {
            iArr = new int[i3 + 1];
        }
        int i4 = 0;
        iArr[0] = 0;
        int i5 = i / i3;
        int i6 = i % i3;
        int i7 = 0;
        for (int i8 = 1; i8 <= i3; i8++) {
            i4 += i6;
            if (i4 <= 0 || i3 - i4 >= i6) {
                i2 = i5;
            } else {
                i2 = i5 + 1;
                i4 -= i3;
            }
            i7 += i2;
            iArr[i8] = i7;
        }
        this.f1427 = iArr;
    }

    @Override // p179.AbstractC2669
    /* renamed from: ʻٴ */
    public final p179.C2700 mo468(android.view.ViewGroup.LayoutParams layoutParams) {
        if (layoutParams instanceof android.view.ViewGroup.MarginLayoutParams) {
            p179.C2698 c2698 = new p179.C2698((android.view.ViewGroup.MarginLayoutParams) layoutParams);
            c2698.f10276 = -1;
            c2698.f10277 = 0;
            return c2698;
        }
        p179.C2698 c26982 = new p179.C2698(layoutParams);
        c26982.f10276 = -1;
        c26982.f10277 = 0;
        return c26982;
    }

    @Override // p179.AbstractC2669
    /* renamed from: ʻᵎ */
    public final void mo469(p179.C2666 c2666, p179.C2723 c2723, android.view.View view, p158.C2535 c2535) {
        android.view.ViewGroup.LayoutParams layoutParams = view.getLayoutParams();
        if (!(layoutParams instanceof p179.C2698)) {
            m5985(view, c2535);
            return;
        }
        p179.C2698 c2698 = (p179.C2698) layoutParams;
        int iM880 = m880(c2698.f10283.m6008(), c2666, c2723);
        if (this.f1435 == 0) {
            c2535.m5678(p075.C1652.m4511(false, c2698.f10276, c2698.f10277, iM880, 1));
        } else {
            c2535.m5678(p075.C1652.m4511(false, iM880, 1, c2698.f10276, c2698.f10277));
        }
    }

    @Override // androidx.recyclerview.widget.LinearLayoutManager, p179.AbstractC2669
    /* renamed from: ʼᐧ, reason: contains not printable characters */
    public final int mo859(p179.C2723 c2723) {
        return m914(c2723);
    }

    /* renamed from: ʽᐧ, reason: contains not printable characters */
    public final int m860(int i) {
        if (this.f1435 == 1) {
            androidx.recyclerview.widget.RecyclerView recyclerView = this.f10154;
            return m880(i, recyclerView.f1464, recyclerView.f1516);
        }
        androidx.recyclerview.widget.RecyclerView recyclerView2 = this.f10154;
        return m878(i, recyclerView2.f1464, recyclerView2.f1516);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ʽﹳ */
    public final p179.C2700 mo476(android.content.Context context, android.util.AttributeSet attributeSet) {
        p179.C2698 c2698 = new p179.C2698(context, attributeSet);
        c2698.f10276 = -1;
        c2698.f10277 = 0;
        return c2698;
    }

    /* renamed from: ʾˏ, reason: contains not printable characters */
    public final int m861(int i, int i2) {
        if (this.f1435 != 1 || !m889()) {
            int[] iArr = this.f1427;
            return iArr[i2 + i] - iArr[i];
        }
        int[] iArr2 = this.f1427;
        int i3 = this.f1425;
        return iArr2[i3 - i] - iArr2[(i3 - i) - i2];
    }

    /* renamed from: ʿˎ, reason: contains not printable characters */
    public final void m862() {
        int iM5988;
        int iM5989;
        if (this.f1435 == 1) {
            iM5988 = this.f10152 - m5987();
            iM5989 = m5984();
        } else {
            iM5988 = this.f10148 - m5988();
            iM5989 = m5989();
        }
        m858(iM5988 - iM5989);
    }

    @Override // androidx.recyclerview.widget.LinearLayoutManager, p179.AbstractC2669
    /* renamed from: ʿـ */
    public final int mo481(int i, p179.C2666 c2666, p179.C2723 c2723) {
        m862();
        m871();
        return super.mo481(i, c2666, c2723);
    }

    @Override // androidx.recyclerview.widget.LinearLayoutManager
    /* renamed from: ˆˎ, reason: contains not printable characters */
    public final void mo863(p179.C2666 c2666, p179.C2723 c2723, p179.C2697 c2697, int i) {
        m862();
        if (c2723.m6109() > 0 && !c2723.f10376) {
            boolean z = i == 1;
            int iM878 = m878(c2697.f10273, c2666, c2723);
            if (z) {
                while (iM878 > 0) {
                    int i2 = c2697.f10273;
                    if (i2 <= 0) {
                        break;
                    }
                    int i3 = i2 - 1;
                    c2697.f10273 = i3;
                    iM878 = m878(i3, c2666, c2723);
                }
            } else {
                int iM6109 = c2723.m6109() - 1;
                int i4 = c2697.f10273;
                while (i4 < iM6109) {
                    int i5 = i4 + 1;
                    int iM8782 = m878(i5, c2666, c2723);
                    if (iM8782 <= iM878) {
                        break;
                    }
                    i4 = i5;
                    iM878 = iM8782;
                }
                c2697.f10273 = i4;
            }
        }
        m871();
    }

    @Override // androidx.recyclerview.widget.LinearLayoutManager
    /* renamed from: ˆﹳ, reason: contains not printable characters */
    public final void mo864(p179.C2666 c2666, p179.C2723 c2723, p179.C2717 c2717, p179.C2732 c2732) {
        int i;
        int i2;
        int i3;
        int iMo3831;
        int iM5989;
        int iM5984;
        int iMo38312;
        int iM5962;
        int iM59622;
        boolean z;
        int i4;
        android.view.View viewM6098;
        int iMo3830 = this.f1447.mo3830();
        boolean z2 = iMo3830 != 1073741824;
        int i5 = m5974() > 0 ? this.f1427[this.f1425] : 0;
        if (z2) {
            m862();
        }
        boolean z3 = c2717.f10334 == 1;
        int iM878 = this.f1425;
        if (!z3) {
            iM878 = m878(c2717.f10333, c2666, c2723) + m868(c2717.f10333, c2666, c2723);
        }
        int i6 = 0;
        while (i6 < this.f1425 && (i4 = c2717.f10333) >= 0 && i4 < c2723.m6109() && iM878 > 0) {
            int i7 = c2717.f10333;
            int iM868 = m868(i7, c2666, c2723);
            if (iM868 > this.f1425) {
                throw new java.lang.IllegalArgumentException(p035.AbstractC1220.m3782(p307.AbstractC3740.m7944("Item at position ", i7, " requires ", iM868, " spans but GridLayoutManager has only "), this.f1425, " spans."));
            }
            iM878 -= iM868;
            if (iM878 < 0 || (viewM6098 = c2717.m6098(c2666)) == null) {
                break;
            }
            this.f1424[i6] = viewM6098;
            i6++;
        }
        if (i6 == 0) {
            c2732.f10429 = true;
            return;
        }
        if (z3) {
            i3 = 1;
            i2 = i6;
            i = 0;
        } else {
            i = i6 - 1;
            i2 = -1;
            i3 = -1;
        }
        int i8 = 0;
        while (i != i2) {
            android.view.View view = this.f1424[i];
            p179.C2698 c2698 = (p179.C2698) view.getLayoutParams();
            int iM8682 = m868(p179.AbstractC2669.m5963(view), c2666, c2723);
            c2698.f10277 = iM8682;
            c2698.f10276 = i8;
            i8 += iM8682;
            i += i3;
        }
        float f = 0.0f;
        int i9 = 0;
        for (int i10 = 0; i10 < i6; i10++) {
            android.view.View view2 = this.f1424[i10];
            if (c2717.f10335 != null) {
                z = false;
                if (z3) {
                    m5992(-1, view2, true);
                } else {
                    m5992(0, view2, true);
                }
            } else if (z3) {
                z = false;
                m5992(-1, view2, false);
            } else {
                z = false;
                m5992(0, view2, false);
            }
            m5976(view2, this.f1431);
            m882(iMo3830, view2, z);
            int iMo3824 = this.f1447.mo3824(view2);
            if (iMo3824 > i9) {
                i9 = iMo3824;
            }
            float fMo3831 = (this.f1447.mo3831(view2) * 1.0f) / ((p179.C2698) view2.getLayoutParams()).f10277;
            if (fMo3831 > f) {
                f = fMo3831;
            }
        }
        if (z2) {
            m858(java.lang.Math.max(java.lang.Math.round(f * this.f1425), i5));
            i9 = 0;
            for (int i11 = 0; i11 < i6; i11++) {
                android.view.View view3 = this.f1424[i11];
                m882(1073741824, view3, true);
                int iMo38242 = this.f1447.mo3824(view3);
                if (iMo38242 > i9) {
                    i9 = iMo38242;
                }
            }
        }
        for (int i12 = 0; i12 < i6; i12++) {
            android.view.View view4 = this.f1424[i12];
            if (this.f1447.mo3824(view4) != i9) {
                p179.C2698 c26982 = (p179.C2698) view4.getLayoutParams();
                android.graphics.Rect rect = c26982.f10282;
                int i13 = rect.top + rect.bottom + ((android.view.ViewGroup.MarginLayoutParams) c26982).topMargin + ((android.view.ViewGroup.MarginLayoutParams) c26982).bottomMargin;
                int i14 = rect.left + rect.right + ((android.view.ViewGroup.MarginLayoutParams) c26982).leftMargin + ((android.view.ViewGroup.MarginLayoutParams) c26982).rightMargin;
                int iM861 = m861(c26982.f10276, c26982.f10277);
                if (this.f1435 == 1) {
                    iM59622 = p179.AbstractC2669.m5962(false, iM861, 1073741824, i14, ((android.view.ViewGroup.MarginLayoutParams) c26982).width);
                    iM5962 = android.view.View.MeasureSpec.makeMeasureSpec(i9 - i13, 1073741824);
                } else {
                    int iMakeMeasureSpec = android.view.View.MeasureSpec.makeMeasureSpec(i9 - i14, 1073741824);
                    iM5962 = p179.AbstractC2669.m5962(false, iM861, 1073741824, i13, ((android.view.ViewGroup.MarginLayoutParams) c26982).height);
                    iM59622 = iMakeMeasureSpec;
                }
                if (m5971(view4, iM59622, iM5962, (p179.C2700) view4.getLayoutParams())) {
                    view4.measure(iM59622, iM5962);
                }
            }
        }
        c2732.f10430 = i9;
        if (this.f1435 != 1) {
            if (c2717.f10341 == -1) {
                int i15 = c2717.f10338;
                iM5984 = i15 - i9;
                iM5989 = 0;
                iMo3831 = i15;
            } else {
                int i16 = c2717.f10338;
                iMo3831 = i16 + i9;
                iM5989 = 0;
                iM5984 = i16;
            }
            iMo38312 = iM5989;
        } else if (c2717.f10341 == -1) {
            iMo38312 = c2717.f10338;
            iM5989 = iMo38312 - i9;
            iM5984 = 0;
            iMo3831 = 0;
        } else {
            int i17 = c2717.f10338;
            iMo3831 = 0;
            iM5989 = i17;
            iMo38312 = i17 + i9;
            iM5984 = 0;
        }
        for (int i18 = 0; i18 < i6; i18++) {
            android.view.View view5 = this.f1424[i18];
            p179.C2698 c26983 = (p179.C2698) view5.getLayoutParams();
            if (this.f1435 != 1) {
                iM5989 = m5989() + this.f1427[c26983.f10276];
                iMo38312 = this.f1447.mo3831(view5) + iM5989;
            } else if (m889()) {
                int iM59842 = m5984() + this.f1427[this.f1425 - c26983.f10276];
                iMo3831 = iM59842;
                iM5984 = iM59842 - this.f1447.mo3831(view5);
            } else {
                iM5984 = m5984() + this.f1427[c26983.f10276];
                iMo3831 = this.f1447.mo3831(view5) + iM5984;
            }
            p179.AbstractC2669.m5969(view5, iM5984, iM5989, iMo3831, iMo38312);
            if (c26983.f10283.m6007() || c26983.f10283.m6009()) {
                c2732.f10427 = true;
            }
            c2732.f10428 = view5.hasFocusable() | c2732.f10428;
        }
        java.util.Arrays.fill(this.f1424, (java.lang.Object) null);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˈʿ */
    public final int mo487(p179.C2666 c2666, p179.C2723 c2723) {
        if (this.f1435 == 0) {
            return java.lang.Math.min(this.f1425, m5977());
        }
        if (c2723.m6109() < 1) {
            return 0;
        }
        return m880(c2723.m6109() - 1, c2666, c2723) + 1;
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˈˏ */
    public final void mo488() {
        ﹶﾞ.ⁱי r0 = this.f1429;
        r0.ʻٴ();
        ((android.util.SparseIntArray) r0.ʽʽ).clear();
    }

    @Override // androidx.recyclerview.widget.LinearLayoutManager, p179.AbstractC2669
    /* renamed from: ˈـ, reason: contains not printable characters */
    public final boolean mo865() {
        return this.f1446 == null && !this.f1428;
    }

    @Override // androidx.recyclerview.widget.LinearLayoutManager, p179.AbstractC2669
    /* renamed from: ˉʿ, reason: contains not printable characters */
    public final int mo866(p179.C2723 c2723) {
        return m914(c2723);
    }

    @Override // androidx.recyclerview.widget.LinearLayoutManager, p179.AbstractC2669
    /* renamed from: ˉˆ, reason: contains not printable characters */
    public final int mo867(p179.C2723 c2723) {
        return m917(c2723);
    }

    /* renamed from: ˊـ, reason: contains not printable characters */
    public final int m868(int i, p179.C2666 c2666, p179.C2723 c2723) {
        boolean z = c2723.f10376;
        ﹶﾞ.ⁱי r0 = this.f1429;
        if (!z) {
            r0.getClass();
            return 1;
        }
        int i2 = this.f1430.get(i, -1);
        if (i2 != -1) {
            return i2;
        }
        if (c2666.m5958(i) != -1) {
            r0.getClass();
            return 1;
        }
        java.lang.String str = "Cannot find span size for pre layout position. It is not cached, not in the adapter. Pos:" + i;
        return 1;
    }

    @Override // androidx.recyclerview.widget.LinearLayoutManager
    /* renamed from: ˊﹳ, reason: contains not printable characters */
    public final android.view.View mo869(p179.C2666 c2666, p179.C2723 c2723, boolean z, boolean z2) {
        int i;
        int iM5974;
        int iM59742 = m5974();
        int i2 = 1;
        if (z2) {
            iM5974 = m5974() - 1;
            i = -1;
            i2 = -1;
        } else {
            i = iM59742;
            iM5974 = 0;
        }
        int iM6109 = c2723.m6109();
        m918();
        int iMo3822 = this.f1447.mo3822();
        int iMo3818 = this.f1447.mo3818();
        android.view.View view = null;
        android.view.View view2 = null;
        while (iM5974 != i) {
            android.view.View viewM5981 = m5981(iM5974);
            int iM5963 = p179.AbstractC2669.m5963(viewM5981);
            if (iM5963 >= 0 && iM5963 < iM6109 && m878(iM5963, c2666, c2723) == 0) {
                if (((p179.C2700) viewM5981.getLayoutParams()).f10283.m6007()) {
                    if (view2 == null) {
                        view2 = viewM5981;
                    }
                } else {
                    if (this.f1447.mo3826(viewM5981) < iMo3818 && this.f1447.mo3821(viewM5981) >= iMo3822) {
                        return viewM5981;
                    }
                    if (view == null) {
                        view = viewM5981;
                    }
                }
            }
            iM5974 += i2;
        }
        return view != null ? view : view2;
    }

    /* renamed from: ˎᵎ, reason: contains not printable characters */
    public final java.util.HashSet m870(int i, int i2) {
        java.util.HashSet hashSet = new java.util.HashSet();
        androidx.recyclerview.widget.RecyclerView recyclerView = this.f10154;
        int iM868 = m868(i2, recyclerView.f1464, recyclerView.f1516);
        for (int i3 = i; i3 < i + iM868; i3++) {
            hashSet.add(java.lang.Integer.valueOf(i3));
        }
        return hashSet;
    }

    /* renamed from: ˏʻ, reason: contains not printable characters */
    public final void m871() {
        android.view.View[] viewArr = this.f1424;
        if (viewArr == null || viewArr.length != this.f1425) {
            this.f1424 = new android.view.View[this.f1425];
        }
    }

    @Override // androidx.recyclerview.widget.LinearLayoutManager, p179.AbstractC2669
    /* renamed from: ˏי */
    public final p179.C2700 mo502() {
        return this.f1435 == 0 ? new p179.C2698(-2, -1) : new p179.C2698(-1, -2);
    }

    @Override // androidx.recyclerview.widget.LinearLayoutManager, p179.AbstractC2669
    /* renamed from: ˏᵢ */
    public final void mo503(p179.C2666 c2666, p179.C2723 c2723, p158.C2535 c2535) {
        super.mo503(c2666, c2723, c2535);
        c2535.m5665(android.widget.GridView.class.getName());
        p179.AbstractC2727 abstractC2727 = this.f10154.f1474;
        if (abstractC2727 == null || abstractC2727.mo611() <= 1) {
            return;
        }
        c2535.m5675(p158.C2526.f9619);
    }

    /* JADX WARN: Removed duplicated region for block: B:118:0x01a1  */
    /* JADX WARN: Removed duplicated region for block: B:121:0x01a7  */
    /* JADX WARN: Removed duplicated region for block: B:122:0x01a9 A[EDGE_INSN: B:209:0x01a9->B:122:0x01a9 BREAK  A[LOOP:2: B:126:0x01b9->B:135:0x01e2, LOOP_LABEL: LOOP:2: B:126:0x01b9->B:135:0x01e2], EDGE_INSN: B:216:0x01a9->B:122:0x01a9 BREAK  A[LOOP:5: B:148:0x0221->B:159:0x0251, LOOP_LABEL: LOOP:5: B:148:0x0221->B:159:0x0251]] */
    /* JADX WARN: Removed duplicated region for block: B:142:0x0213  */
    /* JADX WARN: Removed duplicated region for block: B:167:0x027e  */
    @Override // androidx.recyclerview.widget.LinearLayoutManager, p179.AbstractC2669
    /* renamed from: ˑ, reason: contains not printable characters */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct add '--show-bad-code' argument
    */
    public final boolean mo872(int r12, android.os.Bundle r13) {
        /*
            Method dump skipped, instructions count: 739
            To view this dump add '--comments-level debug' option
        */
        throw new UnsupportedOperationException("Method not decompiled: androidx.recyclerview.widget.GridLayoutManager.mo872(int, android.os.Bundle):boolean");
    }

    @Override // p179.AbstractC2669
    /* renamed from: ˑʼ, reason: contains not printable characters */
    public final void mo873(androidx.recyclerview.widget.RecyclerView recyclerView, int i, int i2) {
        ﹶﾞ.ⁱי r1 = this.f1429;
        r1.ʻٴ();
        ((android.util.SparseIntArray) r1.ʽʽ).clear();
    }

    @Override // androidx.recyclerview.widget.LinearLayoutManager
    /* renamed from: ˑˆ, reason: contains not printable characters */
    public final void mo874(p179.C2723 c2723, p179.C2717 c2717, p179.C2676 c2676) {
        int i;
        int i2 = this.f1425;
        for (int i3 = 0; i3 < this.f1425 && (i = c2717.f10333) >= 0 && i < c2723.m6109() && i2 > 0; i3++) {
            c2676.m6025(c2717.f10333, java.lang.Math.max(0, c2717.f10336));
            this.f1429.getClass();
            i2--;
            c2717.f10333 += c2717.f10334;
        }
    }

    /* renamed from: ˑˉ, reason: contains not printable characters */
    public final void m875(int i) {
        if (i == this.f1425) {
            return;
        }
        this.f1428 = true;
        if (i < 1) {
            throw new java.lang.IllegalArgumentException(p307.AbstractC3740.m7932(i, "Span count should be at least 1. Provided "));
        }
        this.f1425 = i;
        this.f1429.ʻٴ();
        m5982();
    }

    @Override // androidx.recyclerview.widget.LinearLayoutManager
    /* renamed from: יʿ, reason: contains not printable characters */
    public final void mo876(boolean z) {
        if (z) {
            throw new java.lang.UnsupportedOperationException("GridLayoutManager does not support stack from end. Consider using reverse layout");
        }
        super.mo876(false);
    }

    /* renamed from: יⁱ, reason: contains not printable characters */
    public final int m877(int i) {
        if (this.f1435 == 0) {
            androidx.recyclerview.widget.RecyclerView recyclerView = this.f10154;
            return m880(i, recyclerView.f1464, recyclerView.f1516);
        }
        androidx.recyclerview.widget.RecyclerView recyclerView2 = this.f10154;
        return m878(i, recyclerView2.f1464, recyclerView2.f1516);
    }

    /* renamed from: ـˑ, reason: contains not printable characters */
    public final int m878(int i, p179.C2666 c2666, p179.C2723 c2723) {
        boolean z = c2723.f10376;
        ﹶﾞ.ⁱי r0 = this.f1429;
        if (!z) {
            int i2 = this.f1425;
            r0.getClass();
            return i % i2;
        }
        int i3 = this.f1426.get(i, -1);
        if (i3 != -1) {
            return i3;
        }
        int iM5958 = c2666.m5958(i);
        if (iM5958 != -1) {
            int i4 = this.f1425;
            r0.getClass();
            return iM5958 % i4;
        }
        java.lang.String str = "Cannot find span size for pre layout position. It is not cached, not in the adapter. Pos:" + i;
        return 0;
    }

    @Override // p179.AbstractC2669
    /* renamed from: ـﹶ */
    public final void mo514(int i, int i2) {
        ﹶﾞ.ⁱי r1 = this.f1429;
        r1.ʻٴ();
        ((android.util.SparseIntArray) r1.ʽʽ).clear();
    }

    @Override // p179.AbstractC2669
    /* renamed from: ٴᴵ, reason: contains not printable characters */
    public final void mo879(android.graphics.Rect rect, int i, int i2) {
        int iM5968;
        int iM59682;
        if (this.f1427 == null) {
            super.mo879(rect, i, i2);
        }
        int iM5987 = m5987() + m5984();
        int iM5988 = m5988() + m5989();
        if (this.f1435 == 1) {
            int iHeight = rect.height() + iM5988;
            androidx.recyclerview.widget.RecyclerView recyclerView = this.f10154;
            java.util.WeakHashMap weakHashMap = p186.AbstractC2823.f10603;
            iM59682 = p179.AbstractC2669.m5968(i2, iHeight, recyclerView.getMinimumHeight());
            int[] iArr = this.f1427;
            iM5968 = p179.AbstractC2669.m5968(i, iArr[iArr.length - 1] + iM5987, this.f10154.getMinimumWidth());
        } else {
            int iWidth = rect.width() + iM5987;
            androidx.recyclerview.widget.RecyclerView recyclerView2 = this.f10154;
            java.util.WeakHashMap weakHashMap2 = p186.AbstractC2823.f10603;
            iM5968 = p179.AbstractC2669.m5968(i, iWidth, recyclerView2.getMinimumWidth());
            int[] iArr2 = this.f1427;
            iM59682 = p179.AbstractC2669.m5968(i2, iArr2[iArr2.length - 1] + iM5988, this.f10154.getMinimumHeight());
        }
        this.f10154.setMeasuredDimension(iM5968, iM59682);
    }

    @Override // androidx.recyclerview.widget.LinearLayoutManager, p179.AbstractC2669
    /* renamed from: ٴﹳ */
    public final void mo517(p179.C2666 c2666, p179.C2723 c2723) {
        boolean z = c2723.f10376;
        android.util.SparseIntArray sparseIntArray = this.f1426;
        android.util.SparseIntArray sparseIntArray2 = this.f1430;
        if (z) {
            int iM5974 = m5974();
            for (int i = 0; i < iM5974; i++) {
                p179.C2698 c2698 = (p179.C2698) m5981(i).getLayoutParams();
                int iM6008 = c2698.f10283.m6008();
                sparseIntArray2.put(iM6008, c2698.f10277);
                sparseIntArray.put(iM6008, c2698.f10276);
            }
        }
        super.mo517(c2666, c2723);
        sparseIntArray2.clear();
        sparseIntArray.clear();
    }

    /* renamed from: ᐧˏ, reason: contains not printable characters */
    public final int m880(int i, p179.C2666 c2666, p179.C2723 c2723) {
        boolean z = c2723.f10376;
        ﹶﾞ.ⁱי r0 = this.f1429;
        if (!z) {
            int i2 = this.f1425;
            r0.getClass();
            return ﹶﾞ.ⁱי.ˏי(i, i2);
        }
        int iM5958 = c2666.m5958(i);
        if (iM5958 != -1) {
            int i3 = this.f1425;
            r0.getClass();
            return ﹶﾞ.ⁱי.ˏי(iM5958, i3);
        }
        java.lang.String str = "Cannot find span size for pre layout position. " + i;
        return 0;
    }

    /* JADX WARN: Code restructure failed: missing block: B:54:0x00c9, code lost:
    
        if (r13 == (r2 > r15)) goto L49;
     */
    /* JADX WARN: Code restructure failed: missing block: B:78:0x012d, code lost:
    
        if (r16 == null) goto L80;
     */
    /* JADX WARN: Code restructure failed: missing block: B:79:0x012f, code lost:
    
        return r16;
     */
    /* JADX WARN: Code restructure failed: missing block: B:80:0x0130, code lost:
    
        return r17;
     */
    @Override // androidx.recyclerview.widget.LinearLayoutManager, p179.AbstractC2669
    /* renamed from: ᐧﾞ, reason: contains not printable characters */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct add '--show-bad-code' argument
    */
    public final android.view.View mo881(android.view.View r23, int r24, p179.C2666 r25, p179.C2723 r26) {
        /*
            Method dump skipped, instructions count: 305
            To view this dump add '--comments-level debug' option
        */
        throw new UnsupportedOperationException("Method not decompiled: androidx.recyclerview.widget.GridLayoutManager.mo881(android.view.View, int, ˋˋ.ʻˋ, ˋˋ.ᐧﹶ):android.view.View");
    }

    @Override // androidx.recyclerview.widget.LinearLayoutManager, p179.AbstractC2669
    /* renamed from: ᵎʻ */
    public final void mo523(p179.C2723 c2723) {
        android.view.View viewMo904;
        super.mo523(c2723);
        this.f1428 = false;
        int i = this.f1422;
        if (i == -1 || (viewMo904 = mo904(i)) == null) {
            return;
        }
        viewMo904.sendAccessibilityEvent(67108864);
        this.f1422 = -1;
    }

    @Override // p179.AbstractC2669
    /* renamed from: ᵎﹶ */
    public final boolean mo524(p179.C2700 c2700) {
        return c2700 instanceof p179.C2698;
    }

    @Override // p179.AbstractC2669
    /* renamed from: ᵢˏ */
    public final int mo527(p179.C2666 c2666, p179.C2723 c2723) {
        if (this.f1435 == 1) {
            return java.lang.Math.min(this.f1425, m5977());
        }
        if (c2723.m6109() < 1) {
            return 0;
        }
        return m880(c2723.m6109() - 1, c2666, c2723) + 1;
    }

    /* renamed from: ᵢי, reason: contains not printable characters */
    public final void m882(int i, android.view.View view, boolean z) {
        int iM5962;
        int iM59622;
        p179.C2698 c2698 = (p179.C2698) view.getLayoutParams();
        android.graphics.Rect rect = c2698.f10282;
        int i2 = rect.top + rect.bottom + ((android.view.ViewGroup.MarginLayoutParams) c2698).topMargin + ((android.view.ViewGroup.MarginLayoutParams) c2698).bottomMargin;
        int i3 = rect.left + rect.right + ((android.view.ViewGroup.MarginLayoutParams) c2698).leftMargin + ((android.view.ViewGroup.MarginLayoutParams) c2698).rightMargin;
        int iM861 = m861(c2698.f10276, c2698.f10277);
        if (this.f1435 == 1) {
            iM59622 = p179.AbstractC2669.m5962(false, iM861, i, i3, ((android.view.ViewGroup.MarginLayoutParams) c2698).width);
            iM5962 = p179.AbstractC2669.m5962(true, this.f1447.mo3827(), this.f10147, i2, ((android.view.ViewGroup.MarginLayoutParams) c2698).height);
        } else {
            int iM59623 = p179.AbstractC2669.m5962(false, iM861, i, i2, ((android.view.ViewGroup.MarginLayoutParams) c2698).height);
            int iM59624 = p179.AbstractC2669.m5962(true, this.f1447.mo3827(), this.f10156, i3, ((android.view.ViewGroup.MarginLayoutParams) c2698).width);
            iM5962 = iM59623;
            iM59622 = iM59624;
        }
        p179.C2700 c2700 = (p179.C2700) view.getLayoutParams();
        if (z ? m5971(view, iM59622, iM5962, c2700) : m5972(view, iM59622, iM5962, c2700)) {
            view.measure(iM59622, iM5962);
        }
    }

    /* renamed from: ⁱʾ, reason: contains not printable characters */
    public final java.util.HashSet m883(int i) {
        return m870(m860(i), i);
    }

    @Override // androidx.recyclerview.widget.LinearLayoutManager, p179.AbstractC2669
    /* renamed from: ⁱי */
    public final int mo530(int i, p179.C2666 c2666, p179.C2723 c2723) {
        m862();
        m871();
        return super.mo530(i, c2666, c2723);
    }

    @Override // p179.AbstractC2669
    /* renamed from: ﹳﹳ */
    public final void mo532(int i, int i2) {
        ﹶﾞ.ⁱי r1 = this.f1429;
        r1.ʻٴ();
        ((android.util.SparseIntArray) r1.ʽʽ).clear();
    }

    @Override // p179.AbstractC2669
    /* renamed from: ﹶᐧ */
    public final void mo534(int i, int i2) {
        ﹶﾞ.ⁱי r1 = this.f1429;
        r1.ʻٴ();
        ((android.util.SparseIntArray) r1.ʽʽ).clear();
    }

    @Override // androidx.recyclerview.widget.LinearLayoutManager, p179.AbstractC2669
    /* renamed from: ﾞʻ, reason: contains not printable characters */
    public final int mo884(p179.C2723 c2723) {
        return m917(c2723);
    }
}
