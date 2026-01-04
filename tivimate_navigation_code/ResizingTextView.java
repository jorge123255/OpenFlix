package androidx.leanback.widget;

@android.annotation.SuppressLint({"AppCompatCustomView"})
/* loaded from: classes.dex */
class ResizingTextView extends android.widget.TextView {

    /* renamed from: ʽʽ, reason: contains not printable characters */
    public final boolean f703;

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public final int f704;

    /* renamed from: ˈٴ, reason: contains not printable characters */
    public final int f705;

    /* renamed from: ˉٴ, reason: contains not printable characters */
    public float f706;

    /* renamed from: ˊʻ, reason: contains not printable characters */
    public boolean f707;

    /* renamed from: ٴʼ, reason: contains not printable characters */
    public int f708;

    /* renamed from: ٴᵢ, reason: contains not printable characters */
    public int f709;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public final int f710;

    /* renamed from: ᴵᵔ, reason: contains not printable characters */
    public final int f711;

    /* renamed from: ᵎⁱ, reason: contains not printable characters */
    public int f712;

    public ResizingTextView(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet, android.R.attr.textViewStyle);
        this.f707 = false;
        android.content.res.TypedArray typedArrayObtainStyledAttributes = context.obtainStyledAttributes(attributeSet, p272.AbstractC3483.f13672, android.R.attr.textViewStyle, 0);
        try {
            this.f704 = typedArrayObtainStyledAttributes.getInt(1, 1);
            this.f710 = typedArrayObtainStyledAttributes.getDimensionPixelSize(4, -1);
            this.f703 = typedArrayObtainStyledAttributes.getBoolean(0, false);
            this.f705 = typedArrayObtainStyledAttributes.getDimensionPixelOffset(3, 0);
            this.f711 = typedArrayObtainStyledAttributes.getDimensionPixelOffset(2, 0);
        } finally {
            typedArrayObtainStyledAttributes.recycle();
        }
    }

    /* JADX WARN: Removed duplicated region for block: B:13:0x0053  */
    /* JADX WARN: Removed duplicated region for block: B:42:0x00cd A[PHI: r2
      0x00cd: PHI (r2v6 boolean) = (r2v2 boolean), (r2v8 boolean) binds: [B:40:0x00ca, B:27:0x0097] A[DONT_GENERATE, DONT_INLINE]] */
    @Override // android.widget.TextView, android.view.View
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct add '--show-bad-code' argument
    */
    public final void onMeasure(int r8, int r9) {
        /*
            Method dump skipped, instructions count: 220
            To view this dump add '--comments-level debug' option
        */
        throw new UnsupportedOperationException("Method not decompiled: androidx.leanback.widget.ResizingTextView.onMeasure(int, int):void");
    }

    @Override // android.widget.TextView
    public final void setCustomSelectionActionModeCallback(android.view.ActionMode.Callback callback) {
        super.setCustomSelectionActionModeCallback(ﹳٴ.ﹳٴ.ˉـ(callback, this));
    }

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final void m547(int i, int i2) {
        if (isPaddingRelative()) {
            setPaddingRelative(getPaddingStart(), i, getPaddingEnd(), i2);
        } else {
            setPadding(getPaddingLeft(), i, getPaddingRight(), i2);
        }
    }
}
