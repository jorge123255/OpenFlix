package androidx.leanback.widget;

/* loaded from: classes.dex */
public class VerticalGridView extends androidx.leanback.widget.AbstractC0145 {
    public VerticalGridView(android.content.Context context, android.util.AttributeSet attributeSet) {
        this(context, attributeSet, 0);
    }

    public VerticalGridView(android.content.Context context, android.util.AttributeSet attributeSet, int i) {
        super(context, attributeSet);
        this.f1005.m495(1);
        m654(context, attributeSet);
        int[] iArr = androidx.leanback.widget.AbstractC0130.f971;
        android.content.res.TypedArray typedArrayObtainStyledAttributes = context.obtainStyledAttributes(attributeSet, iArr);
        p186.AbstractC2823.m6282(this, context, iArr, attributeSet, typedArrayObtainStyledAttributes, 0);
        setColumnWidth(typedArrayObtainStyledAttributes);
        setNumColumns(typedArrayObtainStyledAttributes.getInt(1, 1));
        typedArrayObtainStyledAttributes.recycle();
    }

    public void setColumnWidth(int i) {
        this.f1005.m466(i);
        requestLayout();
    }

    public void setColumnWidth(android.content.res.TypedArray typedArray) {
        if (typedArray.peekValue(0) != null) {
            setColumnWidth(typedArray.getLayoutDimension(0, 0));
        }
    }

    public void setNumColumns(int i) {
        androidx.leanback.widget.GridLayoutManager gridLayoutManager = this.f1005;
        if (i < 0) {
            gridLayoutManager.getClass();
            throw new java.lang.IllegalArgumentException();
        }
        gridLayoutManager.f629 = i;
        requestLayout();
    }
}
