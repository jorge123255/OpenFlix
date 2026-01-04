package p363;

/* renamed from: ᵔᵢ.ˆʾ, reason: contains not printable characters */
/* loaded from: classes.dex */
public abstract class AbstractActivityC4410 extends p036.AbstractActivityC1262 implements p363.InterfaceC4422, p151.InterfaceC2436 {

    /* renamed from: ˈⁱ, reason: contains not printable characters */
    public boolean f16399;

    /* renamed from: ˉـ, reason: contains not printable characters */
    public p363.LayoutInflaterFactory2C4430 f16400;

    /* renamed from: ﹳـ, reason: contains not printable characters */
    public boolean f16403;

    /* renamed from: ʼˈ, reason: contains not printable characters */
    public final ˉˆ.ʿ f16398 = new ˉˆ.ʿ(21, new p229.C3114(this));

    /* renamed from: ـˏ, reason: contains not printable characters */
    public final androidx.lifecycle.C0184 f16401 = new androidx.lifecycle.C0184(this);

    /* renamed from: ᴵˑ, reason: contains not printable characters */
    public boolean f16402 = true;

    public AbstractActivityC4410() {
        ((p229.C3125) this.f4903.f13456).m6832("android:support:lifecycle", new p036.C1256(2, this));
        final int i = 0;
        m3847(new p238.InterfaceC3206(this) { // from class: ˑʼ.ˊʻ

            /* renamed from: ⁱˊ, reason: contains not printable characters */
            public final /* synthetic */ p363.AbstractActivityC4410 f11808;

            {
                this.f11808 = this;
            }

            @Override // p238.InterfaceC3206
            public final void accept(java.lang.Object obj) {
                switch (i) {
                    case 0:
                        this.f11808.f16398.ᵔٴ();
                        break;
                    default:
                        this.f11808.f16398.ᵔٴ();
                        break;
                }
            }
        });
        final int i2 = 1;
        this.f4907.add(new p238.InterfaceC3206(this) { // from class: ˑʼ.ˊʻ

            /* renamed from: ⁱˊ, reason: contains not printable characters */
            public final /* synthetic */ p363.AbstractActivityC4410 f11808;

            {
                this.f11808 = this;
            }

            @Override // p238.InterfaceC3206
            public final void accept(java.lang.Object obj) {
                switch (i2) {
                    case 0:
                        this.f11808.f16398.ᵔٴ();
                        break;
                    default:
                        this.f11808.f16398.ᵔٴ();
                        break;
                }
            }
        });
        m3848(new p036.C1260(this, 1));
        ((p229.C3125) this.f4903.f13456).m6832("androidx:appcompat", new p333.C4205(this));
        m3848(new p363.C4403(this));
    }

    /* renamed from: ﾞʻ, reason: contains not printable characters */
    public static boolean m8909(p229.C3085 c3085) {
        boolean zM8909 = false;
        for (p229.AbstractComponentCallbacksC3123 abstractComponentCallbacksC3123 : c3085.f11725.ʾᵎ()) {
            if (abstractComponentCallbacksC3123 != null) {
                p229.C3114 c3114 = abstractComponentCallbacksC3123.f11936;
                if ((c3114 == null ? null : c3114.f11852) != null) {
                    zM8909 |= m8909(abstractComponentCallbacksC3123.m6788());
                }
                p229.C3115 c3115 = abstractComponentCallbacksC3123.f11915;
                androidx.lifecycle.EnumC0199 enumC0199 = androidx.lifecycle.EnumC0199.f1100;
                androidx.lifecycle.EnumC0199 enumC01992 = androidx.lifecycle.EnumC0199.f1102;
                if (c3115 != null && c3115.mo691().f1076.m733(enumC01992)) {
                    androidx.lifecycle.C0184 c0184 = abstractComponentCallbacksC3123.f11915.f11856;
                    c0184.m709("setCurrentState");
                    c0184.m711(enumC0199);
                    zM8909 = true;
                }
                if (abstractComponentCallbacksC3123.f11924.f1076.m733(enumC01992)) {
                    androidx.lifecycle.C0184 c01842 = abstractComponentCallbacksC3123.f11924;
                    c01842.m709("setCurrentState");
                    c01842.m711(enumC0199);
                    zM8909 = true;
                }
            }
        }
        return zM8909;
    }

    @Override // p036.AbstractActivityC1262, android.app.Activity
    public final void addContentView(android.view.View view, android.view.ViewGroup.LayoutParams layoutParams) throws java.lang.IllegalAccessException, java.lang.NoSuchMethodException, java.lang.SecurityException, java.lang.IllegalArgumentException, java.lang.reflect.InvocationTargetException {
        m3850();
        p363.LayoutInflaterFactory2C4430 layoutInflaterFactory2C4430 = (p363.LayoutInflaterFactory2C4430) m8911();
        layoutInflaterFactory2C4430.m8951();
        ((android.view.ViewGroup) layoutInflaterFactory2C4430.f16523.findViewById(android.R.id.content)).addView(view, layoutParams);
        layoutInflaterFactory2C4430.f16499.m8904(layoutInflaterFactory2C4430.f16530.getCallback());
    }

    @Override // android.app.Activity, android.view.ContextThemeWrapper, android.content.ContextWrapper
    public void attachBaseContext(android.content.Context context) {
        p363.LayoutInflaterFactory2C4430 layoutInflaterFactory2C4430 = (p363.LayoutInflaterFactory2C4430) m8911();
        layoutInflaterFactory2C4430.f16516 = true;
        int i = layoutInflaterFactory2C4430.f16494;
        if (i == -100) {
            i = p363.AbstractC4427.f16477;
        }
        int iM8953 = layoutInflaterFactory2C4430.m8953(context, i);
        if (p363.AbstractC4427.m8933(context) && p363.AbstractC4427.m8933(context)) {
            if (android.os.Build.VERSION.SDK_INT < 33) {
                synchronized (p363.AbstractC4427.f16479) {
                    try {
                        p114.C1981 c1981 = p363.AbstractC4427.f16471;
                        if (c1981 == null) {
                            if (p363.AbstractC4427.f16473 == null) {
                                p363.AbstractC4427.f16473 = p114.C1981.m4966(p151.AbstractC2427.m5536(context));
                            }
                            if (!p363.AbstractC4427.f16473.f7840.isEmpty()) {
                                p363.AbstractC4427.f16471 = p363.AbstractC4427.f16473;
                            }
                        } else if (!c1981.equals(p363.AbstractC4427.f16473)) {
                            p114.C1981 c19812 = p363.AbstractC4427.f16471;
                            p363.AbstractC4427.f16473 = c19812;
                            p151.AbstractC2427.m5535(context, c19812.f7840.mo4969());
                        }
                    } finally {
                    }
                }
            } else if (!p363.AbstractC4427.f16475) {
                p363.AbstractC4427.f16472.execute(new p000.RunnableC0759(context, 2));
            }
        }
        p114.C1981 c1981M8949 = p363.LayoutInflaterFactory2C4430.m8949(context);
        android.content.res.Configuration configuration = null;
        if (context instanceof android.view.ContextThemeWrapper) {
            try {
                ((android.view.ContextThemeWrapper) context).applyOverrideConfiguration(p363.LayoutInflaterFactory2C4430.m8950(context, iM8953, c1981M8949, null, false));
            } catch (java.lang.IllegalStateException unused) {
            }
        } else if (context instanceof p136.C2219) {
            try {
                ((p136.C2219) context).m5207(p363.LayoutInflaterFactory2C4430.m8950(context, iM8953, c1981M8949, null, false));
            } catch (java.lang.IllegalStateException unused2) {
            }
        } else if (p363.LayoutInflaterFactory2C4430.f16485) {
            android.content.res.Configuration configuration2 = new android.content.res.Configuration();
            configuration2.uiMode = -1;
            configuration2.fontScale = 0.0f;
            android.content.res.Configuration configuration3 = context.createConfigurationContext(configuration2).getResources().getConfiguration();
            android.content.res.Configuration configuration4 = context.getResources().getConfiguration();
            configuration3.uiMode = configuration4.uiMode;
            if (!configuration3.equals(configuration4)) {
                configuration = new android.content.res.Configuration();
                configuration.fontScale = 0.0f;
                if (configuration3.diff(configuration4) != 0) {
                    float f = configuration3.fontScale;
                    float f2 = configuration4.fontScale;
                    if (f != f2) {
                        configuration.fontScale = f2;
                    }
                    int i2 = configuration3.mcc;
                    int i3 = configuration4.mcc;
                    if (i2 != i3) {
                        configuration.mcc = i3;
                    }
                    int i4 = configuration3.mnc;
                    int i5 = configuration4.mnc;
                    if (i4 != i5) {
                        configuration.mnc = i5;
                    }
                    int i6 = android.os.Build.VERSION.SDK_INT;
                    if (i6 >= 24) {
                        p363.AbstractC4417.m8923(configuration3, configuration4, configuration);
                    } else if (!j$.util.Objects.equals(configuration3.locale, configuration4.locale)) {
                        configuration.locale = configuration4.locale;
                    }
                    int i7 = configuration3.touchscreen;
                    int i8 = configuration4.touchscreen;
                    if (i7 != i8) {
                        configuration.touchscreen = i8;
                    }
                    int i9 = configuration3.keyboard;
                    int i10 = configuration4.keyboard;
                    if (i9 != i10) {
                        configuration.keyboard = i10;
                    }
                    int i11 = configuration3.keyboardHidden;
                    int i12 = configuration4.keyboardHidden;
                    if (i11 != i12) {
                        configuration.keyboardHidden = i12;
                    }
                    int i13 = configuration3.navigation;
                    int i14 = configuration4.navigation;
                    if (i13 != i14) {
                        configuration.navigation = i14;
                    }
                    int i15 = configuration3.navigationHidden;
                    int i16 = configuration4.navigationHidden;
                    if (i15 != i16) {
                        configuration.navigationHidden = i16;
                    }
                    int i17 = configuration3.orientation;
                    int i18 = configuration4.orientation;
                    if (i17 != i18) {
                        configuration.orientation = i18;
                    }
                    int i19 = configuration3.screenLayout & 15;
                    int i20 = configuration4.screenLayout & 15;
                    if (i19 != i20) {
                        configuration.screenLayout |= i20;
                    }
                    int i21 = configuration3.screenLayout & 192;
                    int i22 = configuration4.screenLayout & 192;
                    if (i21 != i22) {
                        configuration.screenLayout |= i22;
                    }
                    int i23 = configuration3.screenLayout & 48;
                    int i24 = configuration4.screenLayout & 48;
                    if (i23 != i24) {
                        configuration.screenLayout |= i24;
                    }
                    int i25 = configuration3.screenLayout & 768;
                    int i26 = configuration4.screenLayout & 768;
                    if (i25 != i26) {
                        configuration.screenLayout |= i26;
                    }
                    if (i6 >= 26) {
                        ˑˊ.ﹳٴ.ʽ(configuration3, configuration4, configuration);
                    }
                    int i27 = configuration3.uiMode & 15;
                    int i28 = configuration4.uiMode & 15;
                    if (i27 != i28) {
                        configuration.uiMode |= i28;
                    }
                    int i29 = configuration3.uiMode & 48;
                    int i30 = configuration4.uiMode & 48;
                    if (i29 != i30) {
                        configuration.uiMode |= i30;
                    }
                    int i31 = configuration3.screenWidthDp;
                    int i32 = configuration4.screenWidthDp;
                    if (i31 != i32) {
                        configuration.screenWidthDp = i32;
                    }
                    int i33 = configuration3.screenHeightDp;
                    int i34 = configuration4.screenHeightDp;
                    if (i33 != i34) {
                        configuration.screenHeightDp = i34;
                    }
                    int i35 = configuration3.smallestScreenWidthDp;
                    int i36 = configuration4.smallestScreenWidthDp;
                    if (i35 != i36) {
                        configuration.smallestScreenWidthDp = i36;
                    }
                    int i37 = configuration3.densityDpi;
                    int i38 = configuration4.densityDpi;
                    if (i37 != i38) {
                        configuration.densityDpi = i38;
                    }
                }
            }
            android.content.res.Configuration configurationM8950 = p363.LayoutInflaterFactory2C4430.m8950(context, iM8953, c1981M8949, configuration, true);
            p136.C2219 c2219 = new p136.C2219(context, ar.tvplayer.tv.R.style._5iv_res_0x7f14031c);
            c2219.m5207(configurationM8950);
            try {
                if (context.getTheme() != null) {
                    p143.AbstractC2392.m5488(c2219.getTheme());
                }
            } catch (java.lang.NullPointerException unused3) {
            }
            context = c2219;
        }
        super.attachBaseContext(context);
    }

    @Override // android.app.Activity
    public final void closeOptionsMenu() throws java.lang.IllegalAccessException, java.lang.NoSuchMethodException, java.lang.SecurityException, java.lang.IllegalArgumentException, java.lang.reflect.InvocationTargetException {
        ((p363.LayoutInflaterFactory2C4430) m8911()).m8955();
        if (getWindow().hasFeature(0)) {
            super.closeOptionsMenu();
        }
    }

    @Override // p151.AbstractActivityC2438, android.app.Activity, android.view.Window.Callback
    public boolean dispatchKeyEvent(android.view.KeyEvent keyEvent) throws java.lang.IllegalAccessException, java.lang.NoSuchMethodException, java.lang.SecurityException, java.lang.IllegalArgumentException, java.lang.reflect.InvocationTargetException {
        keyEvent.getKeyCode();
        ((p363.LayoutInflaterFactory2C4430) m8911()).m8955();
        return super.dispatchKeyEvent(keyEvent);
    }

    /* JADX WARN: Can't fix incorrect switch cases order, some code will duplicate */
    /* JADX WARN: Failed to restore switch over string. Please report as a decompilation issue */
    /* JADX WARN: Removed duplicated region for block: B:28:0x0046  */
    @Override // android.app.Activity
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct add '--show-bad-code' argument
    */
    public final void dump(java.lang.String r7, java.io.FileDescriptor r8, java.io.PrintWriter r9, java.lang.String[] r10) {
        /*
            Method dump skipped, instructions count: 306
            To view this dump add '--comments-level debug' option
        */
        throw new UnsupportedOperationException("Method not decompiled: p363.AbstractActivityC4410.dump(java.lang.String, java.io.FileDescriptor, java.io.PrintWriter, java.lang.String[]):void");
    }

    @Override // android.app.Activity
    public final android.view.View findViewById(int i) throws java.lang.IllegalAccessException, java.lang.NoSuchMethodException, java.lang.SecurityException, java.lang.IllegalArgumentException, java.lang.reflect.InvocationTargetException {
        p363.LayoutInflaterFactory2C4430 layoutInflaterFactory2C4430 = (p363.LayoutInflaterFactory2C4430) m8911();
        layoutInflaterFactory2C4430.m8951();
        return layoutInflaterFactory2C4430.f16530.findViewById(i);
    }

    @Override // android.app.Activity
    public final android.view.MenuInflater getMenuInflater() throws java.lang.IllegalAccessException, java.lang.NoSuchMethodException, java.lang.SecurityException, java.lang.IllegalArgumentException, java.lang.reflect.InvocationTargetException {
        p363.LayoutInflaterFactory2C4430 layoutInflaterFactory2C4430 = (p363.LayoutInflaterFactory2C4430) m8911();
        if (layoutInflaterFactory2C4430.f16511 == null) {
            layoutInflaterFactory2C4430.m8955();
            p363.C4425 c4425 = layoutInflaterFactory2C4430.f16500;
            layoutInflaterFactory2C4430.f16511 = new p136.C2226(c4425 != null ? c4425.m8932() : layoutInflaterFactory2C4430.f16528);
        }
        return layoutInflaterFactory2C4430.f16511;
    }

    @Override // android.view.ContextThemeWrapper, android.content.ContextWrapper, android.content.Context
    public final android.content.res.Resources getResources() {
        int i = p137.AbstractC2329.f9068;
        return super.getResources();
    }

    @Override // android.app.Activity
    public final void invalidateOptionsMenu() {
        p363.LayoutInflaterFactory2C4430 layoutInflaterFactory2C4430 = (p363.LayoutInflaterFactory2C4430) m8911();
        if (layoutInflaterFactory2C4430.f16500 != null) {
            layoutInflaterFactory2C4430.m8955();
            layoutInflaterFactory2C4430.f16500.getClass();
            layoutInflaterFactory2C4430.m8964(0);
        }
    }

    @Override // p036.AbstractActivityC1262, android.app.Activity
    public void onActivityResult(int i, int i2, android.content.Intent intent) {
        this.f16398.ᵔٴ();
        super.onActivityResult(i, i2, intent);
    }

    @Override // p036.AbstractActivityC1262, android.app.Activity, android.content.ComponentCallbacks
    public final void onConfigurationChanged(android.content.res.Configuration configuration) throws java.lang.IllegalAccessException, java.lang.NoSuchFieldException, java.lang.NoSuchMethodException, android.content.pm.PackageManager.NameNotFoundException, java.lang.SecurityException, java.lang.IllegalArgumentException, java.lang.reflect.InvocationTargetException {
        super.onConfigurationChanged(configuration);
        p363.LayoutInflaterFactory2C4430 layoutInflaterFactory2C4430 = (p363.LayoutInflaterFactory2C4430) m8911();
        if (layoutInflaterFactory2C4430.f16505 && layoutInflaterFactory2C4430.f16529) {
            layoutInflaterFactory2C4430.m8955();
            p363.C4425 c4425 = layoutInflaterFactory2C4430.f16500;
            if (c4425 != null) {
                c4425.m8928(c4425.f16462.getResources().getBoolean(ar.tvplayer.tv.R.bool._4f5_res_0x7f050000));
            }
        }
        p137.C2284 c2284M5332 = p137.C2284.m5332();
        android.content.Context context = layoutInflaterFactory2C4430.f16528;
        synchronized (c2284M5332) {
            c2284M5332.f8942.m5254(context);
        }
        layoutInflaterFactory2C4430.f16512 = new android.content.res.Configuration(layoutInflaterFactory2C4430.f16528.getResources().getConfiguration());
        layoutInflaterFactory2C4430.m8958(false, false);
    }

    @Override // android.app.Activity, android.view.Window.Callback
    public final void onContentChanged() {
    }

    @Override // p036.AbstractActivityC1262, p151.AbstractActivityC2438, android.app.Activity
    public void onCreate(android.os.Bundle bundle) {
        super.onCreate(bundle);
        this.f16401.m710(androidx.lifecycle.EnumC0174.ON_CREATE);
        p229.C3085 c3085 = ((p229.C3114) this.f16398.ᴵˊ).f11850;
        c3085.f11751 = false;
        c3085.f11745 = false;
        c3085.f11741.f11948 = false;
        c3085.m6663(1);
    }

    @Override // android.app.Activity, android.view.LayoutInflater.Factory2
    public final android.view.View onCreateView(android.view.View view, java.lang.String str, android.content.Context context, android.util.AttributeSet attributeSet) {
        android.view.View viewOnCreateView = ((p229.C3114) this.f16398.ᴵˊ).f11850.f11763.onCreateView(view, str, context, attributeSet);
        return viewOnCreateView == null ? super.onCreateView(view, str, context, attributeSet) : viewOnCreateView;
    }

    @Override // android.app.Activity, android.view.LayoutInflater.Factory
    public final android.view.View onCreateView(java.lang.String str, android.content.Context context, android.util.AttributeSet attributeSet) {
        android.view.View viewOnCreateView = ((p229.C3114) this.f16398.ᴵˊ).f11850.f11763.onCreateView(null, str, context, attributeSet);
        return viewOnCreateView == null ? super.onCreateView(str, context, attributeSet) : viewOnCreateView;
    }

    @Override // android.app.Activity
    public void onDestroy() {
        m8912();
        m8911().mo8942();
    }

    @Override // android.app.Activity, android.view.KeyEvent.Callback
    public boolean onKeyDown(int i, android.view.KeyEvent keyEvent) {
        android.view.Window window;
        if (android.os.Build.VERSION.SDK_INT >= 26 || keyEvent.isCtrlPressed() || android.view.KeyEvent.metaStateHasNoModifiers(keyEvent.getMetaState()) || keyEvent.getRepeatCount() != 0 || android.view.KeyEvent.isModifierKey(keyEvent.getKeyCode()) || (window = getWindow()) == null || window.getDecorView() == null || !window.getDecorView().dispatchKeyShortcutEvent(keyEvent)) {
            return super.onKeyDown(i, keyEvent);
        }
        return true;
    }

    @Override // p036.AbstractActivityC1262, android.app.Activity, android.view.Window.Callback
    public final boolean onMenuItemSelected(int i, android.view.MenuItem menuItem) throws java.lang.IllegalAccessException, java.lang.NoSuchMethodException, java.lang.SecurityException, java.lang.IllegalArgumentException, java.lang.reflect.InvocationTargetException {
        android.content.Intent intentM5538;
        if (!m8915(i, menuItem)) {
            p363.LayoutInflaterFactory2C4430 layoutInflaterFactory2C4430 = (p363.LayoutInflaterFactory2C4430) m8911();
            layoutInflaterFactory2C4430.m8955();
            p363.C4425 c4425 = layoutInflaterFactory2C4430.f16500;
            if (menuItem.getItemId() != 16908332 || c4425 == null || (((p137.C2286) c4425.f16460).f8954 & 4) == 0 || (intentM5538 = p151.AbstractC2427.m5538(this)) == null) {
                return false;
            }
            if (!shouldUpRecreateTask(intentM5538)) {
                navigateUpTo(intentM5538);
                return true;
            }
            java.util.ArrayList arrayList = new java.util.ArrayList();
            android.content.Intent intentM55382 = p151.AbstractC2427.m5538(this);
            if (intentM55382 == null) {
                intentM55382 = p151.AbstractC2427.m5538(this);
            }
            if (intentM55382 != null) {
                android.content.ComponentName component = intentM55382.getComponent();
                if (component == null) {
                    component = intentM55382.resolveActivity(getPackageManager());
                }
                int size = arrayList.size();
                try {
                    android.content.Intent intentM5537 = p151.AbstractC2427.m5537(this, component);
                    while (intentM5537 != null) {
                        arrayList.add(size, intentM5537);
                        intentM5537 = p151.AbstractC2427.m5537(this, intentM5537.getComponent());
                    }
                    arrayList.add(intentM55382);
                } catch (android.content.pm.PackageManager.NameNotFoundException e) {
                    throw new java.lang.IllegalArgumentException(e);
                }
            }
            if (arrayList.isEmpty()) {
                throw new java.lang.IllegalStateException("No intents added to TaskStackBuilder; cannot startActivities");
            }
            android.content.Intent[] intentArr = (android.content.Intent[]) arrayList.toArray(new android.content.Intent[0]);
            intentArr[0] = new android.content.Intent(intentArr[0]).addFlags(268484608);
            startActivities(intentArr, null);
            try {
                finishAffinity();
            } catch (java.lang.IllegalStateException unused) {
                finish();
            }
        }
        return true;
    }

    @Override // android.app.Activity
    public final void onPause() {
        super.onPause();
        this.f16399 = false;
        ((p229.C3114) this.f16398.ᴵˊ).f11850.m6663(5);
        this.f16401.m710(androidx.lifecycle.EnumC0174.ON_PAUSE);
    }

    @Override // android.app.Activity
    public final void onPostCreate(android.os.Bundle bundle) throws java.lang.IllegalAccessException, java.lang.NoSuchMethodException, java.lang.SecurityException, java.lang.IllegalArgumentException, java.lang.reflect.InvocationTargetException {
        super.onPostCreate(bundle);
        ((p363.LayoutInflaterFactory2C4430) m8911()).m8951();
    }

    @Override // android.app.Activity
    public final void onPostResume() throws java.lang.IllegalAccessException, java.lang.NoSuchMethodException, java.lang.SecurityException, java.lang.IllegalArgumentException, java.lang.reflect.InvocationTargetException {
        m8913();
        p363.LayoutInflaterFactory2C4430 layoutInflaterFactory2C4430 = (p363.LayoutInflaterFactory2C4430) m8911();
        layoutInflaterFactory2C4430.m8955();
        p363.C4425 c4425 = layoutInflaterFactory2C4430.f16500;
        if (c4425 != null) {
            c4425.f16466 = true;
        }
    }

    @Override // p036.AbstractActivityC1262, android.app.Activity
    public final void onRequestPermissionsResult(int i, java.lang.String[] strArr, int[] iArr) {
        this.f16398.ᵔٴ();
        super.onRequestPermissionsResult(i, strArr, iArr);
    }

    @Override // android.app.Activity
    public void onResume() {
        ˉˆ.ʿ r0 = this.f16398;
        r0.ᵔٴ();
        super.onResume();
        this.f16399 = true;
        ((p229.C3114) r0.ᴵˊ).f11850.m6664(true);
    }

    @Override // android.app.Activity
    public void onStart() throws java.lang.IllegalAccessException, java.lang.NoSuchFieldException, android.content.pm.PackageManager.NameNotFoundException, java.lang.SecurityException, java.lang.IllegalArgumentException {
        m8910();
        ((p363.LayoutInflaterFactory2C4430) m8911()).m8958(true, false);
    }

    @Override // android.app.Activity
    public final void onStateNotSaved() {
        this.f16398.ᵔٴ();
    }

    @Override // android.app.Activity
    public void onStop() throws java.lang.IllegalAccessException, java.lang.NoSuchMethodException, java.lang.SecurityException, java.lang.IllegalArgumentException, java.lang.reflect.InvocationTargetException {
        m8916();
        p363.LayoutInflaterFactory2C4430 layoutInflaterFactory2C4430 = (p363.LayoutInflaterFactory2C4430) m8911();
        layoutInflaterFactory2C4430.m8955();
        p363.C4425 c4425 = layoutInflaterFactory2C4430.f16500;
        if (c4425 != null) {
            c4425.f16466 = false;
            p136.C2220 c2220 = c4425.f16446;
            if (c2220 != null) {
                c2220.m5209();
            }
        }
    }

    @Override // android.app.Activity
    public final void onTitleChanged(java.lang.CharSequence charSequence, int i) {
        super.onTitleChanged(charSequence, i);
        m8911().mo8941(charSequence);
    }

    @Override // android.app.Activity
    public final void openOptionsMenu() throws java.lang.IllegalAccessException, java.lang.NoSuchMethodException, java.lang.SecurityException, java.lang.IllegalArgumentException, java.lang.reflect.InvocationTargetException {
        ((p363.LayoutInflaterFactory2C4430) m8911()).m8955();
        if (getWindow().hasFeature(0)) {
            super.openOptionsMenu();
        }
    }

    @Override // p036.AbstractActivityC1262, android.app.Activity
    public final void setContentView(int i) {
        m3850();
        m8911().mo8935(i);
    }

    @Override // p036.AbstractActivityC1262, android.app.Activity
    public void setContentView(android.view.View view) {
        m3850();
        m8911().mo8936(view);
    }

    @Override // p036.AbstractActivityC1262, android.app.Activity
    public final void setContentView(android.view.View view, android.view.ViewGroup.LayoutParams layoutParams) {
        m3850();
        m8911().mo8938(view, layoutParams);
    }

    @Override // android.app.Activity, android.view.ContextThemeWrapper, android.content.ContextWrapper, android.content.Context
    public final void setTheme(int i) {
        super.setTheme(i);
        ((p363.LayoutInflaterFactory2C4430) m8911()).f16509 = i;
    }

    /* renamed from: ʼᐧ, reason: contains not printable characters */
    public final void m8910() {
        ˉˆ.ʿ r0 = this.f16398;
        r0.ᵔٴ();
        p229.C3114 c3114 = (p229.C3114) r0.ᴵˊ;
        super.onStart();
        this.f16402 = false;
        if (!this.f16403) {
            this.f16403 = true;
            p229.C3085 c3085 = c3114.f11850;
            c3085.f11751 = false;
            c3085.f11745 = false;
            c3085.f11741.f11948 = false;
            c3085.m6663(4);
        }
        c3114.f11850.m6664(true);
        this.f16401.m710(androidx.lifecycle.EnumC0174.ON_START);
        p229.C3085 c30852 = c3114.f11850;
        c30852.f11751 = false;
        c30852.f11745 = false;
        c30852.f11741.f11948 = false;
        c30852.m6663(5);
    }

    /* renamed from: ˆʾ, reason: contains not printable characters */
    public final p363.AbstractC4427 m8911() {
        if (this.f16400 == null) {
            p035.ExecutorC1212 executorC1212 = p363.AbstractC4427.f16472;
            this.f16400 = new p363.LayoutInflaterFactory2C4430(this, null, this, this);
        }
        return this.f16400;
    }

    /* renamed from: ˉʿ, reason: contains not printable characters */
    public final void m8912() {
        super.onDestroy();
        ((p229.C3114) this.f16398.ᴵˊ).f11850.m6714();
        this.f16401.m710(androidx.lifecycle.EnumC0174.ON_DESTROY);
    }

    /* renamed from: ˉˆ, reason: contains not printable characters */
    public final void m8913() {
        super.onPostResume();
        this.f16401.m710(androidx.lifecycle.EnumC0174.ON_RESUME);
        p229.C3085 c3085 = ((p229.C3114) this.f16398.ᴵˊ).f11850;
        c3085.f11751 = false;
        c3085.f11745 = false;
        c3085.f11741.f11948 = false;
        c3085.m6663(7);
    }

    /* renamed from: ٴﹶ, reason: contains not printable characters */
    public final p229.C3085 m8914() {
        return ((p229.C3114) this.f16398.ᴵˊ).f11850;
    }

    /* renamed from: ᵔʾ, reason: contains not printable characters */
    public final boolean m8915(int i, android.view.MenuItem menuItem) {
        if (super.onMenuItemSelected(i, menuItem)) {
            return true;
        }
        if (i == 6) {
            return ((p229.C3114) this.f16398.ᴵˊ).f11850.m6668();
        }
        return false;
    }

    /* renamed from: ᵔﹳ, reason: contains not printable characters */
    public final void m8916() {
        super.onStop();
        this.f16402 = true;
        while (m8909(m8914())) {
        }
        p229.C3085 c3085 = ((p229.C3114) this.f16398.ᴵˊ).f11850;
        c3085.f11745 = true;
        c3085.f11741.f11948 = true;
        c3085.m6663(4);
        this.f16401.m710(androidx.lifecycle.EnumC0174.ON_STOP);
    }
}
