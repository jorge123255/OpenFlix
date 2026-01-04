package androidx.leanback.widget.picker;

/* loaded from: classes.dex */
public class DatePicker extends androidx.leanback.widget.picker.Picker {

    /* renamed from: ˏᵢ, reason: contains not printable characters */
    public static final int[] f794 = {5, 2, 1};

    /* renamed from: ʼˈ, reason: contains not printable characters */
    public p244.C3248 f795;

    /* renamed from: ʿ, reason: contains not printable characters */
    public final p404.C4790 f796;

    /* renamed from: ʿᵢ, reason: contains not printable characters */
    public final java.util.Calendar f797;

    /* renamed from: ˈⁱ, reason: contains not printable characters */
    public int f798;

    /* renamed from: ˉـ, reason: contains not printable characters */
    public final java.text.SimpleDateFormat f799;

    /* renamed from: ˊˋ, reason: contains not printable characters */
    public p244.C3248 f800;

    /* renamed from: ˋᵔ, reason: contains not printable characters */
    public java.lang.String f801;

    /* renamed from: ـˏ, reason: contains not printable characters */
    public p244.C3248 f802;

    /* renamed from: ᐧᴵ, reason: contains not printable characters */
    public final java.util.Calendar f803;

    /* renamed from: ᐧﾞ, reason: contains not printable characters */
    public final java.util.Calendar f804;

    /* renamed from: ᴵˑ, reason: contains not printable characters */
    public int f805;

    /* renamed from: ᵎᵔ, reason: contains not printable characters */
    public final java.util.Calendar f806;

    /* renamed from: ﹳـ, reason: contains not printable characters */
    public int f807;

    public DatePicker(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet, ar.tvplayer.tv.R.attr._6m8_res_0x7f0401d5);
        this.f799 = new java.text.SimpleDateFormat("MM/dd/yyyy", java.util.Locale.getDefault());
        java.util.Locale locale = java.util.Locale.getDefault();
        getContext().getResources();
        this.f796 = new p404.C4790(locale);
        this.f803 = ﹳˋ.ٴﹶ.ʽﹳ(this.f803, locale);
        this.f797 = ﹳˋ.ٴﹶ.ʽﹳ(this.f797, (java.util.Locale) this.f796.f18036);
        this.f806 = ﹳˋ.ٴﹶ.ʽﹳ(this.f806, (java.util.Locale) this.f796.f18036);
        this.f804 = ﹳˋ.ٴﹶ.ʽﹳ(this.f804, (java.util.Locale) this.f796.f18036);
        p244.C3248 c3248 = this.f800;
        if (c3248 != null) {
            c3248.f12502 = (java.lang.String[]) this.f796.f18034;
            m563(this.f807, c3248);
        }
        int[] iArr = p272.AbstractC3483.f13665;
        android.content.res.TypedArray typedArrayObtainStyledAttributes = context.obtainStyledAttributes(attributeSet, iArr);
        p186.AbstractC2823.m6282(this, context, iArr, attributeSet, typedArrayObtainStyledAttributes, 0);
        try {
            java.lang.String string = typedArrayObtainStyledAttributes.getString(0);
            java.lang.String string2 = typedArrayObtainStyledAttributes.getString(1);
            java.lang.String string3 = typedArrayObtainStyledAttributes.getString(2);
            typedArrayObtainStyledAttributes.recycle();
            this.f803.clear();
            if (android.text.TextUtils.isEmpty(string) || !m559(string, this.f803)) {
                this.f803.set(1900, 0, 1);
            }
            this.f797.setTimeInMillis(this.f803.getTimeInMillis());
            this.f803.clear();
            if (android.text.TextUtils.isEmpty(string2) || !m559(string2, this.f803)) {
                this.f803.set(2100, 0, 1);
            }
            this.f806.setTimeInMillis(this.f803.getTimeInMillis());
            setDatePickerFormat(android.text.TextUtils.isEmpty(string3) ? new java.lang.String(android.text.format.DateFormat.getDateFormatOrder(context)) : string3);
        } catch (java.lang.Throwable th) {
            typedArrayObtainStyledAttributes.recycle();
            throw th;
        }
    }

    public long getDate() {
        return this.f804.getTimeInMillis();
    }

    public java.lang.String getDatePickerFormat() {
        return this.f801;
    }

    public long getMaxDate() {
        return this.f806.getTimeInMillis();
    }

    public long getMinDate() {
        return this.f797.getTimeInMillis();
    }

    public void setDate(long j) {
        this.f803.setTimeInMillis(j);
        m560(this.f803.get(1), this.f803.get(2), this.f803.get(5));
    }

    public void setDatePickerFormat(java.lang.String str) {
        if (android.text.TextUtils.isEmpty(str)) {
            str = new java.lang.String(android.text.format.DateFormat.getDateFormatOrder(getContext()));
        }
        if (android.text.TextUtils.equals(this.f801, str)) {
            return;
        }
        this.f801 = str;
        p404.C4790 c4790 = this.f796;
        java.lang.String bestDateTimePattern = android.text.format.DateFormat.getBestDateTimePattern((java.util.Locale) c4790.f18036, str);
        if (android.text.TextUtils.isEmpty(bestDateTimePattern)) {
            bestDateTimePattern = "MM/dd/yyyy";
        }
        java.util.ArrayList arrayList = new java.util.ArrayList();
        java.lang.StringBuilder sb = new java.lang.StringBuilder();
        char[] cArr = {'Y', 'y', 'M', 'm', 'D', 'd'};
        boolean z = false;
        char c = 0;
        for (int i = 0; i < bestDateTimePattern.length(); i++) {
            char cCharAt = bestDateTimePattern.charAt(i);
            if (cCharAt != ' ') {
                if (cCharAt != '\'') {
                    if (!z) {
                        int i2 = 0;
                        while (true) {
                            if (i2 >= 6) {
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
                } else if (z) {
                    z = false;
                } else {
                    sb.setLength(0);
                    z = true;
                }
            }
        }
        arrayList.add(sb.toString());
        if (arrayList.size() != str.length() + 1) {
            throw new java.lang.IllegalStateException("Separators size: " + arrayList.size() + " must equal the size of datePickerFormat: " + str.length() + " + 1");
        }
        setSeparators(arrayList);
        this.f795 = null;
        this.f800 = null;
        this.f802 = null;
        this.f807 = -1;
        this.f798 = -1;
        this.f805 = -1;
        java.lang.String upperCase = str.toUpperCase((java.util.Locale) c4790.f18036);
        java.util.ArrayList arrayList2 = new java.util.ArrayList(3);
        for (int i3 = 0; i3 < upperCase.length(); i3++) {
            char cCharAt2 = upperCase.charAt(i3);
            if (cCharAt2 == 'D') {
                if (this.f795 != null) {
                    throw new java.lang.IllegalArgumentException("datePicker format error");
                }
                p244.C3248 c3248 = new p244.C3248();
                this.f795 = c3248;
                arrayList2.add(c3248);
                this.f795.f12503 = "%02d";
                this.f798 = i3;
            } else if (cCharAt2 != 'M') {
                if (cCharAt2 != 'Y') {
                    throw new java.lang.IllegalArgumentException("datePicker format error");
                }
                if (this.f802 != null) {
                    throw new java.lang.IllegalArgumentException("datePicker format error");
                }
                p244.C3248 c32482 = new p244.C3248();
                this.f802 = c32482;
                arrayList2.add(c32482);
                this.f805 = i3;
                this.f802.f12503 = "%d";
            } else {
                if (this.f800 != null) {
                    throw new java.lang.IllegalArgumentException("datePicker format error");
                }
                p244.C3248 c32483 = new p244.C3248();
                this.f800 = c32483;
                arrayList2.add(c32483);
                this.f800.f12502 = (java.lang.String[]) c4790.f18034;
                this.f807 = i3;
            }
        }
        setColumns(arrayList2);
        post(new androidx.leanback.widget.RunnableC0142(26, this));
    }

    public void setMaxDate(long j) {
        this.f803.setTimeInMillis(j);
        if (this.f803.get(1) != this.f806.get(1) || this.f803.get(6) == this.f806.get(6)) {
            this.f806.setTimeInMillis(j);
            if (this.f804.after(this.f806)) {
                this.f804.setTimeInMillis(this.f806.getTimeInMillis());
            }
            post(new androidx.leanback.widget.RunnableC0142(26, this));
        }
    }

    public void setMinDate(long j) {
        this.f803.setTimeInMillis(j);
        if (this.f803.get(1) != this.f797.get(1) || this.f803.get(6) == this.f797.get(6)) {
            this.f797.setTimeInMillis(j);
            if (this.f804.before(this.f797)) {
                this.f804.setTimeInMillis(this.f797.getTimeInMillis());
            }
            post(new androidx.leanback.widget.RunnableC0142(26, this));
        }
    }

    @Override // androidx.leanback.widget.picker.Picker
    /* renamed from: ʽ, reason: contains not printable characters */
    public final void mo558(int i, int i2) {
        this.f803.setTimeInMillis(this.f804.getTimeInMillis());
        int i3 = m568(i).f12505;
        if (i == this.f798) {
            this.f803.add(5, i2 - i3);
        } else if (i == this.f807) {
            this.f803.add(2, i2 - i3);
        } else {
            if (i != this.f805) {
                throw new java.lang.IllegalArgumentException();
            }
            this.f803.add(1, i2 - i3);
        }
        m560(this.f803.get(1), this.f803.get(2), this.f803.get(5));
    }

    /* renamed from: ٴﹶ, reason: contains not printable characters */
    public final boolean m559(java.lang.String str, java.util.Calendar calendar) {
        try {
            calendar.setTime(this.f799.parse(str));
            return true;
        } catch (java.text.ParseException unused) {
            java.lang.String str2 = "Date: " + str + " not in format: MM/dd/yyyy";
            return false;
        }
    }

    /* renamed from: ﾞʻ, reason: contains not printable characters */
    public final void m560(int i, int i2, int i3) {
        if (this.f804.get(1) == i && this.f804.get(2) == i3 && this.f804.get(5) == i2) {
            return;
        }
        this.f804.set(i, i2, i3);
        if (this.f804.before(this.f797)) {
            this.f804.setTimeInMillis(this.f797.getTimeInMillis());
        } else if (this.f804.after(this.f806)) {
            this.f804.setTimeInMillis(this.f806.getTimeInMillis());
        }
        post(new androidx.leanback.widget.RunnableC0142(26, this));
    }
}
