package androidx.leanback.widget.picker;

/* loaded from: classes.dex */
public class TimePicker extends androidx.leanback.widget.picker.Picker {

    /* renamed from: ʼˈ, reason: contains not printable characters */
    public p244.C3248 f824;

    /* renamed from: ʿ, reason: contains not printable characters */
    public int f825;

    /* renamed from: ʿᵢ, reason: contains not printable characters */
    public int f826;

    /* renamed from: ˈⁱ, reason: contains not printable characters */
    public int f827;

    /* renamed from: ˉـ, reason: contains not printable characters */
    public boolean f828;

    /* renamed from: ˊˋ, reason: contains not printable characters */
    public p244.C3248 f829;

    /* renamed from: ˋᵔ, reason: contains not printable characters */
    public p244.C3248 f830;

    /* renamed from: ـˏ, reason: contains not printable characters */
    public int f831;

    /* renamed from: ᐧﾞ, reason: contains not printable characters */
    public java.lang.String f832;

    /* renamed from: ᴵˑ, reason: contains not printable characters */
    public final ˏˆ.ﹳٴ f833;

    /* renamed from: ᵎᵔ, reason: contains not printable characters */
    public int f834;

    /* renamed from: ﹳـ, reason: contains not printable characters */
    public int f835;

    public TimePicker(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet, ar.tvplayer.tv.R.attr._174_res_0x7f040673);
        java.util.Locale locale = java.util.Locale.getDefault();
        context.getResources();
        this.f833 = new ˏˆ.ﹳٴ(locale);
        int[] iArr = p272.AbstractC3483.f13664;
        android.content.res.TypedArray typedArrayObtainStyledAttributes = context.obtainStyledAttributes(attributeSet, iArr);
        p186.AbstractC2823.m6282(this, context, iArr, attributeSet, typedArrayObtainStyledAttributes, 0);
        try {
            this.f828 = typedArrayObtainStyledAttributes.getBoolean(0, android.text.format.DateFormat.is24HourFormat(context));
            boolean z = typedArrayObtainStyledAttributes.getBoolean(3, true);
            typedArrayObtainStyledAttributes.recycle();
            m570();
            m571();
            if (z) {
                java.util.Calendar calendar = java.util.Calendar.getInstance(locale);
                setHour(calendar.get(11));
                setMinute(calendar.get(12));
                if (this.f828) {
                    return;
                }
                m564(this.f827, this.f834);
            }
        } catch (java.lang.Throwable th) {
            typedArrayObtainStyledAttributes.recycle();
            throw th;
        }
    }

    public java.lang.String getBestHourMinutePattern() {
        java.lang.String bestDateTimePattern = android.text.format.DateFormat.getBestDateTimePattern((java.util.Locale) this.f833.ᴵˊ, this.f828 ? "Hma" : "hma");
        return android.text.TextUtils.isEmpty(bestDateTimePattern) ? "h:mma" : bestDateTimePattern;
    }

    public int getHour() {
        return this.f828 ? this.f825 : this.f834 == 0 ? this.f825 % 12 : (this.f825 % 12) + 12;
    }

    public int getMinute() {
        return this.f826;
    }

    public void setHour(int i) {
        if (i < 0 || i > 23) {
            throw new java.lang.IllegalArgumentException(p035.AbstractC1220.m3773(i, "hour: ", " is not in [0-23] range in"));
        }
        this.f825 = i;
        boolean z = this.f828;
        if (!z) {
            if (i >= 12) {
                this.f834 = 1;
                if (i > 12) {
                    this.f825 = i - 12;
                }
            } else {
                this.f834 = 0;
                if (i == 0) {
                    this.f825 = 12;
                }
            }
            if (!z) {
                m564(this.f827, this.f834);
            }
        }
        m564(this.f831, this.f825);
    }

    public void setIs24Hour(boolean z) {
        if (this.f828 == z) {
            return;
        }
        int hour = getHour();
        int minute = getMinute();
        this.f828 = z;
        m570();
        m571();
        setHour(hour);
        setMinute(minute);
        if (this.f828) {
            return;
        }
        m564(this.f827, this.f834);
    }

    public void setMinute(int i) {
        if (i < 0 || i > 59) {
            throw new java.lang.IllegalArgumentException(p035.AbstractC1220.m3773(i, "minute: ", " is not in [0-59] range."));
        }
        this.f826 = i;
        m564(this.f835, i);
    }

    @Override // androidx.leanback.widget.picker.Picker
    /* renamed from: ʽ */
    public final void mo558(int i, int i2) {
        if (i == this.f831) {
            this.f825 = i2;
        } else if (i == this.f835) {
            this.f826 = i2;
        } else {
            if (i != this.f827) {
                throw new java.lang.IllegalArgumentException("Invalid column index.");
            }
            this.f834 = i2;
        }
    }

    /* renamed from: ٴﹶ, reason: contains not printable characters */
    public final void m570() {
        java.lang.String bestHourMinutePattern = getBestHourMinutePattern();
        if (android.text.TextUtils.equals(bestHourMinutePattern, this.f832)) {
            return;
        }
        this.f832 = bestHourMinutePattern;
        java.lang.String bestHourMinutePattern2 = getBestHourMinutePattern();
        ˏˆ.ﹳٴ r1 = this.f833;
        boolean z = android.text.TextUtils.getLayoutDirectionFromLocale((java.util.Locale) r1.ᴵˊ) == 1;
        boolean z2 = bestHourMinutePattern2.indexOf(97) < 0 || bestHourMinutePattern2.indexOf("a") > bestHourMinutePattern2.indexOf("m");
        java.lang.String strConcat = z ? "mh" : "hm";
        if (!this.f828) {
            strConcat = z2 ? strConcat.concat("a") : "a".concat(strConcat);
        }
        java.lang.String bestHourMinutePattern3 = getBestHourMinutePattern();
        java.util.ArrayList arrayList = new java.util.ArrayList();
        java.lang.StringBuilder sb = new java.lang.StringBuilder();
        char[] cArr = {'H', 'h', 'K', 'k', 'm', 'M', 'a'};
        boolean z3 = false;
        char c = 0;
        for (int i = 0; i < bestHourMinutePattern3.length(); i++) {
            char cCharAt = bestHourMinutePattern3.charAt(i);
            if (cCharAt != ' ') {
                if (cCharAt != '\'') {
                    if (!z3) {
                        int i2 = 0;
                        while (true) {
                            if (i2 >= 7) {
                                sb.append(cCharAt);
                                break;
                            } else if (cCharAt != cArr[i2]) {
                                i2++;
                            } else if (cCharAt != c) {
                                arrayList.add(sb.toString());
                                sb.setLength(0);
                            }
                        }
                    } else {
                        sb.append(cCharAt);
                    }
                    c = cCharAt;
                } else if (z3) {
                    z3 = false;
                } else {
                    sb.setLength(0);
                    z3 = true;
                }
            }
        }
        arrayList.add(sb.toString());
        if (arrayList.size() != strConcat.length() + 1) {
            throw new java.lang.IllegalStateException("Separators size: " + arrayList.size() + " must equal the size of timeFieldsPattern: " + strConcat.length() + " + 1");
        }
        setSeparators(arrayList);
        java.lang.String upperCase = strConcat.toUpperCase((java.util.Locale) r1.ᴵˊ);
        this.f824 = null;
        this.f829 = null;
        this.f830 = null;
        this.f827 = -1;
        this.f835 = -1;
        this.f831 = -1;
        java.util.ArrayList arrayList2 = new java.util.ArrayList(3);
        for (int i3 = 0; i3 < upperCase.length(); i3++) {
            char cCharAt2 = upperCase.charAt(i3);
            if (cCharAt2 == 'A') {
                p244.C3248 c3248 = new p244.C3248();
                this.f824 = c3248;
                arrayList2.add(c3248);
                p244.C3248 c32482 = this.f824;
                c32482.f12502 = (java.lang.String[]) r1.ᴵᵔ;
                this.f827 = i3;
                if (c32482.f12504 != 0) {
                    c32482.f12504 = 0;
                }
                if (1 != c32482.f12501) {
                    c32482.f12501 = 1;
                }
            } else if (cCharAt2 == 'H') {
                p244.C3248 c32483 = new p244.C3248();
                this.f830 = c32483;
                arrayList2.add(c32483);
                this.f830.f12502 = (java.lang.String[]) r1.ʽʽ;
                this.f831 = i3;
            } else {
                if (cCharAt2 != 'M') {
                    throw new java.lang.IllegalArgumentException("Invalid time picker format.");
                }
                p244.C3248 c32484 = new p244.C3248();
                this.f829 = c32484;
                arrayList2.add(c32484);
                this.f829.f12502 = (java.lang.String[]) r1.ˈٴ;
                this.f835 = i3;
            }
        }
        setColumns(arrayList2);
    }

    /* renamed from: ﾞʻ, reason: contains not printable characters */
    public final void m571() {
        p244.C3248 c3248 = this.f830;
        boolean z = this.f828;
        int i = !z ? 1 : 0;
        if (i != c3248.f12504) {
            c3248.f12504 = i;
        }
        int i2 = z ? 23 : 12;
        if (i2 != c3248.f12501) {
            c3248.f12501 = i2;
        }
        p244.C3248 c32482 = this.f829;
        if (c32482.f12504 != 0) {
            c32482.f12504 = 0;
        }
        if (59 != c32482.f12501) {
            c32482.f12501 = 59;
        }
        p244.C3248 c32483 = this.f824;
        if (c32483 != null) {
            if (c32483.f12504 != 0) {
                c32483.f12504 = 0;
            }
            if (1 != c32483.f12501) {
                c32483.f12501 = 1;
            }
        }
    }
}
