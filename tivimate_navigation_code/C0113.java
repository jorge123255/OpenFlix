package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ˏי, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C0113 implements android.os.Parcelable.Creator {
    @Override // android.os.Parcelable.Creator
    public final java.lang.Object createFromParcel(android.os.Parcel parcel) {
        androidx.leanback.widget.C0092 c0092 = new androidx.leanback.widget.C0092();
        c0092.f861 = android.os.Bundle.EMPTY;
        c0092.f860 = parcel.readInt();
        c0092.f861 = parcel.readBundle(androidx.leanback.widget.GridLayoutManager.class.getClassLoader());
        return c0092;
    }

    @Override // android.os.Parcelable.Creator
    public final java.lang.Object[] newArray(int i) {
        return new androidx.leanback.widget.C0092[i];
    }
}
