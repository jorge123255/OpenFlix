package androidx.leanback.widget;

/* loaded from: classes.dex */
public class SearchBar extends android.widget.RelativeLayout {

    /* renamed from: ʿᵢ, reason: contains not printable characters */
    public static final /* synthetic */ int f716 = 0;

    /* renamed from: ʼˈ, reason: contains not printable characters */
    public android.speech.SpeechRecognizer f717;

    /* renamed from: ʽʽ, reason: contains not printable characters */
    public androidx.leanback.widget.SpeechOrbView f718;

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public androidx.leanback.widget.InterfaceC0102 f719;

    /* renamed from: ʿ, reason: contains not printable characters */
    public androidx.leanback.widget.InterfaceC0153 f720;

    /* renamed from: ˆﾞ, reason: contains not printable characters */
    public final int f721;

    /* renamed from: ˈʿ, reason: contains not printable characters */
    public final int f722;

    /* renamed from: ˈٴ, reason: contains not printable characters */
    public android.widget.ImageView f723;

    /* renamed from: ˈⁱ, reason: contains not printable characters */
    public final android.util.SparseIntArray f724;

    /* renamed from: ˉـ, reason: contains not printable characters */
    public final android.content.Context f725;

    /* renamed from: ˉٴ, reason: contains not printable characters */
    public android.graphics.drawable.Drawable f726;

    /* renamed from: ˊʻ, reason: contains not printable characters */
    public java.lang.String f727;

    /* renamed from: ˊˋ, reason: contains not printable characters */
    public final int f728;

    /* renamed from: ˋᵔ, reason: contains not printable characters */
    public final int f729;

    /* renamed from: ˑٴ, reason: contains not printable characters */
    public final int f730;

    /* renamed from: ـˏ, reason: contains not printable characters */
    public boolean f731;

    /* renamed from: ٴʼ, reason: contains not printable characters */
    public final android.view.inputmethod.InputMethodManager f732;

    /* renamed from: ٴᵢ, reason: contains not printable characters */
    public java.lang.String f733;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public androidx.leanback.widget.SearchEditText f734;

    /* renamed from: ᴵˑ, reason: contains not printable characters */
    public boolean f735;

    /* renamed from: ᴵᵔ, reason: contains not printable characters */
    public java.lang.String f736;

    /* renamed from: ᵎˊ, reason: contains not printable characters */
    public boolean f737;

    /* renamed from: ᵎⁱ, reason: contains not printable characters */
    public final android.os.Handler f738;

    /* renamed from: ᵔי, reason: contains not printable characters */
    public android.graphics.drawable.Drawable f739;

    /* renamed from: ᵔٴ, reason: contains not printable characters */
    public final int f740;

    /* renamed from: ﹳـ, reason: contains not printable characters */
    public android.media.SoundPool f741;

    public SearchBar(android.content.Context context, android.util.AttributeSet attributeSet) {
        this(context, attributeSet, 0);
    }

    public SearchBar(android.content.Context context, android.util.AttributeSet attributeSet, int i) {
        super(context, attributeSet, 0);
        this.f738 = new android.os.Handler();
        this.f737 = false;
        this.f724 = new android.util.SparseIntArray();
        this.f735 = false;
        this.f725 = context;
        android.content.res.Resources resources = getResources();
        android.view.LayoutInflater.from(getContext()).inflate(ar.tvplayer.tv.R.layout.lb_search_bar, (android.view.ViewGroup) this, true);
        android.widget.RelativeLayout.LayoutParams layoutParams = new android.widget.RelativeLayout.LayoutParams(-1, getResources().getDimensionPixelSize(ar.tvplayer.tv.R.dimen._59n_res_0x7f0701b8));
        layoutParams.addRule(10, -1);
        setLayoutParams(layoutParams);
        setBackgroundColor(0);
        setClipChildren(false);
        this.f736 = "";
        this.f732 = (android.view.inputmethod.InputMethodManager) context.getSystemService("input_method");
        this.f740 = resources.getColor(ar.tvplayer.tv.R.color._3ct_res_0x7f0600f6);
        this.f721 = resources.getColor(ar.tvplayer.tv.R.color._749_res_0x7f0600f5);
        this.f728 = resources.getInteger(ar.tvplayer.tv.R.integer._4ej_res_0x7f0c002e);
        this.f729 = resources.getInteger(ar.tvplayer.tv.R.integer._743_res_0x7f0c002f);
        this.f730 = resources.getColor(ar.tvplayer.tv.R.color._319_res_0x7f0600f4);
        this.f722 = resources.getColor(ar.tvplayer.tv.R.color._1kf_res_0x7f0600f3);
    }

    public android.graphics.drawable.Drawable getBadgeDrawable() {
        return this.f726;
    }

    public java.lang.CharSequence getHint() {
        return this.f727;
    }

    public java.lang.String getTitle() {
        return this.f733;
    }

    @Override // android.view.ViewGroup, android.view.View
    public final void onAttachedToWindow() {
        super.onAttachedToWindow();
        this.f741 = new android.media.SoundPool(2, 1, 0);
        int[] iArr = {ar.tvplayer.tv.R.raw._7s_res_0x7f120004, ar.tvplayer.tv.R.raw.mb, ar.tvplayer.tv.R.raw._76l_res_0x7f120005, ar.tvplayer.tv.R.raw._6en_res_0x7f120007};
        for (int i = 0; i < 4; i++) {
            int i2 = iArr[i];
            this.f724.put(i2, this.f741.load(this.f725, i2, 1));
        }
    }

    @Override // android.view.ViewGroup, android.view.View
    public final void onDetachedFromWindow() {
        m552();
        this.f741.release();
        super.onDetachedFromWindow();
    }

    @Override // android.view.View
    public void onFinishInflate() throws android.content.res.Resources.NotFoundException {
        super.onFinishInflate();
        this.f739 = ((android.widget.RelativeLayout) findViewById(ar.tvplayer.tv.R.id._2f3_res_0x7f0b0248)).getBackground();
        this.f734 = (androidx.leanback.widget.SearchEditText) findViewById(ar.tvplayer.tv.R.id._3pq_res_0x7f0b024b);
        android.widget.ImageView imageView = (android.widget.ImageView) findViewById(ar.tvplayer.tv.R.id._17s_res_0x7f0b0247);
        this.f723 = imageView;
        android.graphics.drawable.Drawable drawable = this.f726;
        if (drawable != null) {
            imageView.setImageDrawable(drawable);
        }
        this.f734.setOnFocusChangeListener(new androidx.leanback.widget.ViewOnFocusChangeListenerC0133(this, 0));
        this.f734.addTextChangedListener(new ʼⁱ.ˆʾ(this, new androidx.leanback.widget.RunnableC0082(this, 0)));
        this.f734.setOnKeyboardDismissListener(new ﹳי.ʽ(this));
        int i = 1;
        this.f734.setOnEditorActionListener(new androidx.leanback.widget.C0134(i, this));
        this.f734.setPrivateImeOptions("escapeNorth,voiceDismiss");
        androidx.leanback.widget.SpeechOrbView speechOrbView = (androidx.leanback.widget.SpeechOrbView) findViewById(ar.tvplayer.tv.R.id._6j3_res_0x7f0b0249);
        this.f718 = speechOrbView;
        speechOrbView.setOnOrbClickedListener(new androidx.leanback.widget.ViewOnClickListenerC0083(i, this));
        this.f718.setOnFocusChangeListener(new androidx.leanback.widget.ViewOnFocusChangeListenerC0133(this, 1));
        m550(hasFocus());
        m549();
    }

    public void setBadgeDrawable(android.graphics.drawable.Drawable drawable) {
        this.f726 = drawable;
        android.widget.ImageView imageView = this.f723;
        if (imageView != null) {
            imageView.setImageDrawable(drawable);
            if (drawable != null) {
                this.f723.setVisibility(0);
            } else {
                this.f723.setVisibility(8);
            }
        }
    }

    @Override // android.view.View
    public void setNextFocusDownId(int i) {
        this.f718.setNextFocusDownId(i);
        this.f734.setNextFocusDownId(i);
    }

    public void setPermissionListener(androidx.leanback.widget.InterfaceC0153 interfaceC0153) {
        this.f720 = interfaceC0153;
    }

    public void setSearchAffordanceColors(androidx.leanback.widget.C0116 c0116) {
        androidx.leanback.widget.SpeechOrbView speechOrbView = this.f718;
        if (speechOrbView != null) {
            speechOrbView.setNotListeningOrbColors(c0116);
        }
    }

    public void setSearchAffordanceColorsInListening(androidx.leanback.widget.C0116 c0116) {
        androidx.leanback.widget.SpeechOrbView speechOrbView = this.f718;
        if (speechOrbView != null) {
            speechOrbView.setListeningOrbColors(c0116);
        }
    }

    public void setSearchBarListener(androidx.leanback.widget.InterfaceC0102 interfaceC0102) {
        this.f719 = interfaceC0102;
    }

    public void setSearchQuery(java.lang.String str) {
        m552();
        this.f734.setText(str);
        setSearchQueryInternal(str);
    }

    public void setSearchQueryInternal(java.lang.String str) {
        if (android.text.TextUtils.equals(this.f736, str)) {
            return;
        }
        this.f736 = str;
        androidx.leanback.widget.InterfaceC0102 interfaceC0102 = this.f719;
        if (interfaceC0102 != null) {
            ﾞᵔ.ˉٴ.ʽᐧ((ﾞᵔ.ˉٴ) ((p384.C4603) interfaceC0102).f17126, str, false);
        }
    }

    @java.lang.Deprecated
    public void setSpeechRecognitionCallback(androidx.leanback.widget.InterfaceC0124 interfaceC0124) {
    }

    public void setSpeechRecognizer(android.speech.SpeechRecognizer speechRecognizer) {
        m552();
        android.speech.SpeechRecognizer speechRecognizer2 = this.f717;
        if (speechRecognizer2 != null) {
            speechRecognizer2.setRecognitionListener(null);
            if (this.f731) {
                this.f717.cancel();
                this.f731 = false;
            }
        }
        this.f717 = speechRecognizer;
    }

    public void setTitle(java.lang.String str) throws android.content.res.Resources.NotFoundException {
        this.f733 = str;
        m549();
    }

    /* renamed from: ʽ */
    public void mo458() {
        this.f738.post(new androidx.leanback.widget.RunnableC0114(ar.tvplayer.tv.R.raw.mb, 0, this));
    }

    /* renamed from: ˈ */
    public void mo459() {
        this.f738.post(new androidx.leanback.widget.RunnableC0114(ar.tvplayer.tv.R.raw._6en_res_0x7f120007, 0, this));
    }

    /* renamed from: ˑﹳ, reason: contains not printable characters */
    public final void m548() {
        if (this.f735) {
            return;
        }
        if (!hasFocus()) {
            requestFocus();
        }
        if (this.f717 == null) {
            return;
        }
        if (getContext().checkCallingOrSelfPermission("android.permission.RECORD_AUDIO") != 0) {
            ﾞᵔ.ⁱˊ r0 = this.f720;
            if (r0 == null) {
                throw new java.lang.IllegalStateException("android.permission.RECORD_AUDIO required for search");
            }
            p229.C3109 c3109 = r0.ᴵˊ.ʿʽ;
            boolean z = ʿˋ.ˉʿ.ﹳٴ;
            try {
                c3109.mo6753("android.permission.RECORD_AUDIO");
                return;
            } catch (java.lang.Exception unused) {
                return;
            }
        }
        this.f735 = true;
        this.f734.setText("");
        android.content.Intent intent = new android.content.Intent("android.speech.action.RECOGNIZE_SPEECH");
        intent.putExtra("android.speech.extra.LANGUAGE_MODEL", "free_form");
        intent.putExtra("android.speech.extra.PARTIAL_RESULTS", true);
        this.f717.setRecognitionListener(new androidx.leanback.widget.C0125(this));
        this.f731 = true;
        this.f717.startListening(intent);
    }

    /* renamed from: ᵎﹶ, reason: contains not printable characters */
    public final void m549() throws android.content.res.Resources.NotFoundException {
        java.lang.String string = getResources().getString(ar.tvplayer.tv.R.string.lb_search_bar_hint);
        if (!android.text.TextUtils.isEmpty(this.f733)) {
            string = this.f718.isFocused() ? getResources().getString(ar.tvplayer.tv.R.string._3j_res_0x7f130106, this.f733) : getResources().getString(ar.tvplayer.tv.R.string._2sk_res_0x7f130105, this.f733);
        } else if (this.f718.isFocused()) {
            string = getResources().getString(ar.tvplayer.tv.R.string.ha);
        }
        this.f727 = string;
        androidx.leanback.widget.SearchEditText searchEditText = this.f734;
        if (searchEditText != null) {
            searchEditText.setHint(string);
        }
    }

    /* renamed from: ᵔᵢ, reason: contains not printable characters */
    public final void m550(boolean z) {
        if (z) {
            this.f739.setAlpha(this.f728);
            boolean zIsFocused = this.f718.isFocused();
            int i = this.f730;
            if (zIsFocused) {
                this.f734.setTextColor(i);
                this.f734.setHintTextColor(i);
            } else {
                this.f734.setTextColor(this.f740);
                this.f734.setHintTextColor(i);
            }
        } else {
            this.f739.setAlpha(this.f729);
            this.f734.setTextColor(this.f721);
            this.f734.setHintTextColor(this.f722);
        }
        m549();
    }

    /* renamed from: ⁱˊ */
    public void mo460() {
        this.f738.post(new androidx.leanback.widget.RunnableC0114(ar.tvplayer.tv.R.raw._7s_res_0x7f120004, 0, this));
    }

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final void m551() {
        this.f732.hideSoftInputFromWindow(this.f734.getWindowToken(), 0);
    }

    /* renamed from: ﾞᴵ, reason: contains not printable characters */
    public final void m552() {
        if (this.f735) {
            this.f734.setText(this.f736);
            this.f734.setHint(this.f727);
            this.f735 = false;
            if (this.f717 == null) {
                return;
            }
            this.f718.m556();
            if (this.f731) {
                this.f717.cancel();
                this.f731 = false;
            }
            this.f717.setRecognitionListener(null);
        }
    }
}
