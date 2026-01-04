package androidx.leanback.widget;

/* loaded from: classes.dex */
class NonOverlappingView extends android.view.View {
    public NonOverlappingView(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet, 0);
    }

    @Override // android.view.View
    public final boolean hasOverlappingRendering() {
        return false;
    }
}
