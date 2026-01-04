package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ˊʻ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C0108 extends p179.AbstractC2727 {

    /* renamed from: ʼˎ, reason: contains not printable characters */
    public final androidx.leanback.widget.C0094 f908;

    /* renamed from: ˆʾ, reason: contains not printable characters */
    public final java.util.ArrayList f909;

    /* renamed from: ˈ, reason: contains not printable characters */
    public final androidx.leanback.widget.VerticalGridView f910;

    /* renamed from: ˉʿ, reason: contains not printable characters */
    public com.google.android.gms.internal.measurement.C0344 f911;

    /* renamed from: ˉˆ, reason: contains not printable characters */
    public final androidx.leanback.widget.ViewOnClickListenerC0083 f912 = new androidx.leanback.widget.ViewOnClickListenerC0083(0, this);

    /* renamed from: ˑﹳ, reason: contains not printable characters */
    public final boolean f913;

    /* renamed from: ٴﹶ, reason: contains not printable characters */
    public final androidx.leanback.widget.InterfaceC0136 f914;

    /* renamed from: ᵎﹶ, reason: contains not printable characters */
    public final androidx.leanback.widget.ViewOnFocusChangeListenerC0089 f915;

    /* renamed from: ᵔʾ, reason: contains not printable characters */
    public androidx.leanback.widget.C0140 f916;

    /* renamed from: ᵔᵢ, reason: contains not printable characters */
    public final androidx.leanback.widget.C0134 f917;

    /* renamed from: ﾞʻ, reason: contains not printable characters */
    public final androidx.leanback.widget.C0117 f918;

    /* renamed from: ﾞᴵ, reason: contains not printable characters */
    public final androidx.leanback.widget.ViewOnKeyListenerC0103 f919;

    public C0108(java.util.ArrayList arrayList, androidx.leanback.widget.InterfaceC0136 interfaceC0136, androidx.leanback.app.C0069 c0069, androidx.leanback.widget.C0117 c0117, boolean z) {
        this.f909 = arrayList == null ? new java.util.ArrayList() : new java.util.ArrayList(arrayList);
        this.f914 = interfaceC0136;
        this.f918 = c0117;
        this.f919 = new androidx.leanback.widget.ViewOnKeyListenerC0103(this);
        this.f915 = new androidx.leanback.widget.ViewOnFocusChangeListenerC0089(this, c0069);
        this.f917 = new androidx.leanback.widget.C0134(0, this);
        this.f908 = new androidx.leanback.widget.C0094(this);
        this.f913 = z;
        if (!z) {
            this.f916 = androidx.leanback.widget.C0140.f994;
        }
        this.f910 = z ? c0117.f931 : c0117.f944;
    }

    /* JADX WARN: Multi-variable type inference failed */
    /* renamed from: ʼᐧ, reason: contains not printable characters */
    public final void m606(android.widget.EditText editText) {
        if (editText != 0) {
            editText.setPrivateImeOptions("escapeNorth");
            androidx.leanback.widget.C0134 c0134 = this.f917;
            editText.setOnEditorActionListener(c0134);
            if (editText instanceof androidx.leanback.widget.InterfaceC0109) {
                ((androidx.leanback.widget.InterfaceC0109) editText).setImeKeyListener(c0134);
            }
            if (editText instanceof androidx.leanback.widget.InterfaceC0107) {
                ((androidx.leanback.widget.InterfaceC0107) editText).setOnAutofillListener(this.f908);
            }
        }
    }

    @Override // p179.AbstractC2727
    /* renamed from: ʽ, reason: contains not printable characters */
    public final int mo607(int i) {
        this.f918.getClass();
        return 0;
    }

    /* renamed from: ˉˆ, reason: contains not printable characters */
    public final void m608(java.util.List list) {
        if (!this.f913) {
            this.f918.m620(false);
        }
        androidx.leanback.widget.ViewOnFocusChangeListenerC0089 viewOnFocusChangeListenerC0089 = this.f915;
        androidx.leanback.widget.C0108 c0108 = viewOnFocusChangeListenerC0089.f844;
        android.view.View view = viewOnFocusChangeListenerC0089.f845;
        if (view != null) {
            androidx.leanback.widget.VerticalGridView verticalGridView = c0108.f910;
            if (verticalGridView.f1499) {
                p179.AbstractC2673 abstractC2673M946 = verticalGridView.m946(view);
                if (abstractC2673M946 != null) {
                    c0108.f918.getClass();
                } else {
                    new java.lang.Throwable();
                }
            }
        }
        androidx.leanback.widget.C0140 c0140 = this.f916;
        java.util.ArrayList arrayList = this.f909;
        if (c0140 == null) {
            arrayList.clear();
            arrayList.addAll(list);
            m6118();
        } else {
            java.util.ArrayList arrayList2 = new java.util.ArrayList();
            arrayList2.addAll(arrayList);
            arrayList.clear();
            arrayList.addAll(list);
            p179.AbstractC2741.m6138(new androidx.leanback.widget.C0147(this, arrayList2)).m6030(new ˉˆ.ʿ(8, this));
        }
    }

    /* JADX WARN: Multi-variable type inference failed */
    /* JADX WARN: Type inference failed for: r3v7, types: [android.view.View] */
    /* renamed from: ᵔʾ, reason: contains not printable characters */
    public final androidx.leanback.widget.C0101 m609(android.widget.TextView textView) {
        androidx.leanback.widget.VerticalGridView verticalGridView = this.f910;
        if (!verticalGridView.f1499) {
            return null;
        }
        android.view.ViewParent parent = textView.getParent();
        android.widget.TextView textView2 = textView;
        while (parent != verticalGridView && parent != null) {
            ?? r3 = (android.view.View) parent;
            parent = parent.getParent();
            textView2 = r3;
        }
        if (parent != null) {
            return (androidx.leanback.widget.C0101) verticalGridView.m946(textView2);
        }
        return null;
    }

    @Override // p179.AbstractC2727
    /* renamed from: ᵔᵢ, reason: contains not printable characters */
    public final p179.AbstractC2673 mo610(android.view.ViewGroup viewGroup, int i) {
        int iM621;
        androidx.leanback.widget.C0101 c0101;
        androidx.leanback.widget.C0117 c0117 = this.f918;
        if (i == 0) {
            c0101 = c0117.m615(viewGroup);
        } else {
            c0117.getClass();
            android.view.LayoutInflater layoutInflaterFrom = android.view.LayoutInflater.from(viewGroup.getContext());
            if (i == 0) {
                iM621 = c0117.m621();
            } else {
                if (i != 1) {
                    throw new java.lang.RuntimeException(p035.AbstractC1220.m3773(i, "ViewType ", " not supported in GuidedActionsStylist"));
                }
                iM621 = ar.tvplayer.tv.R.layout._7dp_res_0x7f0e00a3;
            }
            c0101 = new androidx.leanback.widget.C0101(layoutInflaterFrom.inflate(iM621, viewGroup, false), viewGroup == c0117.f931);
        }
        android.view.View view = c0101.f10176;
        view.setOnKeyListener(this.f919);
        view.setOnClickListener(this.f912);
        view.setOnFocusChangeListener(this.f915);
        android.widget.TextView textView = c0101.f894;
        m606(textView instanceof android.widget.EditText ? (android.widget.EditText) textView : null);
        android.widget.TextView textView2 = c0101.f889;
        m606(textView2 instanceof android.widget.EditText ? (android.widget.EditText) textView2 : null);
        return c0101;
    }

    @Override // p179.AbstractC2727
    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final int mo611() {
        return this.f909.size();
    }

    /* JADX WARN: Multi-variable type inference failed */
    @Override // p179.AbstractC2727
    /* renamed from: ﾞᴵ, reason: contains not printable characters */
    public final void mo612(p179.AbstractC2673 abstractC2673, int i) {
        java.util.ArrayList arrayList = this.f909;
        if (i >= arrayList.size()) {
            return;
        }
        androidx.leanback.widget.C0101 c0101 = (androidx.leanback.widget.C0101) abstractC2673;
        android.widget.TextView textView = c0101.f894;
        android.widget.TextView textView2 = c0101.f889;
        androidx.leanback.widget.C0095 c0095 = (androidx.leanback.widget.C0095) arrayList.get(i);
        androidx.leanback.widget.C0117 c0117 = this.f918;
        c0117.getClass();
        c0101.f896 = c0095;
        android.view.View view = c0101.f10176;
        if (textView != null) {
            textView.setInputType(c0095.f870);
            textView.setText(c0095.f871);
            textView.setAlpha(c0095.m580() ? c0117.f940 : c0117.f942);
            textView.setFocusable(false);
            textView.setClickable(false);
            textView.setLongClickable(false);
            int i2 = android.os.Build.VERSION.SDK_INT;
            if (i2 >= 28) {
                if (c0095.m579()) {
                    p076.AbstractC1659.m4531(textView);
                } else {
                    p076.AbstractC1659.m4531(textView);
                }
            } else if (i2 >= 26) {
                p076.AbstractC1659.m4535(textView);
            }
        }
        if (textView2 != null) {
            textView2.setInputType(c0095.f872);
            textView2.setText(c0095.f873);
            textView2.setVisibility(android.text.TextUtils.isEmpty(c0095.f873) ? 8 : 0);
            textView2.setAlpha(c0095.m580() ? c0117.f929 : c0117.f932);
            textView2.setFocusable(false);
            textView2.setClickable(false);
            textView2.setLongClickable(false);
            int i3 = android.os.Build.VERSION.SDK_INT;
            if (i3 >= 28) {
                if (c0095.f878 == 2) {
                    p076.AbstractC1659.m4531(textView2);
                } else {
                    p076.AbstractC1659.m4531(textView2);
                }
            } else if (i3 >= 26) {
                p076.AbstractC1659.m4535(textView);
            }
        }
        android.widget.ImageView imageView = c0101.f895;
        if (imageView != 0) {
            if (c0095.f874 != 0) {
                imageView.setVisibility(0);
                int i4 = c0095.f874 == -1 ? android.R.attr.listChoiceIndicatorMultiple : android.R.attr.listChoiceIndicatorSingle;
                android.content.Context context = imageView.getContext();
                android.util.TypedValue typedValue = new android.util.TypedValue();
                imageView.setImageDrawable(context.getTheme().resolveAttribute(i4, typedValue, true) ? context.getDrawable(typedValue.resourceId) : null);
                if (imageView instanceof android.widget.Checkable) {
                    ((android.widget.Checkable) imageView).setChecked(c0095.m584());
                }
            } else {
                imageView.setVisibility(8);
            }
        }
        android.widget.ImageView imageView2 = c0101.f887;
        if (imageView2 != null) {
            android.graphics.drawable.Drawable drawable = c0095.f879;
            if (drawable != null) {
                imageView2.setImageLevel(drawable.getLevel());
                imageView2.setImageDrawable(drawable);
                imageView2.setVisibility(0);
            } else {
                imageView2.setVisibility(8);
            }
        }
        if ((c0095.f875 & 2) != 2) {
            if (textView != null) {
                int i5 = c0117.f934;
                if (i5 == 1) {
                    textView.setSingleLine(true);
                } else {
                    textView.setSingleLine(false);
                    textView.setMaxLines(i5);
                }
            }
            if (textView2 != null) {
                int i6 = c0117.f935;
                if (i6 == 1) {
                    textView2.setSingleLine(true);
                } else {
                    textView2.setSingleLine(false);
                    textView2.setMaxLines(i6);
                }
            }
        } else if (textView != null) {
            int i7 = c0117.f941;
            if (i7 == 1) {
                textView.setSingleLine(true);
            } else {
                textView.setSingleLine(false);
                textView.setMaxLines(i7);
            }
            textView.setInputType(textView.getInputType() | 131072);
            if (textView2 != null) {
                textView2.setInputType(textView2.getInputType() | 131072);
                textView2.setMaxHeight((c0117.f943 - (c0117.f930 * 2)) - (textView.getLineHeight() * (c0117.f941 * 2)));
            }
        }
        c0117.m617(c0101, false, false);
        if ((c0095.f875 & 32) == 32) {
            view.setFocusable(true);
            ((android.view.ViewGroup) view).setDescendantFocusability(131072);
        } else {
            view.setFocusable(false);
            ((android.view.ViewGroup) view).setDescendantFocusability(393216);
        }
        android.widget.EditText editText = textView instanceof android.widget.EditText ? (android.widget.EditText) textView : null;
        if (editText != null) {
            editText.setImeOptions(5);
        }
        android.widget.EditText editText2 = textView2 instanceof android.widget.EditText ? (android.widget.EditText) textView2 : null;
        if (editText2 != null) {
            editText2.setImeOptions(5);
        }
        c0117.m613(c0101);
    }
}
