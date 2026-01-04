package androidx.leanback.widget;

/* loaded from: classes.dex */
public class ThumbsBar extends android.widget.LinearLayout {

    /* renamed from: ʽʽ, reason: contains not printable characters */
    public final int f781;

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public int f782;

    /* renamed from: ˈٴ, reason: contains not printable characters */
    public final int f783;

    /* renamed from: ˊʻ, reason: contains not printable characters */
    public int f784;

    /* renamed from: ٴᵢ, reason: contains not printable characters */
    public boolean f785;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public final int f786;

    /* renamed from: ᴵᵔ, reason: contains not printable characters */
    public final int f787;

    public ThumbsBar(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet, 0);
        this.f782 = -1;
        new android.util.SparseArray();
        this.f785 = false;
        this.f786 = context.getResources().getDimensionPixelSize(ar.tvplayer.tv.R.dimen._77h_res_0x7f07019f);
        this.f781 = context.getResources().getDimensionPixelSize(ar.tvplayer.tv.R.dimen._4f6_res_0x7f07019d);
        this.f787 = context.getResources().getDimensionPixelSize(ar.tvplayer.tv.R.dimen._5ij_res_0x7f070195);
        this.f783 = context.getResources().getDimensionPixelSize(ar.tvplayer.tv.R.dimen._3t2_res_0x7f070194);
        this.f784 = context.getResources().getDimensionPixelSize(ar.tvplayer.tv.R.dimen._55i_res_0x7f07019e);
    }

    public int getHeroIndex() {
        return getChildCount() / 2;
    }

    @Override // android.widget.LinearLayout, android.view.ViewGroup, android.view.View
    public final void onLayout(boolean z, int i, int i2, int i3, int i4) {
        super.onLayout(z, i, i2, i3, i4);
        int heroIndex = getHeroIndex();
        android.view.View childAt = getChildAt(heroIndex);
        int width = (getWidth() / 2) - (childAt.getMeasuredWidth() / 2);
        int measuredWidth = (childAt.getMeasuredWidth() / 2) + (getWidth() / 2);
        childAt.layout(width, getPaddingTop(), measuredWidth, childAt.getMeasuredHeight() + getPaddingTop());
        int measuredHeight = (childAt.getMeasuredHeight() / 2) + getPaddingTop();
        for (int i5 = heroIndex - 1; i5 >= 0; i5--) {
            int i6 = width - this.f784;
            android.view.View childAt2 = getChildAt(i5);
            childAt2.layout(i6 - childAt2.getMeasuredWidth(), measuredHeight - (childAt2.getMeasuredHeight() / 2), i6, (childAt2.getMeasuredHeight() / 2) + measuredHeight);
            width = i6 - childAt2.getMeasuredWidth();
        }
        while (true) {
            heroIndex++;
            if (heroIndex >= this.f782) {
                return;
            }
            int i7 = measuredWidth + this.f784;
            android.view.View childAt3 = getChildAt(heroIndex);
            childAt3.layout(i7, measuredHeight - (childAt3.getMeasuredHeight() / 2), childAt3.getMeasuredWidth() + i7, (childAt3.getMeasuredHeight() / 2) + measuredHeight);
            measuredWidth = i7 + childAt3.getMeasuredWidth();
        }
    }

    @Override // android.widget.LinearLayout, android.view.View
    public final void onMeasure(int i, int i2) {
        super.onMeasure(i, i2);
        int measuredWidth = getMeasuredWidth();
        if (this.f785) {
            return;
        }
        int i3 = measuredWidth - this.f783;
        int i4 = ((i3 + r3) - 1) / (this.f786 + this.f784);
        if (i4 < 2) {
            i4 = 2;
        } else if ((i4 & 1) != 0) {
            i4++;
        }
        int i5 = i4 + 1;
        if (this.f782 != i5) {
            this.f782 = i5;
            m557();
        }
    }

    public void setNumberOfThumbs(int i) {
        this.f785 = true;
        this.f782 = i;
        m557();
    }

    public void setThumbSpace(int i) {
        this.f784 = i;
        requestLayout();
    }

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final void m557() {
        int i;
        int i2;
        while (getChildCount() > this.f782) {
            removeView(getChildAt(getChildCount() - 1));
        }
        while (true) {
            int childCount = getChildCount();
            int i3 = this.f782;
            i = this.f781;
            i2 = this.f786;
            if (childCount >= i3) {
                break;
            } else {
                addView(new android.widget.ImageView(getContext()), new android.widget.LinearLayout.LayoutParams(i2, i));
            }
        }
        int heroIndex = getHeroIndex();
        for (int i4 = 0; i4 < getChildCount(); i4++) {
            android.view.View childAt = getChildAt(i4);
            android.widget.LinearLayout.LayoutParams layoutParams = (android.widget.LinearLayout.LayoutParams) childAt.getLayoutParams();
            if (heroIndex == i4) {
                layoutParams.width = this.f783;
                layoutParams.height = this.f787;
            } else {
                layoutParams.width = i2;
                layoutParams.height = i;
            }
            childAt.setLayoutParams(layoutParams);
        }
    }
}
