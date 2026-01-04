package androidx.leanback.widget;

/* loaded from: classes.dex */
class NonOverlappingRelativeLayout extends android.widget.RelativeLayout {
    public NonOverlappingRelativeLayout(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet, 0);
    }

    @Override // android.view.View
    public final boolean hasOverlappingRendering() {
        return false;
    }
}
