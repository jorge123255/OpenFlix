package androidx.leanback.widget;

/* loaded from: classes.dex */
public class SearchEditText extends androidx.leanback.widget.AbstractC0093 {

    /* renamed from: ˉٴ, reason: contains not printable characters */
    public androidx.leanback.widget.InterfaceC0152 f742;

    public SearchEditText(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet);
    }

    @Override // android.widget.TextView, android.view.View
    public final boolean onKeyPreIme(int i, android.view.KeyEvent keyEvent) {
        if (keyEvent.getKeyCode() == 4 && this.f742 != null) {
            post(new androidx.leanback.widget.RunnableC0142(1, this));
        }
        return super.onKeyPreIme(i, keyEvent);
    }

    @Override // androidx.leanback.widget.AbstractC0093, android.widget.TextView
    public /* bridge */ /* synthetic */ void setCustomSelectionActionModeCallback(android.view.ActionMode.Callback callback) {
        super.setCustomSelectionActionModeCallback(callback);
    }

    public void setFinalRecognizedText(java.lang.CharSequence charSequence) {
        setText(charSequence);
        bringPointIntoView(length());
    }

    public void setOnKeyboardDismissListener(androidx.leanback.widget.InterfaceC0152 interfaceC0152) {
        this.f742 = interfaceC0152;
    }
}
