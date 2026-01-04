package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ᵔʾ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class RunnableC0142 implements java.lang.Runnable {

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public final /* synthetic */ int f995;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public final java.lang.Object f996;

    public /* synthetic */ RunnableC0142(int i, java.lang.Object obj) {
        this.f995 = i;
        this.f996 = obj;
    }

    public /* synthetic */ RunnableC0142(p027.C1111 c1111, ar.tvplayer.core.data.api.parse.ˈ r2) {
        this.f995 = 8;
        this.f996 = c1111;
    }

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    private final void m650() {
        synchronized (((p220.C3031) this.f996).f11556) {
            ((p220.InterfaceC3034) ((p220.C3031) this.f996).f11558).mo6556();
        }
    }

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    private final void m651() {
        synchronized (this) {
            ((androidx.preference.PreferenceGroup) this.f996).f1393.clear();
        }
    }

    /* JADX INFO: Infinite loop detected, blocks: 8, insns: 0 */
    @Override // java.lang.Runnable
    public final void run() {
        androidx.leanback.widget.InterfaceC0102 interfaceC0102;
        java.lang.Object obj;
        p137.C2308 c2308;
        boolean z;
        boolean z2;
        switch (this.f995) {
            case 0:
                ((androidx.leanback.widget.GridLayoutManager) this.f996).m5982();
                return;
            case 1:
                ﹳי.ʽ r0 = ((androidx.leanback.widget.SearchEditText) this.f996).f742;
                if (r0 == null || (interfaceC0102 = ((androidx.leanback.widget.SearchBar) r0.ʾˋ).f719) == null) {
                    return;
                }
                p363.AbstractActivityC4410 abstractActivityC4410M6803 = ((ﾞᵔ.ˉٴ) ((p384.C4603) interfaceC0102).f17126).m6803();
                ʼⁱ.ʽ r2 = abstractActivityC4410M6803 instanceof ʼⁱ.ʽ ? (ʼⁱ.ʽ) abstractActivityC4410M6803 : null;
                if (r2 != null) {
                    r2.ـˆ(false);
                    return;
                }
                return;
            case 2:
                synchronized (((androidx.lifecycle.AbstractC0161) this.f996).f1047) {
                    obj = ((androidx.lifecycle.AbstractC0161) this.f996).f1048;
                    ((androidx.lifecycle.AbstractC0161) this.f996).f1048 = androidx.lifecycle.AbstractC0161.f1038;
                }
                ((androidx.lifecycle.AbstractC0161) this.f996).m686(obj);
                return;
            case 3:
                com.bumptech.glide.ComponentCallbacks2C0236 componentCallbacks2C0236 = (com.bumptech.glide.ComponentCallbacks2C0236) this.f996;
                componentCallbacks2C0236.f1681.mo7498(componentCallbacks2C0236);
                return;
            case 4:
                ((p011.C0859) this.f996).m3059();
                return;
            case 5:
                androidx.recyclerview.widget.RecyclerView recyclerView = ((p011.AbstractC0864) this.f996).f3681;
                recyclerView.focusableViewAvailable(recyclerView);
                return;
            case p223.C3056.STRING_SET_FIELD_NUMBER /* 6 */:
                m651();
                return;
            case p223.C3056.DOUBLE_FIELD_NUMBER /* 7 */:
                ((p011.C0867) this.f996).m3080();
                return;
            case p223.C3056.BYTES_FIELD_NUMBER /* 8 */:
                ((p027.C1111) this.f996).m3519(24, 3, p027.AbstractC1093.f4267);
                boolean z3 = ar.tvplayer.core.domain.ʻٴ.ﹳٴ;
                return;
            case 9:
                try {
                    ((p027.C1111) ((p404.C4790) this.f996).f18034).f4346.mo3443();
                    return;
                } catch (java.lang.Throwable th) {
                    com.google.android.gms.internal.play_billing.AbstractC0542.m2091("BillingClient", "Exception calling onBillingServiceDisconnected.", th);
                    return;
                }
            case 10:
                p027.ServiceConnectionC1088 serviceConnectionC1088 = (p027.ServiceConnectionC1088) this.f996;
                p027.C1111 c1111 = serviceConnectionC1088.f4246;
                c1111.m3499(0);
                p027.C1115 c1115 = p027.AbstractC1093.f4267;
                c1111.m3520(24, serviceConnectionC1088.f4244, c1115);
                serviceConnectionC1088.m3444(c1115);
                return;
            case 11:
                try {
                    super/*android.app.Activity*/.onBackPressed();
                    return;
                } catch (java.lang.IllegalStateException e) {
                    if (!android.text.TextUtils.equals(e.getMessage(), "Can not perform this action after onSaveInstanceState")) {
                        throw e;
                    }
                    return;
                } catch (java.lang.NullPointerException e2) {
                    if (!android.text.TextUtils.equals(e2.getMessage(), "Attempt to invoke virtual method 'android.os.Handler android.app.FragmentHostCallback.getHandler()' on a null object reference")) {
                        throw e2;
                    }
                    return;
                }
            case 12:
                com.google.android.material.internal.CheckableImageButton checkableImageButton = ((com.google.android.material.textfield.TextInputLayout) this.f996).f2845.f5090;
                checkableImageButton.performClick();
                checkableImageButton.jumpDrawablesToCurrentState();
                return;
            case 13:
                com.parse.ٴʼ r02 = (com.parse.ٴʼ) this.f996;
                r02.getClass();
                while (true) {
                    try {
                        r02.ٴᵢ((p080.C1690) ((java.lang.ref.ReferenceQueue) r02.ʽʽ).remove());
                    } catch (java.lang.InterruptedException unused) {
                        java.lang.Thread.currentThread().interrupt();
                    }
                }
            case 14:
                ar.tvplayer.core.util.RestartProcessActivity restartProcessActivity = (ar.tvplayer.core.util.RestartProcessActivity) this.f996;
                ʿˋ.ˉʿ.ʽᵔ(restartProcessActivity, true);
                restartProcessActivity.finish();
                return;
            case 15:
                p096.C1892 c1892 = (p096.C1892) this.f996;
                c1892.m4827(true);
                c1892.invalidateSelf();
                return;
            case 16:
                p137.C2249 c2249 = (p137.C2249) this.f996;
                c2249.f8820 = null;
                c2249.drawableStateChanged();
                return;
            case 17:
                androidx.appcompat.widget.SearchView$SearchAutoComplete searchView$SearchAutoComplete = (androidx.appcompat.widget.SearchView$SearchAutoComplete) this.f996;
                if (searchView$SearchAutoComplete.f156) {
                    ((android.view.inputmethod.InputMethodManager) searchView$SearchAutoComplete.getContext().getSystemService("input_method")).showSoftInput(searchView$SearchAutoComplete, 0);
                    searchView$SearchAutoComplete.f156 = false;
                    return;
                }
                return;
            case 18:
                androidx.appcompat.widget.ActionMenuView actionMenuView = ((androidx.appcompat.widget.Toolbar) this.f996).f209;
                if (actionMenuView == null || (c2308 = actionMenuView.f138) == null) {
                    return;
                }
                c2308.m5392();
                return;
            case 19:
                ((p142.C2381) this.f996).m5464(0);
                return;
            case 20:
                p179.C2726 c2726 = (p179.C2726) this.f996;
                android.animation.ValueAnimator valueAnimator = c2726.f10411;
                int i = c2726.f10395;
                if (i == 1) {
                    valueAnimator.cancel();
                } else if (i != 2) {
                    return;
                }
                c2726.f10395 = 3;
                valueAnimator.setFloatValues(((java.lang.Float) valueAnimator.getAnimatedValue()).floatValue(), 0.0f);
                valueAnimator.setDuration(500);
                valueAnimator.start();
                return;
            case 21:
                ((androidx.recyclerview.widget.StaggeredGridLayoutManager) this.f996).m1002();
                return;
            case 22:
                m650();
                return;
            case 23:
                p229.DialogInterfaceOnCancelListenerC3073 dialogInterfaceOnCancelListenerC3073 = (p229.DialogInterfaceOnCancelListenerC3073) this.f996;
                dialogInterfaceOnCancelListenerC3073.f11676.onDismiss(dialogInterfaceOnCancelListenerC3073.f11678);
                return;
            case 24:
                p229.C3133 c3133 = (p229.C3133) this.f996;
                if (c3133.f11974.isEmpty()) {
                    return;
                }
                c3133.m6870();
                return;
            case 25:
                ((p229.C3085) this.f996).m6664(true);
                return;
            case 26:
                androidx.leanback.widget.picker.DatePicker datePicker = (androidx.leanback.widget.picker.DatePicker) this.f996;
                int[] iArr = {datePicker.f798, datePicker.f807, datePicker.f805};
                boolean z4 = true;
                boolean z5 = true;
                for (int i2 = 2; i2 >= 0; i2--) {
                    int i3 = iArr[i2];
                    if (i3 >= 0) {
                        int i4 = androidx.leanback.widget.picker.DatePicker.f794[i2];
                        p244.C3248 c3248M568 = datePicker.m568(i3);
                        if (z4) {
                            int i5 = datePicker.f797.get(i4);
                            if (i5 != c3248M568.f12504) {
                                c3248M568.f12504 = i5;
                                z = true;
                            }
                            z = false;
                        } else {
                            int actualMinimum = datePicker.f804.getActualMinimum(i4);
                            if (actualMinimum != c3248M568.f12504) {
                                c3248M568.f12504 = actualMinimum;
                                z = true;
                            }
                            z = false;
                        }
                        if (z5) {
                            int i6 = datePicker.f806.get(i4);
                            if (i6 != c3248M568.f12501) {
                                c3248M568.f12501 = i6;
                                z2 = true;
                            }
                            z2 = false;
                        } else {
                            int actualMaximum = datePicker.f804.getActualMaximum(i4);
                            if (actualMaximum != c3248M568.f12501) {
                                c3248M568.f12501 = actualMaximum;
                                z2 = true;
                            }
                            z2 = false;
                        }
                        boolean z6 = z | z2;
                        z4 &= datePicker.f804.get(i4) == datePicker.f797.get(i4);
                        z5 &= datePicker.f804.get(i4) == datePicker.f806.get(i4);
                        if (z6) {
                            datePicker.m563(iArr[i2], c3248M568);
                        }
                        datePicker.m564(iArr[i2], datePicker.f804.get(i4));
                    }
                }
                return;
            case 27:
                ((p364.InterfaceC4453) this.f996).mo9004();
                return;
            case 28:
                ((p409.C4840) this.f996).m9644();
                return;
            default:
                p369.InterfaceC4507 interfaceC4507 = ((p409.C4840) ((p384.C4603) this.f996).f17126).f18153;
                interfaceC4507.m9074(interfaceC4507.getClass().getName().concat(" disconnecting because it was signed out."));
                return;
        }
    }
}
