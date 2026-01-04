package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ᴵˊ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C0134 implements android.widget.TextView.OnEditorActionListener, androidx.leanback.widget.InterfaceC0111 {

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public final /* synthetic */ java.lang.Object f980;

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final /* synthetic */ int f981;

    public /* synthetic */ C0134(int i, java.lang.Object obj) {
        this.f981 = i;
        this.f980 = obj;
    }

    @Override // android.widget.TextView.OnEditorActionListener
    public final boolean onEditorAction(android.widget.TextView textView, int i, android.view.KeyEvent keyEvent) {
        switch (this.f981) {
            case 0:
                androidx.leanback.widget.C0108 c0108 = (androidx.leanback.widget.C0108) this.f980;
                if (i != 5 && i != 6) {
                    if (i == 1) {
                        c0108.f911.m1592(c0108, textView);
                        break;
                    }
                } else {
                    c0108.f911.m1591(c0108, textView);
                    break;
                }
                break;
            case 1:
                androidx.leanback.widget.SearchBar searchBar = (androidx.leanback.widget.SearchBar) this.f980;
                android.os.Handler handler = searchBar.f738;
                if ((3 != i && i != 0) || searchBar.f719 == null) {
                    if (1 == i && searchBar.f719 != null) {
                        searchBar.m551();
                        handler.postDelayed(new androidx.leanback.widget.RunnableC0110(this, 1), 500L);
                        break;
                    } else if (2 == i) {
                        searchBar.m551();
                        handler.postDelayed(new androidx.leanback.widget.RunnableC0110(this, 2), 500L);
                        break;
                    }
                } else {
                    searchBar.m551();
                    handler.postDelayed(new androidx.leanback.widget.RunnableC0110(this, 0), 500L);
                    break;
                }
                break;
            default:
                p053.C1437 c1437 = (p053.C1437) this.f980;
                if (i == 6 || i == 2 || i == 3 || i == 5 || i == 4) {
                    ((android.view.inputmethod.InputMethodManager) c1437.m6803().getSystemService("input_method")).hideSoftInputFromWindow(textView.getWindowToken(), 0);
                    ((androidx.preference.EditTextPreference) c1437.m4204()).m819(textView.getText().toString());
                    c1437.f11917.m6673();
                    break;
                }
                break;
        }
        return true;
    }

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public boolean m646(android.widget.EditText editText, int i, android.view.KeyEvent keyEvent) {
        androidx.leanback.widget.C0108 c0108 = (androidx.leanback.widget.C0108) this.f980;
        if (i == 4 && keyEvent.getAction() == 1) {
            c0108.f911.m1592(c0108, editText);
            return true;
        }
        if (i != 66 || keyEvent.getAction() != 1) {
            return false;
        }
        c0108.f911.m1591(c0108, editText);
        return true;
    }
}
