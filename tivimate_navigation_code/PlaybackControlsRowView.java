package androidx.leanback.widget;

/* loaded from: classes.dex */
class PlaybackControlsRowView extends android.widget.LinearLayout {
    public PlaybackControlsRowView(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet);
    }

    @Override // android.view.ViewGroup, android.view.View
    public final boolean dispatchKeyEvent(android.view.KeyEvent keyEvent) {
        return super.dispatchKeyEvent(keyEvent);
    }

    @Override // android.view.View
    public final boolean hasOverlappingRendering() {
        return false;
    }

    @Override // android.view.ViewGroup
    public final boolean onRequestFocusInDescendants(int i, android.graphics.Rect rect) {
        android.view.View viewFindFocus = findFocus();
        if (viewFindFocus == null || !viewFindFocus.requestFocus(i, rect)) {
            return super.onRequestFocusInDescendants(i, rect);
        }
        return true;
    }
}
