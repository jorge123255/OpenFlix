package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ʾᵎ, reason: contains not printable characters */
/* loaded from: classes.dex */
public class C0095 {

    /* renamed from: ʼˎ, reason: contains not printable characters */
    public int f870;

    /* renamed from: ʽ, reason: contains not printable characters */
    public java.lang.CharSequence f871;

    /* renamed from: ˆʾ, reason: contains not printable characters */
    public int f872;

    /* renamed from: ˈ, reason: contains not printable characters */
    public java.lang.CharSequence f873;

    /* renamed from: ˉʿ, reason: contains not printable characters */
    public int f874;

    /* renamed from: ˑﹳ, reason: contains not printable characters */
    public int f875;

    /* renamed from: ٴﹶ, reason: contains not printable characters */
    public int f876;

    /* renamed from: ᵎﹶ, reason: contains not printable characters */
    public java.lang.CharSequence f877;

    /* renamed from: ᵔᵢ, reason: contains not printable characters */
    public int f878;

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public android.graphics.drawable.Drawable f879;

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public long f880;

    /* renamed from: ﾞʻ, reason: contains not printable characters */
    public int f881;

    /* renamed from: ﾞᴵ, reason: contains not printable characters */
    public java.lang.CharSequence f882;

    public final java.lang.String toString() {
        java.lang.StringBuilder sb = new java.lang.StringBuilder();
        if (!android.text.TextUtils.isEmpty(this.f871)) {
            sb.append(this.f871);
        }
        if (!android.text.TextUtils.isEmpty(this.f873)) {
            if (!android.text.TextUtils.isEmpty(this.f871)) {
                sb.append(" ");
            }
            sb.append(this.f873);
        }
        if (this.f879 != null && sb.length() == 0) {
            sb.append("(action icon)");
        }
        return sb.toString();
    }

    /* renamed from: ʽ, reason: contains not printable characters */
    public final boolean m579() {
        return this.f878 == 1;
    }

    /* renamed from: ˈ, reason: contains not printable characters */
    public final boolean m580() {
        return (this.f875 & 16) == 16;
    }

    /* renamed from: ˑﹳ, reason: contains not printable characters */
    public final void m581(java.lang.String str, android.os.Bundle bundle) {
        int i;
        if (m579()) {
            java.lang.String string = bundle.getString(str);
            if (string != null) {
                this.f871 = string;
                return;
            }
            return;
        }
        if (this.f878 != 2 || (i = this.f881 & 4080) == 128 || i == 144 || i == 224) {
            if (this.f874 != 0) {
                m583(bundle.getBoolean(str, m584()) ? 1 : 0, 1);
            }
        } else {
            java.lang.String string2 = bundle.getString(str);
            if (string2 != null) {
                this.f873 = string2;
            }
        }
    }

    /* renamed from: ᵎﹶ, reason: contains not printable characters */
    public final void m582(boolean z) {
        m583(z ? 16 : 0, 16);
    }

    /* renamed from: ᵔᵢ, reason: contains not printable characters */
    public final void m583(int i, int i2) {
        this.f875 = (i & i2) | (this.f875 & (~i2));
    }

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public final boolean m584() {
        return (this.f875 & 1) == 1;
    }

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final boolean m585() {
        return this.f878 == 3;
    }

    /* renamed from: ﾞᴵ, reason: contains not printable characters */
    public final void m586(java.lang.String str, android.os.Bundle bundle) {
        int i;
        java.lang.CharSequence charSequence;
        java.lang.CharSequence charSequence2;
        if (m579() && (charSequence2 = this.f871) != null) {
            bundle.putString(str, charSequence2.toString());
            return;
        }
        if (this.f878 == 2 && (i = this.f881 & 4080) != 128 && i != 144 && i != 224 && (charSequence = this.f873) != null) {
            bundle.putString(str, charSequence.toString());
        } else if (this.f874 != 0) {
            bundle.putBoolean(str, m584());
        }
    }
}
