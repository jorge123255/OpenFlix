package androidx.leanback.preference;

/* loaded from: classes.dex */
public class LeanbackSettingsRootView extends android.widget.FrameLayout {

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public android.view.View.OnKeyListener f540;

    public LeanbackSettingsRootView(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet);
    }

    @Override // android.view.ViewGroup, android.view.View
    public final boolean dispatchKeyEvent(android.view.KeyEvent keyEvent) {
        android.view.View.OnKeyListener onKeyListener;
        return ((keyEvent.getAction() != 1 || keyEvent.getKeyCode() != 4 || (onKeyListener = this.f540) == null) ? false : onKeyListener.onKey(this, keyEvent.getKeyCode(), keyEvent)) || super.dispatchKeyEvent(keyEvent);
    }

    public void setOnBackKeyListener(android.view.View.OnKeyListener onKeyListener) {
        this.f540 = onKeyListener;
    }
}
