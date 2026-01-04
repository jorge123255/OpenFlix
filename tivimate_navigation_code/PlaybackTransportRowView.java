package androidx.leanback.widget;

/* loaded from: classes.dex */
public class PlaybackTransportRowView extends android.widget.LinearLayout {
    public PlaybackTransportRowView(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet);
    }

    @Override // android.view.ViewGroup, android.view.View
    public final boolean dispatchKeyEvent(android.view.KeyEvent keyEvent) {
        return super.dispatchKeyEvent(keyEvent);
    }

    @Override // android.view.ViewGroup, android.view.ViewParent
    public final android.view.View focusSearch(android.view.View view, int i) {
        android.view.View childAt;
        if (view != null) {
            if (i == 33) {
                for (int iIndexOfChild = indexOfChild(getFocusedChild()) - 1; iIndexOfChild >= 0; iIndexOfChild--) {
                    android.view.View childAt2 = getChildAt(iIndexOfChild);
                    if (childAt2.hasFocusable()) {
                        return childAt2;
                    }
                }
            } else {
                if (i == 130) {
                    int iIndexOfChild2 = indexOfChild(getFocusedChild());
                    do {
                        iIndexOfChild2++;
                        if (iIndexOfChild2 < getChildCount()) {
                            childAt = getChildAt(iIndexOfChild2);
                        }
                    } while (!childAt.hasFocusable());
                    return childAt;
                }
                if ((i == 17 || i == 66) && (getFocusedChild() instanceof android.view.ViewGroup)) {
                    return android.view.FocusFinder.getInstance().findNextFocus((android.view.ViewGroup) getFocusedChild(), view, i);
                }
            }
        }
        return super.focusSearch(view, i);
    }

    public androidx.leanback.widget.InterfaceC0132 getOnUnhandledKeyListener() {
        return null;
    }

    @Override // android.view.View
    public final boolean hasOverlappingRendering() {
        return false;
    }

    @Override // android.view.ViewGroup
    public final boolean onRequestFocusInDescendants(int i, android.graphics.Rect rect) {
        android.view.View viewFindFocus = findFocus();
        if (viewFindFocus != null && viewFindFocus.requestFocus(i, rect)) {
            return true;
        }
        android.view.View viewFindViewById = findViewById(ar.tvplayer.tv.R.id.j6);
        if (viewFindViewById != null && viewFindViewById.isFocusable() && viewFindViewById.requestFocus(i, rect)) {
            return true;
        }
        return super.onRequestFocusInDescendants(i, rect);
    }

    public void setOnUnhandledKeyListener(androidx.leanback.widget.InterfaceC0132 interfaceC0132) {
    }
}
