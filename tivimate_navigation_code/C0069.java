package androidx.leanback.app;

/* renamed from: androidx.leanback.app.ʽ, reason: contains not printable characters */
/* loaded from: classes.dex */
public class C0069 extends p229.AbstractComponentCallbacksC3123 {

    /* renamed from: ʻʿ, reason: contains not printable characters */
    public com.google.android.gms.internal.measurement.C0344 f527;

    /* renamed from: ʻᴵ, reason: contains not printable characters */
    public androidx.leanback.widget.ʻٴ f528;

    /* renamed from: ʿـ, reason: contains not printable characters */
    public androidx.leanback.widget.C0108 f529;

    /* renamed from: ـˊ, reason: contains not printable characters */
    public androidx.leanback.widget.C0117 f530;

    /* renamed from: ᐧˎ, reason: contains not printable characters */
    public android.view.ContextThemeWrapper f532;

    /* renamed from: ᵎʿ, reason: contains not printable characters */
    public androidx.leanback.widget.C0117 f533;

    /* renamed from: ⁱי, reason: contains not printable characters */
    public androidx.leanback.widget.C0108 f534;

    /* renamed from: ﹳⁱ, reason: contains not printable characters */
    public androidx.leanback.widget.C0108 f535;

    /* renamed from: ﹶ, reason: contains not printable characters */
    public java.util.ArrayList f536 = new java.util.ArrayList();

    /* renamed from: ـᵢ, reason: contains not printable characters */
    public java.util.ArrayList f531 = new java.util.ArrayList();

    public C0069() {
        m427();
    }

    /* renamed from: ˈـ, reason: contains not printable characters */
    public static void m415(p363.AbstractActivityC4410 abstractActivityC4410, ʼⁱ.ˉʿ r3) {
        abstractActivityC4410.getWindow().getDecorView();
        p229.C3085 c3085M8914 = abstractActivityC4410.m8914();
        if (c3085M8914.m6697("leanBackGuidedStepSupportFragment") != null) {
            return;
        }
        p229.C3137 c3137 = new p229.C3137(c3085M8914);
        r3.m437(2);
        c3137.m6889(android.R.id.content, r3, "leanBackGuidedStepSupportFragment");
        c3137.m6886(false, true);
    }

    /* renamed from: ˋـ, reason: contains not printable characters */
    public static boolean m416(androidx.leanback.widget.C0095 c0095) {
        return (c0095.f875 & 64) == 64 && c0095.f880 != -1;
    }

    /* renamed from: ˎʾ, reason: contains not printable characters */
    public static void m417(p229.C3137 c3137, android.view.View view, java.lang.String str) {
        if (view != null) {
            p229.C3139 c3139 = p229.AbstractC3100.f11812;
            java.util.WeakHashMap weakHashMap = p186.AbstractC2823.f10603;
            java.lang.String strM6176 = p186.AbstractC2776.m6176(view);
            if (strM6176 == null) {
                throw new java.lang.IllegalArgumentException("Unique transitionNames are required for all sharedElements");
            }
            if (c3137.f12007 == null) {
                c3137.f12007 = new java.util.ArrayList();
                c3137.f12001 = new java.util.ArrayList();
            } else {
                if (c3137.f12001.contains(str)) {
                    throw new java.lang.IllegalArgumentException(p137.AbstractC2305.m5378("A shared element with the target name '", str, "' has already been added to the transaction."));
                }
                if (c3137.f12007.contains(strM6176)) {
                    throw new java.lang.IllegalArgumentException(p137.AbstractC2305.m5378("A shared element with the source name '", strM6176, "' has already been added to the transaction."));
                }
            }
            c3137.f12007.add(strM6176);
            c3137.f12001.add(str);
        }
    }

    /* renamed from: ᵢˋ, reason: contains not printable characters */
    public static boolean m418(android.content.Context context) {
        android.util.TypedValue typedValue = new android.util.TypedValue();
        return context.getTheme().resolveAttribute(ar.tvplayer.tv.R.attr._14n_res_0x7f0402f6, typedValue, true) && typedValue.type == 18 && typedValue.data != 0;
    }

    /* renamed from: ﾞˋ, reason: contains not printable characters */
    public static void m419(p229.C3085 c3085, androidx.leanback.app.C0069 c0069) {
        p229.AbstractComponentCallbacksC3123 abstractComponentCallbacksC3123M6697 = c3085.m6697("leanBackGuidedStepSupportFragment");
        androidx.leanback.app.C0069 c00692 = abstractComponentCallbacksC3123M6697 instanceof androidx.leanback.app.C0069 ? (androidx.leanback.app.C0069) abstractComponentCallbacksC3123M6697 : null;
        int i = c00692 != null ? 1 : 0;
        p229.C3137 c3137 = new p229.C3137(c3085);
        c0069.m437(i ^ 1);
        android.os.Bundle bundle = c0069.f11906;
        int i2 = bundle == null ? 1 : bundle.getInt("uiStyle", 1);
        java.lang.Class<?> cls = c0069.getClass();
        c3137.m6880(i2 != 0 ? i2 != 1 ? "" : "GuidedStepEntrance".concat(cls.getName()) : "GuidedStepDefault".concat(cls.getName()));
        if (c00692 != null) {
            android.view.View view = c00692.f11908;
            m417(c3137, view.findViewById(ar.tvplayer.tv.R.id._3l7_res_0x7f0b0047), "action_fragment_root");
            m417(c3137, view.findViewById(ar.tvplayer.tv.R.id._3p6_res_0x7f0b0046), "action_fragment_background");
            m417(c3137, view.findViewById(ar.tvplayer.tv.R.id._51c_res_0x7f0b0045), "action_fragment");
            m417(c3137, view.findViewById(ar.tvplayer.tv.R.id._3kv_res_0x7f0b01c9), "guidedactions_root");
            m417(c3137, view.findViewById(ar.tvplayer.tv.R.id._25n_res_0x7f0b01bd), "guidedactions_content");
            m417(c3137, view.findViewById(ar.tvplayer.tv.R.id.o3), "guidedactions_list_background");
            m417(c3137, view.findViewById(ar.tvplayer.tv.R.id._5vf_res_0x7f0b01ca), "guidedactions_root2");
            m417(c3137, view.findViewById(ar.tvplayer.tv.R.id._3e1_res_0x7f0b01be), "guidedactions_content2");
            m417(c3137, view.findViewById(ar.tvplayer.tv.R.id._279_res_0x7f0b01c8), "guidedactions_list_background2");
        }
        c3137.m6889(android.R.id.content, c0069, "leanBackGuidedStepSupportFragment");
        c3137.m6886(false, true);
    }

    /* renamed from: ʽʾ, reason: contains not printable characters */
    public final void m420(androidx.leanback.widget.C0095 c0095) {
        androidx.leanback.widget.C0117 c0117 = this.f530;
        androidx.leanback.widget.C0108 c0108 = (androidx.leanback.widget.C0108) c0117.f944.getAdapter();
        c0108.getClass();
        int iIndexOf = new java.util.ArrayList(c0108.f909).indexOf(c0095);
        if (iIndexOf < 0 || !c0095.m579()) {
            return;
        }
        c0117.f944.m653(iIndexOf, new androidx.leanback.widget.C0094(c0108));
    }

    @Override // p229.AbstractComponentCallbacksC3123
    /* renamed from: ʽᵔ, reason: contains not printable characters */
    public void mo421(android.os.Bundle bundle) {
        super.mo421(bundle);
        this.f528 = new androidx.leanback.widget.ʻٴ(0);
        this.f530 = m434();
        this.f533 = m426();
        m427();
        java.util.ArrayList arrayList = new java.util.ArrayList();
        m436(arrayList);
        if (bundle != null) {
            int size = arrayList.size();
            for (int i = 0; i < size; i++) {
                androidx.leanback.widget.C0095 c0095 = (androidx.leanback.widget.C0095) arrayList.get(i);
                if (m416(c0095)) {
                    c0095.m581("action_" + c0095.f880, bundle);
                }
            }
        }
        m430(arrayList);
        java.util.ArrayList arrayList2 = new java.util.ArrayList();
        m440(arrayList2);
        if (bundle != null) {
            int size2 = arrayList2.size();
            for (int i2 = 0; i2 < size2; i2++) {
                androidx.leanback.widget.C0095 c00952 = (androidx.leanback.widget.C0095) arrayList2.get(i2);
                if (m416(c00952)) {
                    c00952.m581("buttonaction_" + c00952.f880, bundle);
                }
            }
        }
        this.f531 = arrayList2;
        androidx.leanback.widget.C0108 c0108 = this.f534;
        if (c0108 != null) {
            c0108.m608(arrayList2);
        }
    }

    @Override // p229.AbstractComponentCallbacksC3123
    /* renamed from: ʽⁱ, reason: contains not printable characters */
    public final void mo422() {
        this.f11926 = true;
        this.f11908.findViewById(ar.tvplayer.tv.R.id._51c_res_0x7f0b0045).requestFocus();
    }

    @Override // p229.AbstractComponentCallbacksC3123
    /* renamed from: ʾˊ, reason: contains not printable characters */
    public final void mo423() {
        androidx.leanback.widget.ʻٴ r0 = this.f528;
        r0.ᴵᵔ = null;
        r0.ˈٴ = null;
        r0.ˊʻ = null;
        r0.ʽʽ = null;
        r0.ᴵˊ = null;
        androidx.leanback.widget.C0117 c0117 = this.f530;
        c0117.f946 = null;
        c0117.f938 = null;
        c0117.f944 = null;
        c0117.f931 = null;
        c0117.f933 = null;
        c0117.f937 = null;
        c0117.f945 = null;
        androidx.leanback.widget.C0117 c01172 = this.f533;
        c01172.f946 = null;
        c01172.f938 = null;
        c01172.f944 = null;
        c01172.f931 = null;
        c01172.f933 = null;
        c01172.f937 = null;
        c01172.f945 = null;
        this.f529 = null;
        this.f535 = null;
        this.f534 = null;
        this.f527 = null;
        this.f11926 = true;
    }

    @Override // p229.AbstractComponentCallbacksC3123
    /* renamed from: ʾﾞ, reason: contains not printable characters */
    public void mo424(android.os.Bundle bundle) {
        java.util.ArrayList arrayList = this.f536;
        int size = arrayList.size();
        for (int i = 0; i < size; i++) {
            androidx.leanback.widget.C0095 c0095 = (androidx.leanback.widget.C0095) arrayList.get(i);
            if (m416(c0095)) {
                c0095.m586("action_" + c0095.f880, bundle);
            }
        }
        java.util.ArrayList arrayList2 = this.f531;
        int size2 = arrayList2.size();
        for (int i2 = 0; i2 < size2; i2++) {
            androidx.leanback.widget.C0095 c00952 = (androidx.leanback.widget.C0095) arrayList2.get(i2);
            if (m416(c00952)) {
                c00952.m586("buttonaction_" + c00952.f880, bundle);
            }
        }
    }

    /* renamed from: ˆˑ, reason: contains not printable characters */
    public final void m425(boolean z) {
        java.util.ArrayList arrayList = new java.util.ArrayList();
        if (z) {
            this.f528.getClass();
            this.f530.getClass();
            this.f533.getClass();
        } else {
            this.f528.getClass();
            this.f530.getClass();
            this.f533.getClass();
        }
        android.animation.AnimatorSet animatorSet = new android.animation.AnimatorSet();
        animatorSet.playTogether(arrayList);
        animatorSet.start();
    }

    /* renamed from: ˊˊ, reason: contains not printable characters */
    public androidx.leanback.widget.C0117 m426() {
        androidx.leanback.widget.C0117 c0117 = new androidx.leanback.widget.C0117();
        if (c0117.f945 != null) {
            throw new java.lang.IllegalStateException("setAsButtonActions() must be called before creating views");
        }
        c0117.f948 = true;
        return c0117;
    }

    /* renamed from: ˊﹳ, reason: contains not printable characters */
    public void m427() {
        android.os.Bundle bundle = this.f11906;
        int i = bundle == null ? 1 : bundle.getInt("uiStyle", 1);
        if (i == 0) {
            androidx.leanback.transition.FadeAndShortSlide fadeAndShortSlide = new androidx.leanback.transition.FadeAndShortSlide(8388613);
            fadeAndShortSlide.excludeTarget(ar.tvplayer.tv.R.id._74r_res_0x7f0b01cd, true);
            fadeAndShortSlide.excludeTarget(ar.tvplayer.tv.R.id.i4, true);
            m6811(fadeAndShortSlide);
            android.transition.Fade fade = new android.transition.Fade(3);
            fade.addTarget(ar.tvplayer.tv.R.id.i4);
            androidx.leanback.transition.C0079 c0079 = new androidx.leanback.transition.C0079();
            c0079.setReparent(false);
            android.transition.TransitionSet transitionSet = new android.transition.TransitionSet();
            transitionSet.setOrdering(0);
            transitionSet.addTransition(fade);
            transitionSet.addTransition(c0079);
            m6787().f11871 = transitionSet;
        } else if (i == 1) {
            android.transition.Fade fade2 = new android.transition.Fade(3);
            fade2.addTarget(ar.tvplayer.tv.R.id._74r_res_0x7f0b01cd);
            androidx.leanback.transition.FadeAndShortSlide fadeAndShortSlide2 = new androidx.leanback.transition.FadeAndShortSlide(8388615);
            fadeAndShortSlide2.addTarget(ar.tvplayer.tv.R.id._734_res_0x7f0b00f7);
            fadeAndShortSlide2.addTarget(ar.tvplayer.tv.R.id._3l7_res_0x7f0b0047);
            android.transition.TransitionSet transitionSet2 = new android.transition.TransitionSet();
            transitionSet2.setOrdering(0);
            transitionSet2.addTransition(fade2);
            transitionSet2.addTransition(fadeAndShortSlide2);
            m6811(transitionSet2);
            m6787().f11871 = null;
        } else if (i == 2) {
            m6811(null);
            m6787().f11871 = null;
        }
        androidx.leanback.transition.FadeAndShortSlide fadeAndShortSlide3 = new androidx.leanback.transition.FadeAndShortSlide(8388611);
        fadeAndShortSlide3.excludeTarget(ar.tvplayer.tv.R.id._74r_res_0x7f0b01cd, true);
        fadeAndShortSlide3.excludeTarget(ar.tvplayer.tv.R.id.i4, true);
        m6783(fadeAndShortSlide3);
    }

    /* renamed from: ˊﾞ, reason: contains not printable characters */
    public ˏˆ.ﹳٴ m428() {
        return new ˏˆ.ﹳٴ("", "", "", (java.lang.Object) null, 1);
    }

    /* renamed from: ˎˉ, reason: contains not printable characters */
    public final int m429(long j) {
        if (this.f536 == null) {
            return -1;
        }
        for (int i = 0; i < this.f536.size(); i++) {
            if (((androidx.leanback.widget.C0095) this.f536.get(i)).f880 == j) {
                return i;
            }
        }
        return -1;
    }

    /* renamed from: ˎـ, reason: contains not printable characters */
    public final void m430(java.util.ArrayList arrayList) {
        this.f536 = arrayList;
        androidx.leanback.widget.C0108 c0108 = this.f529;
        if (c0108 != null) {
            c0108.m608(arrayList);
        }
    }

    /* renamed from: ˏⁱ, reason: contains not printable characters */
    public long m431(androidx.leanback.widget.C0095 c0095) {
        return -2L;
    }

    /* renamed from: ˑˆ, reason: contains not printable characters */
    public final androidx.leanback.widget.C0095 m432(long j) {
        int iM429 = m429(j);
        if (iM429 >= 0) {
            return (androidx.leanback.widget.C0095) this.f536.get(iM429);
        }
        return null;
    }

    /* renamed from: ـʻ, reason: contains not printable characters */
    public void m433(androidx.leanback.widget.C0095 c0095) {
    }

    /* renamed from: ٴʿ, reason: contains not printable characters */
    public androidx.leanback.widget.C0117 m434() {
        return new androidx.leanback.widget.C0117();
    }

    @Override // p229.AbstractComponentCallbacksC3123
    /* renamed from: ᐧﹶ, reason: contains not printable characters */
    public final android.view.View mo435(android.view.LayoutInflater layoutInflater, android.view.ViewGroup viewGroup, android.os.Bundle bundle) throws android.content.res.Resources.NotFoundException {
        android.content.Context contextMo4203 = mo4203();
        if (!m418(contextMo4203)) {
            android.util.TypedValue typedValue = new android.util.TypedValue();
            boolean zResolveAttribute = contextMo4203.getTheme().resolveAttribute(ar.tvplayer.tv.R.attr._65l_res_0x7f0402f5, typedValue, true);
            if (zResolveAttribute) {
                android.view.ContextThemeWrapper contextThemeWrapper = new android.view.ContextThemeWrapper(contextMo4203, typedValue.resourceId);
                if (m418(contextThemeWrapper)) {
                    this.f532 = contextThemeWrapper;
                } else {
                    this.f532 = null;
                    zResolveAttribute = false;
                }
            }
            if (!zResolveAttribute) {
            }
        }
        android.view.ContextThemeWrapper contextThemeWrapper2 = this.f532;
        android.view.LayoutInflater layoutInflaterCloneInContext = contextThemeWrapper2 == null ? layoutInflater : layoutInflater.cloneInContext(contextThemeWrapper2);
        androidx.leanback.app.GuidedStepRootLayout guidedStepRootLayout = (androidx.leanback.app.GuidedStepRootLayout) layoutInflaterCloneInContext.inflate(ar.tvplayer.tv.R.layout._3rl_res_0x7f0e00a7, viewGroup, false);
        guidedStepRootLayout.getClass();
        android.view.ViewGroup viewGroup2 = (android.view.ViewGroup) guidedStepRootLayout.findViewById(ar.tvplayer.tv.R.id._734_res_0x7f0b00f7);
        android.view.ViewGroup viewGroup3 = (android.view.ViewGroup) guidedStepRootLayout.findViewById(ar.tvplayer.tv.R.id._51c_res_0x7f0b0045);
        ((androidx.leanback.widget.NonOverlappingLinearLayout) viewGroup3).setFocusableViewAvailableFixEnabled(true);
        ˏˆ.ﹳٴ r2 = m428();
        java.lang.String str = (java.lang.String) r2.ʽʽ;
        java.lang.String str2 = (java.lang.String) r2.ᴵˊ;
        java.lang.String str3 = (java.lang.String) r2.ˈٴ;
        androidx.leanback.widget.ʻٴ r12 = this.f528;
        r12.getClass();
        android.view.View viewInflate = layoutInflaterCloneInContext.inflate(ar.tvplayer.tv.R.layout._33m_res_0x7f0e00a1, viewGroup2, false);
        r12.ʽʽ = (android.widget.TextView) viewInflate.findViewById(ar.tvplayer.tv.R.id._1qa_res_0x7f0b01bb);
        r12.ᴵᵔ = (android.widget.TextView) viewInflate.findViewById(ar.tvplayer.tv.R.id._74g_res_0x7f0b01b7);
        r12.ˈٴ = (android.widget.TextView) viewInflate.findViewById(ar.tvplayer.tv.R.id._72j_res_0x7f0b01b9);
        r12.ˊʻ = (android.widget.ImageView) viewInflate.findViewById(ar.tvplayer.tv.R.id._1kv_res_0x7f0b01ba);
        r12.ᴵˊ = viewInflate.findViewById(ar.tvplayer.tv.R.id._6ds_res_0x7f0b01b8);
        android.widget.TextView textView = (android.widget.TextView) r12.ʽʽ;
        if (textView != null) {
            textView.setText(str2);
        }
        android.widget.TextView textView2 = (android.widget.TextView) r12.ᴵᵔ;
        if (textView2 != null) {
            textView2.setText(str3);
        }
        android.widget.TextView textView3 = (android.widget.TextView) r12.ˈٴ;
        if (textView3 != null) {
            textView3.setText(str);
        }
        android.widget.ImageView imageView = (android.widget.ImageView) r12.ˊʻ;
        if (imageView != null) {
            android.graphics.drawable.Drawable drawable = (android.graphics.drawable.Drawable) r2.ᴵᵔ;
            if (drawable != null) {
                imageView.setImageDrawable(drawable);
            } else {
                imageView.setVisibility(8);
            }
        }
        android.view.View view = (android.view.View) r12.ᴵˊ;
        if (view != null && android.text.TextUtils.isEmpty(view.getContentDescription())) {
            java.lang.StringBuilder sb = new java.lang.StringBuilder();
            if (!android.text.TextUtils.isEmpty(str3)) {
                sb.append(str3);
                sb.append('\n');
            }
            if (!android.text.TextUtils.isEmpty(str2)) {
                sb.append(str2);
                sb.append('\n');
            }
            if (!android.text.TextUtils.isEmpty(str)) {
                sb.append(str);
                sb.append('\n');
            }
            ((android.view.View) r12.ᴵˊ).setContentDescription(sb);
        }
        viewGroup2.addView(viewInflate);
        viewGroup3.addView(this.f530.m614(layoutInflaterCloneInContext, viewGroup3));
        android.view.ViewGroup viewGroupM614 = this.f533.m614(layoutInflaterCloneInContext, viewGroup3);
        viewGroup3.addView(viewGroupM614);
        androidx.leanback.app.C0071 c0071 = new androidx.leanback.app.C0071(this);
        this.f529 = new androidx.leanback.widget.C0108(this.f536, new androidx.leanback.app.C0070(this, 0), this, this.f530, false);
        this.f534 = new androidx.leanback.widget.C0108(this.f531, new androidx.leanback.app.C0071(this), this, this.f533, false);
        this.f535 = new androidx.leanback.widget.C0108(null, new androidx.leanback.app.C0070(this, 1), this, this.f530, true);
        com.google.android.gms.internal.measurement.C0344 c0344 = new com.google.android.gms.internal.measurement.C0344(1, false);
        java.util.ArrayList arrayList = new java.util.ArrayList();
        c0344.f1997 = arrayList;
        this.f527 = c0344;
        androidx.leanback.widget.C0108 c0108 = this.f529;
        androidx.leanback.widget.C0108 c01082 = this.f534;
        arrayList.add(new android.util.Pair(c0108, c01082));
        if (c0108 != null) {
            c0108.f911 = c0344;
        }
        if (c01082 != null) {
            c01082.f911 = c0344;
        }
        com.google.android.gms.internal.measurement.C0344 c03442 = this.f527;
        androidx.leanback.widget.C0108 c01083 = this.f535;
        ((java.util.ArrayList) c03442.f1997).add(new android.util.Pair(c01083, null));
        if (c01083 != null) {
            c01083.f911 = c03442;
        }
        this.f527.f1999 = c0071;
        androidx.leanback.widget.C0117 c0117 = this.f530;
        c0117.getClass();
        c0117.f944.setAdapter(this.f529);
        androidx.leanback.widget.VerticalGridView verticalGridView = this.f530.f931;
        if (verticalGridView != null) {
            verticalGridView.setAdapter(this.f535);
        }
        this.f533.f944.setAdapter(this.f534);
        if (this.f531.size() == 0) {
            android.widget.LinearLayout.LayoutParams layoutParams = (android.widget.LinearLayout.LayoutParams) viewGroupM614.getLayoutParams();
            layoutParams.weight = 0.0f;
            viewGroupM614.setLayoutParams(layoutParams);
        } else {
            android.content.Context contextMo42032 = this.f532;
            if (contextMo42032 == null) {
                contextMo42032 = mo4203();
            }
            android.util.TypedValue typedValue2 = new android.util.TypedValue();
            if (contextMo42032.getTheme().resolveAttribute(ar.tvplayer.tv.R.attr._1ov_res_0x7f0402ce, typedValue2, true)) {
                android.view.View viewFindViewById = guidedStepRootLayout.findViewById(ar.tvplayer.tv.R.id._3l7_res_0x7f0b0047);
                float f = typedValue2.getFloat();
                android.widget.LinearLayout.LayoutParams layoutParams2 = (android.widget.LinearLayout.LayoutParams) viewFindViewById.getLayoutParams();
                layoutParams2.weight = f;
                viewFindViewById.setLayoutParams(layoutParams2);
            }
        }
        android.view.View viewInflate2 = layoutInflaterCloneInContext.inflate(ar.tvplayer.tv.R.layout.lb_guidedstep_background, (android.view.ViewGroup) guidedStepRootLayout, false);
        if (viewInflate2 != null) {
            ((android.widget.FrameLayout) guidedStepRootLayout.findViewById(ar.tvplayer.tv.R.id._3ec_res_0x7f0b01ce)).addView(viewInflate2, 0);
        }
        return guidedStepRootLayout;
    }

    /* renamed from: ᵔⁱ, reason: contains not printable characters */
    public void m436(java.util.ArrayList arrayList) {
    }

    /* renamed from: ᵢʻ, reason: contains not printable characters */
    public final void m437(int i) {
        android.os.Bundle bundle = this.f11906;
        boolean z = true;
        int i2 = bundle == null ? 1 : bundle.getInt("uiStyle", 1);
        android.os.Bundle bundle2 = this.f11906;
        if (bundle2 == null) {
            bundle2 = new android.os.Bundle();
        } else {
            z = false;
        }
        bundle2.putInt("uiStyle", i);
        if (z) {
            m6807(bundle2);
        }
        if (i != i2) {
            m427();
        }
    }

    /* renamed from: ﹳᵢ, reason: contains not printable characters */
    public final int m438(long j) {
        if (this.f531 == null) {
            return -1;
        }
        for (int i = 0; i < this.f531.size(); i++) {
            if (((androidx.leanback.widget.C0095) this.f531.get(i)).f880 == j) {
                return i;
            }
        }
        return -1;
    }

    /* renamed from: ﹶʽ, reason: contains not printable characters */
    public final void m439(int i) {
        androidx.leanback.widget.C0108 c0108 = this.f529;
        if (c0108 != null) {
            c0108.f10419.m6057(i, 1, null);
        }
    }

    /* renamed from: ﾞˏ, reason: contains not printable characters */
    public void m440(java.util.ArrayList arrayList) {
    }
}
