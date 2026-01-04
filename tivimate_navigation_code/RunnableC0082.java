package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ʻᵎ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class RunnableC0082 implements java.lang.Runnable {

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public final /* synthetic */ int f838;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public final /* synthetic */ androidx.leanback.widget.SearchBar f839;

    public /* synthetic */ RunnableC0082(androidx.leanback.widget.SearchBar searchBar, int i) {
        this.f838 = i;
        this.f839 = searchBar;
    }

    @Override // java.lang.Runnable
    public final void run() {
        switch (this.f838) {
            case 0:
                androidx.leanback.widget.SearchBar searchBar = this.f839;
                searchBar.setSearchQueryInternal(searchBar.f734.getText().toString());
                break;
            default:
                androidx.leanback.widget.SearchBar searchBar2 = this.f839;
                searchBar2.f734.requestFocusFromTouch();
                searchBar2.f734.dispatchTouchEvent(android.view.MotionEvent.obtain(android.os.SystemClock.uptimeMillis(), android.os.SystemClock.uptimeMillis(), 0, searchBar2.f734.getWidth(), searchBar2.f734.getHeight(), 0));
                searchBar2.f734.dispatchTouchEvent(android.view.MotionEvent.obtain(android.os.SystemClock.uptimeMillis(), android.os.SystemClock.uptimeMillis(), 1, searchBar2.f734.getWidth(), searchBar2.f734.getHeight(), 0));
                break;
        }
    }
}
