package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ᵔᵢ, reason: contains not printable characters */
/* loaded from: classes.dex */
public abstract class AbstractC0145 extends androidx.recyclerview.widget.RecyclerView {

    /* renamed from: ʽʾ, reason: contains not printable characters */
    public boolean f1001;

    /* renamed from: ʿʽ, reason: contains not printable characters */
    public int f1002;

    /* renamed from: ˆˑ, reason: contains not printable characters */
    public boolean f1003;

    /* renamed from: ˆﹳ, reason: contains not printable characters */
    public int f1004;

    /* renamed from: ˊﹳ, reason: contains not printable characters */
    public androidx.leanback.widget.GridLayoutManager f1005;

    /* renamed from: ˎـ, reason: contains not printable characters */
    public p179.AbstractC2722 f1006;

    /* renamed from: ᵢʻ, reason: contains not printable characters */
    public androidx.leanback.widget.InterfaceC0088 f1007;

    public AbstractC0145(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet, 0);
        this.f1001 = true;
        this.f1003 = true;
        this.f1002 = 4;
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = new androidx.leanback.widget.GridLayoutManager(this);
        this.f1005 = gridLayoutManager;
        setLayoutManager(gridLayoutManager);
        setPreserveFocusAfterLayout(false);
        setDescendantFocusability(262144);
        setHasFixedSize(true);
        setChildrenDrawingOrderEnabled(true);
        setWillNotDraw(true);
        setOverScrollMode(2);
        ((ʿי.ـᵎ) getItemAnimator()).ᵎﹶ = false;
        this.f1494.add(new androidx.leanback.widget.C0150(this));
    }

    @Override // android.view.ViewGroup, android.view.View
    public final boolean dispatchGenericFocusedEvent(android.view.MotionEvent motionEvent) {
        return super.dispatchGenericFocusedEvent(motionEvent);
    }

    @Override // androidx.recyclerview.widget.RecyclerView, android.view.ViewGroup, android.view.View
    public final boolean dispatchKeyEvent(android.view.KeyEvent keyEvent) {
        androidx.leanback.widget.InterfaceC0088 interfaceC0088 = this.f1007;
        return (interfaceC0088 != null && interfaceC0088.mo574(keyEvent)) || super.dispatchKeyEvent(keyEvent);
    }

    @Override // android.view.View
    public final android.view.View focusSearch(int i) {
        if (isFocused()) {
            androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1005;
            android.view.View viewMo904 = gridLayoutManager.mo904(gridLayoutManager.f613);
            if (viewMo904 != null) {
                return focusSearch(viewMo904, i);
            }
        }
        return super.focusSearch(i);
    }

    @Override // androidx.recyclerview.widget.RecyclerView, android.view.ViewGroup
    public final int getChildDrawingOrder(int i, int i2) {
        int iIndexOfChild;
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1005;
        android.view.View viewMo904 = gridLayoutManager.mo904(gridLayoutManager.f613);
        return (viewMo904 != null && i2 >= (iIndexOfChild = indexOfChild(viewMo904))) ? i2 < i + (-1) ? ((iIndexOfChild + i) - 1) - i2 : iIndexOfChild : i2;
    }

    public int getExtraLayoutSpace() {
        return this.f1005.f625;
    }

    public int getFocusScrollStrategy() {
        return this.f1005.f605;
    }

    @java.lang.Deprecated
    public int getHorizontalMargin() {
        return this.f1005.f616;
    }

    public int getHorizontalSpacing() {
        return this.f1005.f616;
    }

    public int getInitialPrefetchItemCount() {
        return this.f1002;
    }

    public int getItemAlignmentOffset() {
        return ((androidx.leanback.widget.C0084) this.f1005.f632.ˈٴ).f968;
    }

    public float getItemAlignmentOffsetPercent() {
        return ((androidx.leanback.widget.C0084) this.f1005.f632.ˈٴ).f965;
    }

    public int getItemAlignmentViewId() {
        return ((androidx.leanback.widget.C0084) this.f1005.f632.ˈٴ).f969;
    }

    public androidx.leanback.widget.InterfaceC0154 getOnUnhandledKeyListener() {
        return null;
    }

    public final int getSaveChildrenLimitNumber() {
        return this.f1005.f627.f957;
    }

    public final int getSaveChildrenPolicy() {
        return this.f1005.f627.f956;
    }

    public int getSelectedPosition() {
        return this.f1005.f613;
    }

    public int getSelectedSubPosition() {
        return this.f1005.f624;
    }

    public androidx.leanback.widget.InterfaceC0141 getSmoothScrollByBehavior() {
        return null;
    }

    public final int getSmoothScrollMaxPendingMoves() {
        return this.f1005.f636;
    }

    public final float getSmoothScrollSpeedFactor() {
        return this.f1005.f600;
    }

    @java.lang.Deprecated
    public int getVerticalMargin() {
        return this.f1005.f614;
    }

    public int getVerticalSpacing() {
        return this.f1005.f614;
    }

    public int getWindowAlignment() {
        return ((androidx.leanback.widget.C0091) this.f1005.f606.ˈٴ).f859;
    }

    public int getWindowAlignmentOffset() {
        return ((androidx.leanback.widget.C0091) this.f1005.f606.ˈٴ).f854;
    }

    public float getWindowAlignmentOffsetPercent() {
        return ((androidx.leanback.widget.C0091) this.f1005.f606.ˈٴ).f855;
    }

    @Override // android.view.View
    public final boolean hasOverlappingRendering() {
        return this.f1003;
    }

    @Override // android.view.View
    public final void onFocusChanged(boolean z, int i, android.graphics.Rect rect) {
        super.onFocusChanged(z, i, rect);
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1005;
        if (!z) {
            gridLayoutManager.getClass();
            return;
        }
        int i2 = gridLayoutManager.f613;
        while (true) {
            android.view.View viewMo904 = gridLayoutManager.mo904(i2);
            if (viewMo904 == null) {
                return;
            }
            if (viewMo904.getVisibility() == 0 && viewMo904.hasFocusable()) {
                viewMo904.requestFocus();
                return;
            }
            i2++;
        }
    }

    @Override // androidx.recyclerview.widget.RecyclerView, android.view.ViewGroup
    public final boolean onRequestFocusInDescendants(int i, android.graphics.Rect rect) {
        int i2;
        int i3;
        int i4;
        if ((this.f1004 & 1) != 1) {
            androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1005;
            int i5 = gridLayoutManager.f605;
            if (i5 == 1 || i5 == 2) {
                int iM5974 = gridLayoutManager.m5974();
                if ((i & 2) != 0) {
                    i4 = 1;
                    i3 = iM5974;
                    i2 = 0;
                } else {
                    i2 = iM5974 - 1;
                    i3 = -1;
                    i4 = -1;
                }
                androidx.leanback.widget.C0091 c0091 = (androidx.leanback.widget.C0091) gridLayoutManager.f606.ˈٴ;
                int i6 = c0091.f850;
                int i7 = ((c0091.f848 - i6) - c0091.f853) + i6;
                while (i2 != i3) {
                    android.view.View viewM5981 = gridLayoutManager.m5981(i2);
                    if (viewM5981.getVisibility() == 0 && gridLayoutManager.f617.mo3826(viewM5981) >= i6 && gridLayoutManager.f617.mo3821(viewM5981) <= i7 && viewM5981.requestFocus(i, rect)) {
                        return true;
                    }
                    i2 += i4;
                }
            } else {
                android.view.View viewMo904 = gridLayoutManager.mo904(gridLayoutManager.f613);
                if (viewMo904 != null) {
                    return viewMo904.requestFocus(i, rect);
                }
            }
        }
        return false;
    }

    /* JADX WARN: Removed duplicated region for block: B:8:0x000f  */
    @Override // android.view.View
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct add '--show-bad-code' argument
    */
    public final void onRtlPropertiesChanged(int r7) {
        /*
            r6 = this;
            androidx.leanback.widget.GridLayoutManager r0 = r6.f1005
            if (r0 == 0) goto L31
            int r1 = r0.f620
            r2 = 0
            r3 = 1
            if (r1 != 0) goto L11
            if (r7 != r3) goto Lf
            r1 = 262144(0x40000, float:3.67342E-40)
            goto L15
        Lf:
            r1 = r2
            goto L15
        L11:
            if (r7 != r3) goto Lf
            r1 = 524288(0x80000, float:7.34684E-40)
        L15:
            int r4 = r0.f601
            r5 = 786432(0xc0000, float:1.102026E-39)
            r5 = r5 & r4
            if (r5 != r1) goto L1d
            goto L31
        L1d:
            r5 = -786433(0xfffffffffff3ffff, float:NaN)
            r4 = r4 & r5
            r1 = r1 | r4
            r1 = r1 | 256(0x100, float:3.59E-43)
            r0.f601 = r1
            ˏˆ.ﹳٴ r0 = r0.f606
            java.lang.Object r0 = r0.ʽʽ
            androidx.leanback.widget.ʽⁱ r0 = (androidx.leanback.widget.C0091) r0
            if (r7 != r3) goto L2f
            r2 = r3
        L2f:
            r0.f858 = r2
        L31:
            return
        */
        throw new UnsupportedOperationException("Method not decompiled: androidx.leanback.widget.AbstractC0145.onRtlPropertiesChanged(int):void");
    }

    @Override // android.view.ViewGroup, android.view.ViewManager
    public final void removeView(android.view.View view) {
        boolean z = view.hasFocus() && isFocusable();
        if (z) {
            this.f1004 = 1 | this.f1004;
            requestFocus();
        }
        super.removeView(view);
        if (z) {
            this.f1004 ^= -2;
        }
    }

    @Override // android.view.ViewGroup
    public final void removeViewAt(int i) {
        boolean zHasFocus = getChildAt(i).hasFocus();
        if (zHasFocus) {
            this.f1004 |= 1;
            requestFocus();
        }
        super.removeViewAt(i);
        if (zHasFocus) {
            this.f1004 ^= -2;
        }
    }

    public void setAnimateChildLayout(boolean z) {
        if (this.f1001 != z) {
            this.f1001 = z;
            if (z) {
                super.setItemAnimator(this.f1006);
            } else {
                this.f1006 = getItemAnimator();
                super.setItemAnimator(null);
            }
        }
    }

    public void setChildrenVisibility(int i) {
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1005;
        gridLayoutManager.f631 = i;
        if (i != -1) {
            int iM5974 = gridLayoutManager.m5974();
            for (int i2 = 0; i2 < iM5974; i2++) {
                gridLayoutManager.m5981(i2).setVisibility(gridLayoutManager.f631);
            }
        }
    }

    public void setExtraLayoutSpace(int i) {
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1005;
        int i2 = gridLayoutManager.f625;
        if (i2 == i) {
            return;
        }
        if (i2 < 0) {
            throw new java.lang.IllegalArgumentException("ExtraLayoutSpace must >= 0");
        }
        gridLayoutManager.f625 = i;
        gridLayoutManager.m5982();
    }

    public void setFocusDrawingOrderEnabled(boolean z) {
        super.setChildrenDrawingOrderEnabled(z);
    }

    public void setFocusScrollStrategy(int i) {
        if (i != 0 && i != 1 && i != 2) {
            throw new java.lang.IllegalArgumentException("Invalid scrollStrategy");
        }
        this.f1005.f605 = i;
        requestLayout();
    }

    public final void setFocusSearchDisabled(boolean z) {
        setDescendantFocusability(z ? 393216 : 262144);
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1005;
        gridLayoutManager.f601 = (z ? 32768 : 0) | (gridLayoutManager.f601 & (-32769));
    }

    public void setGravity(int i) {
        this.f1005.f638 = i;
        requestLayout();
    }

    public void setHasOverlappingRendering(boolean z) {
        this.f1003 = z;
    }

    @java.lang.Deprecated
    public void setHorizontalMargin(int i) {
        setHorizontalSpacing(i);
    }

    public void setHorizontalSpacing(int i) {
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1005;
        if (gridLayoutManager.f620 == 0) {
            gridLayoutManager.f616 = i;
            gridLayoutManager.f599 = i;
        } else {
            gridLayoutManager.f616 = i;
            gridLayoutManager.f622 = i;
        }
        requestLayout();
    }

    public void setInitialPrefetchItemCount(int i) {
        this.f1002 = i;
    }

    public void setItemAlignmentOffset(int i) {
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1005;
        ((androidx.leanback.widget.C0084) gridLayoutManager.f632.ˈٴ).f968 = i;
        gridLayoutManager.m511();
        requestLayout();
    }

    public void setItemAlignmentOffsetPercent(float f) {
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1005;
        ((androidx.leanback.widget.C0084) gridLayoutManager.f632.ˈٴ).m634(f);
        gridLayoutManager.m511();
        requestLayout();
    }

    public void setItemAlignmentOffsetWithPadding(boolean z) {
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1005;
        ((androidx.leanback.widget.C0084) gridLayoutManager.f632.ˈٴ).f966 = z;
        gridLayoutManager.m511();
        requestLayout();
    }

    public void setItemAlignmentViewId(int i) {
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1005;
        ((androidx.leanback.widget.C0084) gridLayoutManager.f632.ˈٴ).f969 = i;
        gridLayoutManager.m511();
    }

    @java.lang.Deprecated
    public void setItemMargin(int i) {
        setItemSpacing(i);
    }

    public void setItemSpacing(int i) {
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1005;
        gridLayoutManager.f616 = i;
        gridLayoutManager.f614 = i;
        gridLayoutManager.f622 = i;
        gridLayoutManager.f599 = i;
        requestLayout();
    }

    public void setLayoutEnabled(boolean z) {
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1005;
        int i = gridLayoutManager.f601;
        if (((i & 512) != 0) != z) {
            gridLayoutManager.f601 = (i & (-513)) | (z ? 512 : 0);
            gridLayoutManager.m5982();
        }
    }

    @Override // androidx.recyclerview.widget.RecyclerView
    public void setLayoutManager(p179.AbstractC2669 abstractC2669) {
        if (abstractC2669 != null) {
            androidx.leanback.widget.GridLayoutManager gridLayoutManager = (androidx.leanback.widget.GridLayoutManager) abstractC2669;
            this.f1005 = gridLayoutManager;
            gridLayoutManager.f639 = this;
            gridLayoutManager.f611 = null;
            super.setLayoutManager(abstractC2669);
            return;
        }
        super.setLayoutManager(null);
        androidx.leanback.widget.GridLayoutManager gridLayoutManager2 = this.f1005;
        if (gridLayoutManager2 != null) {
            gridLayoutManager2.f639 = null;
            gridLayoutManager2.f611 = null;
        }
        this.f1005 = null;
    }

    public void setOnChildLaidOutListener(androidx.leanback.widget.InterfaceC0135 interfaceC0135) {
        this.f1005.getClass();
    }

    @android.annotation.SuppressLint({"ReferencesDeprecated"})
    public void setOnChildSelectedListener(androidx.leanback.widget.InterfaceC0106 interfaceC0106) {
        this.f1005.f609 = interfaceC0106;
    }

    public void setOnChildViewHolderSelectedListener(androidx.leanback.widget.AbstractC0096 abstractC0096) {
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1005;
        if (abstractC0096 == null) {
            gridLayoutManager.f630 = null;
            return;
        }
        java.util.ArrayList arrayList = gridLayoutManager.f630;
        if (arrayList == null) {
            gridLayoutManager.f630 = new java.util.ArrayList();
        } else {
            arrayList.clear();
        }
        gridLayoutManager.f630.add(abstractC0096);
    }

    public void setOnKeyInterceptListener(androidx.leanback.widget.InterfaceC0088 interfaceC0088) {
        this.f1007 = interfaceC0088;
    }

    public void setOnMotionInterceptListener(androidx.leanback.widget.InterfaceC0100 interfaceC0100) {
    }

    public void setOnTouchInterceptListener(androidx.leanback.widget.InterfaceC0118 interfaceC0118) {
    }

    public void setOnUnhandledKeyListener(androidx.leanback.widget.InterfaceC0154 interfaceC0154) {
    }

    public void setPruneChild(boolean z) {
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1005;
        int i = gridLayoutManager.f601;
        if (((i & 65536) != 0) != z) {
            gridLayoutManager.f601 = (i & (-65537)) | (z ? 65536 : 0);
            if (z) {
                gridLayoutManager.m5982();
            }
        }
    }

    public final void setSaveChildrenLimitNumber(int i) {
        androidx.leanback.widget.C0121 c0121 = this.f1005.f627;
        c0121.f957 = i;
        c0121.m625();
    }

    public final void setSaveChildrenPolicy(int i) {
        androidx.leanback.widget.C0121 c0121 = this.f1005.f627;
        c0121.f956 = i;
        c0121.m625();
    }

    public void setScrollEnabled(boolean z) {
        int i;
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1005;
        int i2 = gridLayoutManager.f601;
        if (((i2 & 131072) != 0) != z) {
            int i3 = (i2 & (-131073)) | (z ? 131072 : 0);
            gridLayoutManager.f601 = i3;
            if ((i3 & 131072) == 0 || gridLayoutManager.f605 != 0 || (i = gridLayoutManager.f613) == -1) {
                return;
            }
            gridLayoutManager.m509(i, gridLayoutManager.f624, true);
        }
    }

    public void setSelectedPosition(int i) {
        this.f1005.m501(i, false);
    }

    public void setSelectedPositionSmooth(int i) {
        this.f1005.m501(i, true);
    }

    public final void setSmoothScrollByBehavior(androidx.leanback.widget.InterfaceC0141 interfaceC0141) {
    }

    public final void setSmoothScrollMaxPendingMoves(int i) {
        this.f1005.f636 = i;
    }

    public final void setSmoothScrollSpeedFactor(float f) {
        this.f1005.f600 = f;
    }

    @java.lang.Deprecated
    public void setVerticalMargin(int i) {
        setVerticalSpacing(i);
    }

    public void setVerticalSpacing(int i) {
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1005;
        if (gridLayoutManager.f620 == 1) {
            gridLayoutManager.f614 = i;
            gridLayoutManager.f599 = i;
        } else {
            gridLayoutManager.f614 = i;
            gridLayoutManager.f622 = i;
        }
        requestLayout();
    }

    public void setWindowAlignment(int i) {
        ((androidx.leanback.widget.C0091) this.f1005.f606.ˈٴ).f859 = i;
        requestLayout();
    }

    public void setWindowAlignmentOffset(int i) {
        ((androidx.leanback.widget.C0091) this.f1005.f606.ˈٴ).f854 = i;
        requestLayout();
    }

    public void setWindowAlignmentOffsetPercent(float f) {
        androidx.leanback.widget.C0091 c0091 = (androidx.leanback.widget.C0091) this.f1005.f606.ˈٴ;
        c0091.getClass();
        if ((f < 0.0f || f > 100.0f) && f != -1.0f) {
            throw new java.lang.IllegalArgumentException();
        }
        c0091.f855 = f;
        requestLayout();
    }

    public void setWindowAlignmentPreferKeyLineOverHighEdge(boolean z) {
        androidx.leanback.widget.C0091 c0091 = (androidx.leanback.widget.C0091) this.f1005.f606.ˈٴ;
        c0091.f852 = z ? c0091.f852 | 2 : c0091.f852 & (-3);
        requestLayout();
    }

    public void setWindowAlignmentPreferKeyLineOverLowEdge(boolean z) {
        androidx.leanback.widget.C0091 c0091 = (androidx.leanback.widget.C0091) this.f1005.f606.ˈٴ;
        c0091.f852 = z ? c0091.f852 | 1 : c0091.f852 & (-2);
        requestLayout();
    }

    @Override // androidx.recyclerview.widget.RecyclerView
    /* renamed from: ʻˋ, reason: contains not printable characters */
    public final void mo652(int i, int i2) {
        m968(i, i2, false);
    }

    /* renamed from: ʼـ, reason: contains not printable characters */
    public final void m653(int i, androidx.leanback.widget.InterfaceC0112 interfaceC0112) {
        p179.AbstractC2673 abstractC2673M979 = m979(i, false);
        if (abstractC2673M979 == null || m960()) {
            androidx.leanback.widget.C0148 c0148 = new androidx.leanback.widget.C0148((androidx.leanback.widget.VerticalGridView) this, i, interfaceC0112);
            androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1005;
            if (gridLayoutManager.f630 == null) {
                gridLayoutManager.f630 = new java.util.ArrayList();
            }
            gridLayoutManager.f630.add(c0148);
        } else {
            interfaceC0112.mo578(abstractC2673M979);
        }
        setSelectedPosition(i);
    }

    /* renamed from: ˑ, reason: contains not printable characters */
    public final void m654(android.content.Context context, android.util.AttributeSet attributeSet) {
        android.content.res.TypedArray typedArrayObtainStyledAttributes = context.obtainStyledAttributes(attributeSet, androidx.leanback.widget.AbstractC0130.f973);
        boolean z = typedArrayObtainStyledAttributes.getBoolean(4, false);
        boolean z2 = typedArrayObtainStyledAttributes.getBoolean(3, false);
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1005;
        gridLayoutManager.f601 = (z ? 2048 : 0) | (gridLayoutManager.f601 & (-6145)) | (z2 ? 4096 : 0);
        boolean z3 = typedArrayObtainStyledAttributes.getBoolean(6, true);
        boolean z4 = typedArrayObtainStyledAttributes.getBoolean(5, true);
        androidx.leanback.widget.GridLayoutManager gridLayoutManager2 = this.f1005;
        gridLayoutManager2.f601 = (z3 ? 8192 : 0) | (gridLayoutManager2.f601 & (-24577)) | (z4 ? 16384 : 0);
        int dimensionPixelSize = typedArrayObtainStyledAttributes.getDimensionPixelSize(2, typedArrayObtainStyledAttributes.getDimensionPixelSize(8, 0));
        if (gridLayoutManager2.f620 == 1) {
            gridLayoutManager2.f614 = dimensionPixelSize;
            gridLayoutManager2.f599 = dimensionPixelSize;
        } else {
            gridLayoutManager2.f614 = dimensionPixelSize;
            gridLayoutManager2.f622 = dimensionPixelSize;
        }
        androidx.leanback.widget.GridLayoutManager gridLayoutManager3 = this.f1005;
        int dimensionPixelSize2 = typedArrayObtainStyledAttributes.getDimensionPixelSize(1, typedArrayObtainStyledAttributes.getDimensionPixelSize(7, 0));
        if (gridLayoutManager3.f620 == 0) {
            gridLayoutManager3.f616 = dimensionPixelSize2;
            gridLayoutManager3.f599 = dimensionPixelSize2;
        } else {
            gridLayoutManager3.f616 = dimensionPixelSize2;
            gridLayoutManager3.f622 = dimensionPixelSize2;
        }
        if (typedArrayObtainStyledAttributes.hasValue(0)) {
            setGravity(typedArrayObtainStyledAttributes.getInt(0, 0));
        }
        typedArrayObtainStyledAttributes.recycle();
    }

    @Override // androidx.recyclerview.widget.RecyclerView
    /* renamed from: ˑʼ, reason: contains not printable characters */
    public final void mo655(int i, int i2) {
        m968(i, i2, false);
    }

    @Override // androidx.recyclerview.widget.RecyclerView
    /* renamed from: ᵎʻ, reason: contains not printable characters */
    public final void mo656(int i) {
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1005;
        if ((gridLayoutManager.f601 & 64) != 0) {
            gridLayoutManager.m501(i, false);
        } else {
            super.mo656(i);
        }
    }

    @Override // androidx.recyclerview.widget.RecyclerView
    /* renamed from: ﹶᐧ, reason: contains not printable characters */
    public final void mo657(int i) {
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1005;
        if ((gridLayoutManager.f601 & 64) != 0) {
            gridLayoutManager.m501(i, false);
        } else {
            super.mo657(i);
        }
    }
}
