package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ˆﾞ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C0099 extends android.view.View.AccessibilityDelegate {

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public final /* synthetic */ java.lang.Object f884;

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final /* synthetic */ int f885;

    public /* synthetic */ C0099(int i, java.lang.Object obj) {
        this.f885 = i;
        this.f884 = obj;
    }

    @Override // android.view.View.AccessibilityDelegate
    public void onInitializeAccessibilityEvent(android.view.View view, android.view.accessibility.AccessibilityEvent accessibilityEvent) {
        switch (this.f885) {
            case 0:
                super.onInitializeAccessibilityEvent(view, accessibilityEvent);
                androidx.leanback.widget.C0095 c0095 = ((androidx.leanback.widget.C0101) this.f884).f896;
                accessibilityEvent.setChecked(c0095 != null && c0095.m584());
                break;
            default:
                super.onInitializeAccessibilityEvent(view, accessibilityEvent);
                break;
        }
    }

    @Override // android.view.View.AccessibilityDelegate
    public final void onInitializeAccessibilityNodeInfo(android.view.View view, android.view.accessibility.AccessibilityNodeInfo accessibilityNodeInfo) {
        switch (this.f885) {
            case 0:
                super.onInitializeAccessibilityNodeInfo(view, accessibilityNodeInfo);
                androidx.leanback.widget.C0101 c0101 = (androidx.leanback.widget.C0101) this.f884;
                androidx.leanback.widget.C0095 c0095 = c0101.f896;
                boolean z = false;
                accessibilityNodeInfo.setCheckable((c0095 == null || c0095.f874 == 0) ? false : true);
                androidx.leanback.widget.C0095 c00952 = c0101.f896;
                if (c00952 != null && c00952.m584()) {
                    z = true;
                }
                accessibilityNodeInfo.setChecked(z);
                break;
            default:
                super.onInitializeAccessibilityNodeInfo(view, accessibilityNodeInfo);
                android.widget.EditText editText = ((p044.C1336) this.f884).f5151.getEditText();
                if (editText != null) {
                    accessibilityNodeInfo.setLabeledBy(editText);
                    break;
                }
                break;
        }
    }
}
