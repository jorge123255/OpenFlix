package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ʽﹳ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C0092 implements android.os.Parcelable {
    public static final android.os.Parcelable.Creator<androidx.leanback.widget.C0092> CREATOR = new androidx.leanback.widget.C0113();

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public int f860;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public android.os.Bundle f861;

    @Override // android.os.Parcelable
    public final int describeContents() {
        return 0;
    }

    @Override // android.os.Parcelable
    public final void writeToParcel(android.os.Parcel parcel, int i) {
        parcel.writeInt(this.f860);
        parcel.writeBundle(this.f861);
    }
}
