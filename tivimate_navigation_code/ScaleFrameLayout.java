package androidx.leanback.widget;

/* loaded from: classes.dex */
public class ScaleFrameLayout extends android.widget.FrameLayout {

    /* renamed from: ʽʽ, reason: contains not printable characters */
    public float f713;

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public float f714;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public float f715;

    public ScaleFrameLayout(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet, 0);
        this.f714 = 1.0f;
        this.f715 = 1.0f;
        this.f713 = 1.0f;
    }

    @Override // android.view.ViewGroup
    public final void addView(android.view.View view, int i, android.view.ViewGroup.LayoutParams layoutParams) {
        super.addView(view, i, layoutParams);
        view.setScaleX(this.f713);
        view.setScaleY(this.f713);
    }

    @Override // android.view.ViewGroup
    public final boolean addViewInLayout(android.view.View view, int i, android.view.ViewGroup.LayoutParams layoutParams, boolean z) {
        boolean zAddViewInLayout = super.addViewInLayout(view, i, layoutParams, z);
        if (zAddViewInLayout) {
            view.setScaleX(this.f713);
            view.setScaleY(this.f713);
        }
        return zAddViewInLayout;
    }

    /* JADX WARN: Removed duplicated region for block: B:33:0x00c9  */
    /* JADX WARN: Removed duplicated region for block: B:42:0x00de  */
    @Override // android.widget.FrameLayout, android.view.ViewGroup, android.view.View
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct add '--show-bad-code' argument
    */
    public final void onLayout(boolean r17, int r18, int r19, int r20, int r21) {
        /*
            Method dump skipped, instructions count: 259
            To view this dump add '--comments-level debug' option
        */
        throw new UnsupportedOperationException("Method not decompiled: androidx.leanback.widget.ScaleFrameLayout.onLayout(boolean, int, int, int, int):void");
    }

    @Override // android.widget.FrameLayout, android.view.View
    public final void onMeasure(int i, int i2) {
        float f = this.f714;
        if (f == 1.0f && this.f715 == 1.0f) {
            super.onMeasure(i, i2);
            return;
        }
        if (f != 1.0f) {
            i = android.view.View.MeasureSpec.makeMeasureSpec((int) ((android.view.View.MeasureSpec.getSize(i) / f) + 0.5f), android.view.View.MeasureSpec.getMode(i));
        }
        float f2 = this.f715;
        if (f2 != 1.0f) {
            i2 = android.view.View.MeasureSpec.makeMeasureSpec((int) ((android.view.View.MeasureSpec.getSize(i2) / f2) + 0.5f), android.view.View.MeasureSpec.getMode(i2));
        }
        super.onMeasure(i, i2);
        setMeasuredDimension((int) ((getMeasuredWidth() * this.f714) + 0.5f), (int) ((getMeasuredHeight() * this.f715) + 0.5f));
    }

    public void setChildScale(float f) {
        if (this.f713 != f) {
            this.f713 = f;
            for (int i = 0; i < getChildCount(); i++) {
                getChildAt(i).setScaleX(f);
                getChildAt(i).setScaleY(f);
            }
        }
    }

    @Override // android.view.View
    public void setForeground(android.graphics.drawable.Drawable drawable) {
        throw new java.lang.UnsupportedOperationException();
    }

    public void setLayoutScaleX(float f) {
        if (f != this.f714) {
            this.f714 = f;
            requestLayout();
        }
    }

    public void setLayoutScaleY(float f) {
        if (f != this.f715) {
            this.f715 = f;
            requestLayout();
        }
    }
}
