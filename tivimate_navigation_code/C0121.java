package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.יﹳ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C0121 implements p004.InterfaceC0799, p266.InterfaceC3452 {

    /* renamed from: ʽʽ, reason: contains not printable characters */
    public java.lang.Object f955;

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public int f956;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public int f957;

    public C0121(int i) {
        switch (i) {
            case p223.C3056.DOUBLE_FIELD_NUMBER /* 7 */:
                this.f955 = new androidx.leanback.widget.C0121[256];
                this.f956 = 0;
                this.f957 = 0;
                break;
            default:
                this.f955 = new p262.C3433();
                this.f956 = 8000;
                this.f957 = 8000;
                break;
        }
    }

    public C0121(android.content.Context context, android.content.res.XmlResourceParser xmlResourceParser) throws android.content.res.Resources.NotFoundException {
        this.f955 = new java.util.ArrayList();
        this.f957 = -1;
        android.content.res.TypedArray typedArrayObtainStyledAttributes = context.obtainStyledAttributes(android.util.Xml.asAttributeSet(xmlResourceParser), p065.AbstractC1597.f6289);
        int indexCount = typedArrayObtainStyledAttributes.getIndexCount();
        for (int i = 0; i < indexCount; i++) {
            int index = typedArrayObtainStyledAttributes.getIndex(i);
            if (index == 0) {
                this.f956 = typedArrayObtainStyledAttributes.getResourceId(index, this.f956);
            } else if (index == 1) {
                int resourceId = typedArrayObtainStyledAttributes.getResourceId(index, this.f957);
                this.f957 = resourceId;
                java.lang.String resourceTypeName = context.getResources().getResourceTypeName(resourceId);
                context.getResources().getResourceName(resourceId);
                if ("layout".equals(resourceTypeName)) {
                    new p065.C1601().m4377((androidx.constraintlayout.widget.ConstraintLayout) android.view.LayoutInflater.from(context).inflate(resourceId, (android.view.ViewGroup) null));
                }
            }
        }
        typedArrayObtainStyledAttributes.recycle();
    }

    @Override // p004.InterfaceC0799
    /* renamed from: ʽ, reason: contains not printable characters */
    public int mo623() {
        int i = this.f956;
        return i == -1 ? ((p305.C3732) this.f955).m7878() : i;
    }

    @Override // p266.InterfaceC3452
    /* renamed from: ˆʾ, reason: contains not printable characters */
    public p266.InterfaceC3462 mo624() {
        return new p266.C3461(this.f956, this.f957, (p262.C3433) this.f955);
    }

    /* renamed from: ˈ, reason: contains not printable characters */
    public void m625() {
        int i;
        int i2 = this.f956;
        if (i2 != 2) {
            if (i2 != 3 && i2 != 1) {
                this.f955 = null;
                return;
            }
            p179.C2713 c2713 = (p179.C2713) this.f955;
            if (c2713 == null || c2713.m6089() != Integer.MAX_VALUE) {
                this.f955 = new p179.C2713(Integer.MAX_VALUE);
                return;
            }
            return;
        }
        if (this.f957 <= 0) {
            throw new java.lang.IllegalArgumentException();
        }
        p179.C2713 c27132 = (p179.C2713) this.f955;
        if (c27132 != null) {
            synchronized (((ˋⁱ.ﾞᴵ) c27132.f10317)) {
                i = c27132.f10318;
            }
            if (i == this.f957) {
                return;
            }
        }
        this.f955 = new p179.C2713(this.f957);
    }

    @Override // p004.InterfaceC0799
    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public int mo626() {
        return this.f957;
    }

    @Override // p004.InterfaceC0799
    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public int mo627() {
        return this.f956;
    }
}
