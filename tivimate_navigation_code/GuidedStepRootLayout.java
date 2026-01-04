package androidx.leanback.app;

/* loaded from: classes.dex */
class GuidedStepRootLayout extends android.widget.LinearLayout {
    public GuidedStepRootLayout(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet);
    }

    @Override // android.view.ViewGroup, android.view.ViewParent
    public final android.view.View focusSearch(android.view.View view, int i) {
        android.view.View viewFocusSearch = super.focusSearch(view, i);
        if ((i != 17 && i != 66) || ˈˆ.ﾞᴵ.ˈٴ(this, viewFocusSearch)) {
            return viewFocusSearch;
        }
        getLayoutDirection();
        return view;
    }
}
