package p053;

/* renamed from: ʽᵔ.ˑﹳ, reason: contains not printable characters */
/* loaded from: classes.dex */
public class C1434 extends p053.C1439 {

    /* renamed from: ʻʿ, reason: contains not printable characters */
    public java.lang.String f5603;

    /* renamed from: ʻᴵ, reason: contains not printable characters */
    public boolean f5604;

    /* renamed from: ʿـ, reason: contains not printable characters */
    public java.lang.CharSequence f5605;

    /* renamed from: ـˊ, reason: contains not printable characters */
    public java.lang.CharSequence[] f5606;

    /* renamed from: ᵎʿ, reason: contains not printable characters */
    public java.lang.CharSequence[] f5607;

    /* renamed from: ⁱי, reason: contains not printable characters */
    public java.util.Set f5608;

    /* renamed from: ﹳⁱ, reason: contains not printable characters */
    public java.lang.CharSequence f5609;

    @Override // p053.C1439, p229.AbstractComponentCallbacksC3123
    /* renamed from: ʽᵔ */
    public final void mo421(android.os.Bundle bundle) {
        super.mo421(bundle);
        if (bundle != null) {
            this.f5605 = bundle.getCharSequence("LeanbackListPreferenceDialogFragment.title");
            this.f5609 = bundle.getCharSequence("LeanbackListPreferenceDialogFragment.message");
            this.f5604 = bundle.getBoolean("LeanbackListPreferenceDialogFragment.isMulti");
            this.f5606 = bundle.getCharSequenceArray("LeanbackListPreferenceDialogFragment.entries");
            this.f5607 = bundle.getCharSequenceArray("LeanbackListPreferenceDialogFragment.entryValues");
            if (!this.f5604) {
                this.f5603 = bundle.getString("LeanbackListPreferenceDialogFragment.initialSelection");
                return;
            }
            java.lang.String[] stringArray = bundle.getStringArray("LeanbackListPreferenceDialogFragment.initialSelections");
            p255.C3370 c3370 = new p255.C3370(stringArray != null ? stringArray.length : 0);
            this.f5608 = c3370;
            if (stringArray != null) {
                java.util.Collections.addAll(c3370, stringArray);
                return;
            }
            return;
        }
        androidx.preference.DialogPreference dialogPreferenceM4204 = m4204();
        this.f5605 = dialogPreferenceM4204.f1332;
        this.f5609 = dialogPreferenceM4204.f1328;
        if (dialogPreferenceM4204 instanceof androidx.preference.ListPreference) {
            this.f5604 = false;
            androidx.preference.ListPreference listPreference = (androidx.preference.ListPreference) dialogPreferenceM4204;
            this.f5606 = listPreference.f1338;
            this.f5607 = listPreference.f1341;
            this.f5603 = listPreference.f1342;
            return;
        }
        if (!(dialogPreferenceM4204 instanceof androidx.preference.MultiSelectListPreference)) {
            throw new java.lang.IllegalArgumentException("Preference must be a ListPreference or MultiSelectListPreference");
        }
        this.f5604 = true;
        androidx.preference.MultiSelectListPreference multiSelectListPreference = (androidx.preference.MultiSelectListPreference) dialogPreferenceM4204;
        this.f5606 = multiSelectListPreference.f1343;
        this.f5607 = multiSelectListPreference.f1344;
        this.f5608 = multiSelectListPreference.f1345;
    }

    @Override // p229.AbstractComponentCallbacksC3123
    /* renamed from: ʾﾞ */
    public final void mo424(android.os.Bundle bundle) {
        bundle.putCharSequence("LeanbackListPreferenceDialogFragment.title", this.f5605);
        bundle.putCharSequence("LeanbackListPreferenceDialogFragment.message", this.f5609);
        bundle.putBoolean("LeanbackListPreferenceDialogFragment.isMulti", this.f5604);
        bundle.putCharSequenceArray("LeanbackListPreferenceDialogFragment.entries", this.f5606);
        bundle.putCharSequenceArray("LeanbackListPreferenceDialogFragment.entryValues", this.f5607);
        if (!this.f5604) {
            bundle.putString("LeanbackListPreferenceDialogFragment.initialSelection", this.f5603);
        } else {
            java.util.Set set = this.f5608;
            bundle.putStringArray("LeanbackListPreferenceDialogFragment.initialSelections", (java.lang.String[]) set.toArray(new java.lang.String[set.size()]));
        }
    }

    @Override // p229.AbstractComponentCallbacksC3123
    /* renamed from: ᐧﹶ */
    public final android.view.View mo435(android.view.LayoutInflater layoutInflater, android.view.ViewGroup viewGroup, android.os.Bundle bundle) {
        android.util.TypedValue typedValue = new android.util.TypedValue();
        m6803().getTheme().resolveAttribute(ar.tvplayer.tv.R.attr._5lg_res_0x7f0404fb, typedValue, true);
        int i = typedValue.resourceId;
        if (i == 0) {
            i = ar.tvplayer.tv.R.style._4kk_res_0x7f1401b3;
        }
        android.view.View viewInflate = layoutInflater.cloneInContext(new android.view.ContextThemeWrapper(m6803(), i)).inflate(ar.tvplayer.tv.R.layout._2bj_res_0x7f0e00cf, viewGroup, false);
        androidx.leanback.widget.VerticalGridView verticalGridView = (androidx.leanback.widget.VerticalGridView) viewInflate.findViewById(android.R.id.list);
        verticalGridView.setWindowAlignment(3);
        verticalGridView.setFocusScrollStrategy(0);
        verticalGridView.setAdapter(this.f5604 ? new p053.C1432(this, this.f5606, this.f5607, this.f5608) : new p053.C1432(this, this.f5606, this.f5607, this.f5603));
        verticalGridView.requestFocus();
        java.lang.CharSequence charSequence = this.f5605;
        if (!android.text.TextUtils.isEmpty(charSequence)) {
            ((android.widget.TextView) viewInflate.findViewById(ar.tvplayer.tv.R.id.up)).setText(charSequence);
        }
        java.lang.CharSequence charSequence2 = this.f5609;
        if (!android.text.TextUtils.isEmpty(charSequence2)) {
            android.widget.TextView textView = (android.widget.TextView) viewInflate.findViewById(android.R.id.message);
            textView.setVisibility(0);
            textView.setText(charSequence2);
        }
        return viewInflate;
    }
}
