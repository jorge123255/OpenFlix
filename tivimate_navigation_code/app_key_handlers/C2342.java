package p137;

/* renamed from: ˉˆ.ﹶ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C2342 extends p137.C2249 {

    /* renamed from: ˆﾞ, reason: contains not printable characters */
    public final int f9083;

    /* renamed from: ˈʿ, reason: contains not printable characters */
    public p137.InterfaceC2340 f9084;

    /* renamed from: ˑٴ, reason: contains not printable characters */
    public p353.C4329 f9085;

    /* renamed from: ᵔٴ, reason: contains not printable characters */
    public final int f9086;

    public C2342(android.content.Context context, boolean z) {
        super(context, z);
        if (1 == context.getResources().getConfiguration().getLayoutDirection()) {
            this.f9083 = 21;
            this.f9086 = 22;
        } else {
            this.f9083 = 22;
            this.f9086 = 21;
        }
    }

    @Override // p137.C2249, android.view.View
    public final boolean onHoverEvent(android.view.MotionEvent motionEvent) {
        p353.C4321 c4321;
        int headersCount;
        int iPointToPosition;
        int i;
        if (this.f9084 != null) {
            android.widget.ListAdapter adapter = getAdapter();
            if (adapter instanceof android.widget.HeaderViewListAdapter) {
                android.widget.HeaderViewListAdapter headerViewListAdapter = (android.widget.HeaderViewListAdapter) adapter;
                headersCount = headerViewListAdapter.getHeadersCount();
                c4321 = (p353.C4321) headerViewListAdapter.getWrappedAdapter();
            } else {
                c4321 = (p353.C4321) adapter;
                headersCount = 0;
            }
            p353.C4329 c4329M8751 = (motionEvent.getAction() == 10 || (iPointToPosition = pointToPosition((int) motionEvent.getX(), (int) motionEvent.getY())) == -1 || (i = iPointToPosition - headersCount) < 0 || i >= c4321.getCount()) ? null : c4321.getItem(i);
            p353.C4329 c4329 = this.f9085;
            if (c4329 != c4329M8751) {
                p353.MenuC4312 menuC4312 = c4321.f16025;
                if (c4329 != null) {
                    this.f9084.mo5350(menuC4312, c4329);
                }
                this.f9085 = c4329M8751;
                if (c4329M8751 != null) {
                    this.f9084.mo5351(menuC4312, c4329M8751);
                }
            }
        }
        return super.onHoverEvent(motionEvent);
    }

    @Override // android.widget.ListView, android.widget.AbsListView, android.view.View, android.view.KeyEvent.Callback
    public final boolean onKeyDown(int i, android.view.KeyEvent keyEvent) {
        androidx.appcompat.view.menu.ListMenuItemView listMenuItemView = (androidx.appcompat.view.menu.ListMenuItemView) getSelectedView();
        if (listMenuItemView != null && i == this.f9083) {
            if (listMenuItemView.isEnabled() && listMenuItemView.getItemData().hasSubMenu()) {
                performItemClick(listMenuItemView, getSelectedItemPosition(), getSelectedItemId());
            }
            return true;
        }
        if (listMenuItemView == null || i != this.f9086) {
            return super.onKeyDown(i, keyEvent);
        }
        setSelection(-1);
        android.widget.ListAdapter adapter = getAdapter();
        (adapter instanceof android.widget.HeaderViewListAdapter ? (p353.C4321) ((android.widget.HeaderViewListAdapter) adapter).getWrappedAdapter() : (p353.C4321) adapter).f16025.m8723(false);
        return true;
    }

    public void setHoverListener(p137.InterfaceC2340 interfaceC2340) {
        this.f9084 = interfaceC2340;
    }

    @Override // p137.C2249, android.widget.AbsListView
    public /* bridge */ /* synthetic */ void setSelector(android.graphics.drawable.Drawable drawable) {
        super.setSelector(drawable);
    }
}
