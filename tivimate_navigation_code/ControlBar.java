package androidx.leanback.widget;

/* loaded from: classes.dex */
class ControlBar extends android.widget.LinearLayout {

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public int f592;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public final boolean f593;

    public ControlBar(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet);
        this.f592 = -1;
        this.f593 = true;
    }

    @Override // android.view.ViewGroup, android.view.View
    public final void addFocusables(java.util.ArrayList arrayList, int i, int i2) {
        if (i != 33 && i != 130) {
            super.addFocusables(arrayList, i, i2);
            return;
        }
        int i3 = this.f592;
        if (i3 >= 0 && i3 < getChildCount()) {
            arrayList.add(getChildAt(this.f592));
        } else if (getChildCount() > 0) {
            arrayList.add(getChildAt(this.f593 ? getChildCount() / 2 : 0));
        }
    }

    @Override // android.widget.LinearLayout, android.view.View
    public final void onMeasure(int i, int i2) {
        super.onMeasure(i, i2);
    }

    @Override // android.view.ViewGroup
    public final boolean onRequestFocusInDescendants(int i, android.graphics.Rect rect) {
        if (getChildCount() > 0) {
            int i2 = this.f592;
            if (getChildAt((i2 < 0 || i2 >= getChildCount()) ? this.f593 ? getChildCount() / 2 : 0 : this.f592).requestFocus(i, rect)) {
                return true;
            }
        }
        return super.onRequestFocusInDescendants(i, rect);
    }

    @Override // android.view.ViewGroup, android.view.ViewParent
    public final void requestChildFocus(android.view.View view, android.view.View view2) {
        super.requestChildFocus(view, view2);
        this.f592 = indexOfChild(view);
    }
}
