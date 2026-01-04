package androidx.leanback.widget;

/* loaded from: classes.dex */
public class BrowseRowsFrameLayout extends android.widget.FrameLayout {
    public BrowseRowsFrameLayout(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet, 0);
    }

    @Override // android.view.ViewGroup
    public final void measureChildWithMargins(android.view.View view, int i, int i2, int i3, int i4) {
        android.view.ViewGroup.MarginLayoutParams marginLayoutParams = (android.view.ViewGroup.MarginLayoutParams) view.getLayoutParams();
        view.measure(android.view.ViewGroup.getChildMeasureSpec(i, getPaddingRight() + getPaddingLeft() + i2, marginLayoutParams.width), android.view.ViewGroup.getChildMeasureSpec(i3, getPaddingBottom() + getPaddingTop() + i4, marginLayoutParams.height));
    }
}
