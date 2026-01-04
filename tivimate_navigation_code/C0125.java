package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ـﹶ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C0125 implements android.speech.RecognitionListener {

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final /* synthetic */ androidx.leanback.widget.SearchBar f970;

    public C0125(androidx.leanback.widget.SearchBar searchBar) {
        this.f970 = searchBar;
    }

    @Override // android.speech.RecognitionListener
    public final void onBeginningOfSpeech() {
    }

    @Override // android.speech.RecognitionListener
    public final void onBufferReceived(byte[] bArr) {
    }

    @Override // android.speech.RecognitionListener
    public final void onEndOfSpeech() {
    }

    @Override // android.speech.RecognitionListener
    public final void onError(int i) {
        switch (i) {
            case 1:
                int i2 = androidx.leanback.widget.SearchBar.f716;
                break;
            case 2:
                int i3 = androidx.leanback.widget.SearchBar.f716;
                break;
            case 3:
                int i4 = androidx.leanback.widget.SearchBar.f716;
                break;
            case 4:
                int i5 = androidx.leanback.widget.SearchBar.f716;
                break;
            case 5:
                int i6 = androidx.leanback.widget.SearchBar.f716;
                break;
            case p223.C3056.STRING_SET_FIELD_NUMBER /* 6 */:
                int i7 = androidx.leanback.widget.SearchBar.f716;
                break;
            case p223.C3056.DOUBLE_FIELD_NUMBER /* 7 */:
                int i8 = androidx.leanback.widget.SearchBar.f716;
                break;
            case p223.C3056.BYTES_FIELD_NUMBER /* 8 */:
                int i9 = androidx.leanback.widget.SearchBar.f716;
                break;
            case 9:
                int i10 = androidx.leanback.widget.SearchBar.f716;
                break;
            default:
                int i11 = androidx.leanback.widget.SearchBar.f716;
                break;
        }
        androidx.leanback.widget.SearchBar searchBar = this.f970;
        searchBar.m552();
        searchBar.mo460();
    }

    @Override // android.speech.RecognitionListener
    public final void onEvent(int i, android.os.Bundle bundle) {
    }

    @Override // android.speech.RecognitionListener
    public final void onPartialResults(android.os.Bundle bundle) {
        java.util.ArrayList<java.lang.String> stringArrayList = bundle.getStringArrayList("results_recognition");
        if (stringArrayList == null || stringArrayList.size() == 0) {
            return;
        }
        java.lang.String str = stringArrayList.get(0);
        java.lang.String str2 = stringArrayList.size() > 1 ? stringArrayList.get(1) : null;
        androidx.leanback.widget.SearchEditText searchEditText = this.f970.f734;
        searchEditText.getClass();
        if (str == null) {
            str = "";
        }
        android.text.SpannableStringBuilder spannableStringBuilder = new android.text.SpannableStringBuilder(str);
        if (str2 != null) {
            int length = spannableStringBuilder.length();
            spannableStringBuilder.append((java.lang.CharSequence) str2);
            java.util.regex.Matcher matcher = androidx.leanback.widget.AbstractC0093.f862.matcher(str2);
            while (matcher.find()) {
                int iStart = matcher.start() + length;
                spannableStringBuilder.setSpan(new androidx.leanback.widget.C0119(searchEditText, str2.charAt(matcher.start()), iStart), iStart, matcher.end() + length, 33);
            }
        }
        searchEditText.f866 = java.lang.Math.max(str.length(), searchEditText.f866);
        searchEditText.setText(new android.text.SpannedString(spannableStringBuilder));
        searchEditText.bringPointIntoView(searchEditText.length());
        android.animation.ObjectAnimator objectAnimator = searchEditText.f868;
        if (objectAnimator != null) {
            objectAnimator.cancel();
        }
        int streamPosition = searchEditText.getStreamPosition();
        int length2 = searchEditText.length();
        int i = length2 - streamPosition;
        if (i > 0) {
            if (searchEditText.f868 == null) {
                android.animation.ObjectAnimator objectAnimator2 = new android.animation.ObjectAnimator();
                searchEditText.f868 = objectAnimator2;
                objectAnimator2.setTarget(searchEditText);
                searchEditText.f868.setProperty(androidx.leanback.widget.AbstractC0093.f863);
            }
            searchEditText.f868.setIntValues(streamPosition, length2);
            searchEditText.f868.setDuration(i * 50);
            searchEditText.f868.start();
        }
    }

    @Override // android.speech.RecognitionListener
    public final void onReadyForSpeech(android.os.Bundle bundle) {
        androidx.leanback.widget.SearchBar searchBar = this.f970;
        androidx.leanback.widget.SpeechOrbView speechOrbView = searchBar.f718;
        speechOrbView.setOrbColors(speechOrbView.f780);
        speechOrbView.setOrbIcon(speechOrbView.getResources().getDrawable(2131231125));
        speechOrbView.m554(true);
        speechOrbView.f746 = false;
        speechOrbView.m553();
        android.view.View view = speechOrbView.f744;
        view.setScaleX(1.0f);
        view.setScaleY(1.0f);
        speechOrbView.f779 = 0;
        speechOrbView.f777 = true;
        searchBar.mo458();
    }

    @Override // android.speech.RecognitionListener
    public final void onResults(android.os.Bundle bundle) {
        androidx.leanback.widget.InterfaceC0102 interfaceC0102;
        java.util.ArrayList<java.lang.String> stringArrayList = bundle.getStringArrayList("results_recognition");
        androidx.leanback.widget.SearchBar searchBar = this.f970;
        if (stringArrayList != null) {
            java.lang.String str = stringArrayList.get(0);
            searchBar.f736 = str;
            searchBar.f734.setText(str);
            if (!android.text.TextUtils.isEmpty(searchBar.f736) && (interfaceC0102 = searchBar.f719) != null) {
                ﾞᵔ.ˉٴ.ʽᐧ((ﾞᵔ.ˉٴ) ((p384.C4603) interfaceC0102).f17126, searchBar.f736, true);
            }
        }
        searchBar.m552();
        searchBar.mo459();
    }

    @Override // android.speech.RecognitionListener
    public final void onRmsChanged(float f) {
        this.f970.f718.setSoundLevel(f < 0.0f ? 0 : (int) (f * 10.0f));
    }
}
