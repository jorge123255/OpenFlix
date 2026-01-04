package androidx.leanback.widget;

/* loaded from: classes.dex */
public class BrowseFrameLayout extends android.widget.FrameLayout {

    /* renamed from: ʽʽ, reason: contains not printable characters */
    public android.view.View.OnKeyListener f587;

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public androidx.leanback.widget.InterfaceC0098 f588;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public androidx.leanback.widget.InterfaceC0085 f589;

    public BrowseFrameLayout(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet, 0);
    }

    @Override // android.view.ViewGroup, android.view.View
    public final boolean dispatchKeyEvent(android.view.KeyEvent keyEvent) {
        boolean zDispatchKeyEvent = super.dispatchKeyEvent(keyEvent);
        android.view.View.OnKeyListener onKeyListener = this.f587;
        return (onKeyListener == null || zDispatchKeyEvent) ? zDispatchKeyEvent : onKeyListener.onKey(getRootView(), keyEvent.getKeyCode(), keyEvent);
    }

    @Override // android.view.ViewGroup, android.view.ViewParent
    public final android.view.View focusSearch(android.view.View view, int i) {
        android.view.View viewM589;
        androidx.leanback.widget.InterfaceC0098 interfaceC0098 = this.f588;
        return (interfaceC0098 == null || (viewM589 = interfaceC0098.m589(view, i)) == null) ? super.focusSearch(view, i) : viewM589;
    }

    public androidx.leanback.widget.InterfaceC0085 getOnChildFocusListener() {
        return this.f589;
    }

    public androidx.leanback.widget.InterfaceC0098 getOnFocusSearchListener() {
        return this.f588;
    }

    @Override // android.view.ViewGroup
    public final boolean onRequestFocusInDescendants(int i, android.graphics.Rect rect) {
        androidx.leanback.widget.InterfaceC0085 interfaceC0085 = this.f589;
        if (interfaceC0085 == null) {
            return super.onRequestFocusInDescendants(i, rect);
        }
        interfaceC0085.m572(i, rect);
        return true;
    }

    public void setOnChildFocusListener(androidx.leanback.widget.InterfaceC0085 interfaceC0085) {
        this.f589 = interfaceC0085;
    }

    public void setOnDispatchKeyListener(android.view.View.OnKeyListener onKeyListener) {
        this.f587 = onKeyListener;
    }

    public void setOnFocusSearchListener(androidx.leanback.widget.InterfaceC0098 interfaceC0098) {
        this.f588 = interfaceC0098;
    }
}
