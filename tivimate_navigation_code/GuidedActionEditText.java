package androidx.leanback.widget;

@android.annotation.SuppressLint({"AppCompatCustomView"})
/* loaded from: classes.dex */
public class GuidedActionEditText extends android.widget.EditText implements androidx.leanback.widget.InterfaceC0109, androidx.leanback.widget.InterfaceC0107 {

    /* renamed from: ʽʽ, reason: contains not printable characters */
    public final android.graphics.drawable.Drawable f645;

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public androidx.leanback.widget.InterfaceC0111 f646;

    /* renamed from: ˈٴ, reason: contains not printable characters */
    public final androidx.leanback.widget.C0126 f647;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public androidx.leanback.widget.InterfaceC0127 f648;

    public GuidedActionEditText(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet, android.R.attr.editTextStyle);
        this.f645 = getBackground();
        androidx.leanback.widget.C0126 c0126 = new androidx.leanback.widget.C0126();
        this.f647 = c0126;
        setBackground(c0126);
    }

    @Override // android.widget.TextView, android.view.View
    public final void autofill(android.view.autofill.AutofillValue autofillValue) {
        super.autofill(autofillValue);
        androidx.leanback.widget.InterfaceC0127 interfaceC0127 = this.f648;
        if (interfaceC0127 != null) {
            androidx.leanback.widget.C0108 c0108 = ((androidx.leanback.widget.C0094) interfaceC0127).f869;
            c0108.f911.m1591(c0108, this);
        }
    }

    @Override // android.widget.TextView, android.view.View
    public int getAutofillType() {
        return 1;
    }

    @Override // android.widget.TextView, android.view.View
    public final void onFocusChanged(boolean z, int i, android.graphics.Rect rect) {
        super.onFocusChanged(z, i, rect);
        if (z) {
            setBackground(this.f645);
        } else {
            setBackground(this.f647);
        }
        if (z) {
            return;
        }
        setFocusable(false);
    }

    @Override // android.view.View
    public final void onInitializeAccessibilityNodeInfo(android.view.accessibility.AccessibilityNodeInfo accessibilityNodeInfo) {
        super.onInitializeAccessibilityNodeInfo(accessibilityNodeInfo);
        accessibilityNodeInfo.setClassName((isFocused() ? android.widget.EditText.class : android.widget.TextView.class).getName());
    }

    @Override // android.widget.TextView, android.view.View
    public final boolean onKeyPreIme(int i, android.view.KeyEvent keyEvent) {
        androidx.leanback.widget.InterfaceC0111 interfaceC0111 = this.f646;
        boolean zM646 = interfaceC0111 != null ? ((androidx.leanback.widget.C0134) interfaceC0111).m646(this, i, keyEvent) : false;
        return !zM646 ? super.onKeyPreIme(i, keyEvent) : zM646;
    }

    @Override // android.widget.TextView, android.view.View
    public final boolean onTouchEvent(android.view.MotionEvent motionEvent) {
        if (!isInTouchMode() || isFocusableInTouchMode() || isTextSelectable()) {
            return super.onTouchEvent(motionEvent);
        }
        return false;
    }

    @Override // android.widget.TextView
    public void setCustomSelectionActionModeCallback(android.view.ActionMode.Callback callback) {
        super.setCustomSelectionActionModeCallback(ﹳٴ.ﹳٴ.ˉـ(callback, this));
    }

    @Override // androidx.leanback.widget.InterfaceC0109
    public void setImeKeyListener(androidx.leanback.widget.InterfaceC0111 interfaceC0111) {
        this.f646 = interfaceC0111;
    }

    @Override // androidx.leanback.widget.InterfaceC0107
    public void setOnAutofillListener(androidx.leanback.widget.InterfaceC0127 interfaceC0127) {
        this.f648 = interfaceC0127;
    }
}
