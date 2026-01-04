package androidx.leanback.widget;

/* loaded from: classes.dex */
public class TitleView extends android.widget.FrameLayout {

    /* renamed from: ʽʽ, reason: contains not printable characters */
    public final androidx.leanback.widget.SearchOrbView f788;

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public final android.widget.ImageView f789;

    /* renamed from: ˈٴ, reason: contains not printable characters */
    public final int f790;

    /* renamed from: ˊʻ, reason: contains not printable characters */
    public final androidx.leanback.widget.C0115 f791;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public final android.widget.TextView f792;

    /* renamed from: ᴵᵔ, reason: contains not printable characters */
    public boolean f793;

    public TitleView(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet, ar.tvplayer.tv.R.attr._28p_res_0x7f0400aa);
        this.f790 = 6;
        this.f793 = false;
        this.f791 = new androidx.leanback.widget.C0115();
        android.view.View viewInflate = android.view.LayoutInflater.from(context).inflate(ar.tvplayer.tv.R.layout._45l_res_0x7f0e00ca, this);
        this.f789 = (android.widget.ImageView) viewInflate.findViewById(ar.tvplayer.tv.R.id._2rp_res_0x7f0b03ad);
        this.f792 = (android.widget.TextView) viewInflate.findViewById(ar.tvplayer.tv.R.id._5n4_res_0x7f0b03b0);
        this.f788 = (androidx.leanback.widget.SearchOrbView) viewInflate.findViewById(ar.tvplayer.tv.R.id._3ou_res_0x7f0b03ae);
        setClipToPadding(false);
        setClipChildren(false);
    }

    public android.graphics.drawable.Drawable getBadgeDrawable() {
        return this.f789.getDrawable();
    }

    public androidx.leanback.widget.C0116 getSearchAffordanceColors() {
        return this.f788.getOrbColors();
    }

    public android.view.View getSearchAffordanceView() {
        return this.f788;
    }

    public java.lang.CharSequence getTitle() {
        return this.f792.getText();
    }

    public androidx.leanback.widget.AbstractC0086 getTitleViewAdapter() {
        return this.f791;
    }

    public void setBadgeDrawable(android.graphics.drawable.Drawable drawable) {
        android.widget.ImageView imageView = this.f789;
        imageView.setImageDrawable(drawable);
        android.graphics.drawable.Drawable drawable2 = imageView.getDrawable();
        android.widget.TextView textView = this.f792;
        if (drawable2 != null) {
            imageView.setVisibility(0);
            textView.setVisibility(8);
        } else {
            imageView.setVisibility(8);
            textView.setVisibility(0);
        }
    }

    public void setOnSearchClickedListener(android.view.View.OnClickListener onClickListener) {
        this.f793 = onClickListener != null;
        androidx.leanback.widget.SearchOrbView searchOrbView = this.f788;
        searchOrbView.setOnOrbClickedListener(onClickListener);
        searchOrbView.setVisibility((this.f793 && (this.f790 & 4) == 4) ? 0 : 4);
    }

    public void setSearchAffordanceColors(androidx.leanback.widget.C0116 c0116) {
        this.f788.setOrbColors(c0116);
    }

    public void setTitle(java.lang.CharSequence charSequence) {
        android.widget.TextView textView = this.f792;
        textView.setText(charSequence);
        android.widget.ImageView imageView = this.f789;
        if (imageView.getDrawable() != null) {
            imageView.setVisibility(0);
            textView.setVisibility(8);
        } else {
            imageView.setVisibility(8);
            textView.setVisibility(0);
        }
    }
}
