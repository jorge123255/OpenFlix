package androidx.leanback.widget;

/* loaded from: classes.dex */
public class PagingIndicator extends android.view.View {

    /* renamed from: ʿ, reason: contains not printable characters */
    public static final androidx.leanback.widget.C0097 f677;

    /* renamed from: ʿᵢ, reason: contains not printable characters */
    public static final androidx.leanback.widget.C0097 f678;

    /* renamed from: ˉـ, reason: contains not printable characters */
    public static final androidx.leanback.widget.C0097 f679;

    /* renamed from: ᴵˑ, reason: contains not printable characters */
    public static final android.view.animation.DecelerateInterpolator f680 = new android.view.animation.DecelerateInterpolator();

    /* renamed from: ʼˈ, reason: contains not printable characters */
    public android.graphics.Bitmap f681;

    /* renamed from: ʽʽ, reason: contains not printable characters */
    public final int f682;

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public boolean f683;

    /* renamed from: ˆﾞ, reason: contains not printable characters */
    public int f684;

    /* renamed from: ˈʿ, reason: contains not printable characters */
    public int f685;

    /* renamed from: ˈٴ, reason: contains not printable characters */
    public final int f686;

    /* renamed from: ˈⁱ, reason: contains not printable characters */
    public final float f687;

    /* renamed from: ˉٴ, reason: contains not printable characters */
    public final int f688;

    /* renamed from: ˊʻ, reason: contains not printable characters */
    public final int f689;

    /* renamed from: ˊˋ, reason: contains not printable characters */
    public final android.graphics.Paint f690;

    /* renamed from: ˋᵔ, reason: contains not printable characters */
    public final android.graphics.Paint f691;

    /* renamed from: ˑٴ, reason: contains not printable characters */
    public int f692;

    /* renamed from: ـˏ, reason: contains not printable characters */
    public android.graphics.Paint f693;

    /* renamed from: ٴʼ, reason: contains not printable characters */
    public int[] f694;

    /* renamed from: ٴᵢ, reason: contains not printable characters */
    public final int f695;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public final int f696;

    /* renamed from: ᴵᵔ, reason: contains not printable characters */
    public final int f697;

    /* renamed from: ᵎˊ, reason: contains not printable characters */
    public int[] f698;

    /* renamed from: ᵎⁱ, reason: contains not printable characters */
    public androidx.leanback.widget.C0139[] f699;

    /* renamed from: ᵔי, reason: contains not printable characters */
    public int[] f700;

    /* renamed from: ᵔٴ, reason: contains not printable characters */
    public int f701;

    /* renamed from: ﹳـ, reason: contains not printable characters */
    public final android.graphics.Rect f702;

    static {
        java.lang.Class<java.lang.Float> cls = java.lang.Float.class;
        f679 = new androidx.leanback.widget.C0097(cls, "alpha", 0);
        f677 = new androidx.leanback.widget.C0097(cls, "diameter", 1);
        f678 = new androidx.leanback.widget.C0097(cls, "translation_x", 2);
    }

    public PagingIndicator(android.content.Context context, android.util.AttributeSet attributeSet) throws android.content.res.Resources.NotFoundException {
        super(context, attributeSet, 0);
        android.animation.AnimatorSet animatorSet = new android.animation.AnimatorSet();
        android.content.res.Resources resources = getResources();
        int[] iArr = p272.AbstractC3483.f13670;
        android.content.res.TypedArray typedArrayObtainStyledAttributes = context.obtainStyledAttributes(attributeSet, iArr, 0, 0);
        p186.AbstractC2823.m6282(this, context, iArr, attributeSet, typedArrayObtainStyledAttributes, 0);
        int dimensionPixelOffset = typedArrayObtainStyledAttributes.getDimensionPixelOffset(6, getResources().getDimensionPixelOffset(ar.tvplayer.tv.R.dimen._6da_res_0x7f07016f));
        this.f682 = dimensionPixelOffset;
        int i = dimensionPixelOffset * 2;
        this.f696 = i;
        int dimensionPixelOffset2 = typedArrayObtainStyledAttributes.getDimensionPixelOffset(2, getResources().getDimensionPixelOffset(ar.tvplayer.tv.R.dimen.r4));
        this.f689 = dimensionPixelOffset2;
        int i2 = dimensionPixelOffset2 * 2;
        this.f697 = i2;
        this.f686 = typedArrayObtainStyledAttributes.getDimensionPixelOffset(5, getResources().getDimensionPixelOffset(ar.tvplayer.tv.R.dimen._56_res_0x7f07016e));
        this.f695 = typedArrayObtainStyledAttributes.getDimensionPixelOffset(4, getResources().getDimensionPixelOffset(ar.tvplayer.tv.R.dimen.o4));
        int color = typedArrayObtainStyledAttributes.getColor(3, getResources().getColor(ar.tvplayer.tv.R.color._59k_res_0x7f0600e1));
        android.graphics.Paint paint = new android.graphics.Paint(1);
        this.f691 = paint;
        paint.setColor(color);
        this.f692 = typedArrayObtainStyledAttributes.getColor(0, getResources().getColor(ar.tvplayer.tv.R.color._3lb_res_0x7f0600df));
        if (this.f693 == null && typedArrayObtainStyledAttributes.hasValue(1)) {
            setArrowColor(typedArrayObtainStyledAttributes.getColor(1, 0));
        }
        typedArrayObtainStyledAttributes.recycle();
        this.f683 = resources.getConfiguration().getLayoutDirection() == 0;
        int color2 = resources.getColor(ar.tvplayer.tv.R.color._183_res_0x7f0600e0);
        int dimensionPixelSize = resources.getDimensionPixelSize(ar.tvplayer.tv.R.dimen._44k_res_0x7f07016d);
        this.f688 = dimensionPixelSize;
        android.graphics.Paint paint2 = new android.graphics.Paint(1);
        this.f690 = paint2;
        float dimensionPixelSize2 = resources.getDimensionPixelSize(ar.tvplayer.tv.R.dimen._4d3_res_0x7f07016c);
        paint2.setShadowLayer(dimensionPixelSize, dimensionPixelSize2, dimensionPixelSize2, color2);
        this.f681 = m544();
        this.f702 = new android.graphics.Rect(0, 0, this.f681.getWidth(), this.f681.getHeight());
        float f = i2;
        this.f687 = this.f681.getWidth() / f;
        android.animation.AnimatorSet animatorSet2 = new android.animation.AnimatorSet();
        androidx.leanback.widget.C0097 c0097 = f679;
        android.animation.ObjectAnimator objectAnimatorOfFloat = android.animation.ObjectAnimator.ofFloat((java.lang.Object) null, c0097, 0.0f, 1.0f);
        objectAnimatorOfFloat.setDuration(167L);
        android.view.animation.DecelerateInterpolator decelerateInterpolator = f680;
        objectAnimatorOfFloat.setInterpolator(decelerateInterpolator);
        float f2 = i;
        androidx.leanback.widget.C0097 c00972 = f677;
        android.animation.ObjectAnimator objectAnimatorOfFloat2 = android.animation.ObjectAnimator.ofFloat((java.lang.Object) null, c00972, f2, f);
        objectAnimatorOfFloat2.setDuration(417L);
        objectAnimatorOfFloat2.setInterpolator(decelerateInterpolator);
        animatorSet2.playTogether(objectAnimatorOfFloat, objectAnimatorOfFloat2, m543());
        android.animation.AnimatorSet animatorSet3 = new android.animation.AnimatorSet();
        android.animation.ObjectAnimator objectAnimatorOfFloat3 = android.animation.ObjectAnimator.ofFloat((java.lang.Object) null, c0097, 1.0f, 0.0f);
        objectAnimatorOfFloat3.setDuration(167L);
        objectAnimatorOfFloat3.setInterpolator(decelerateInterpolator);
        android.animation.ObjectAnimator objectAnimatorOfFloat4 = android.animation.ObjectAnimator.ofFloat((java.lang.Object) null, c00972, f, f2);
        objectAnimatorOfFloat4.setDuration(417L);
        objectAnimatorOfFloat4.setInterpolator(decelerateInterpolator);
        animatorSet3.playTogether(objectAnimatorOfFloat3, objectAnimatorOfFloat4, m543());
        animatorSet.playTogether(animatorSet2, animatorSet3);
        setLayerType(1, null);
    }

    private int getDesiredHeight() {
        return getPaddingBottom() + getPaddingTop() + this.f697 + this.f688;
    }

    private int getDesiredWidth() {
        return getPaddingRight() + getPaddingLeft() + getRequiredWidth();
    }

    private int getRequiredWidth() {
        return ((this.f701 - 3) * this.f686) + (this.f695 * 2) + (this.f682 * 2);
    }

    private void setSelectedPage(int i) {
        if (i == this.f685) {
            return;
        }
        this.f685 = i;
        m546();
    }

    public int[] getDotSelectedLeftX() {
        return this.f698;
    }

    public int[] getDotSelectedRightX() {
        return this.f700;
    }

    public int[] getDotSelectedX() {
        return this.f694;
    }

    public int getPageCount() {
        return this.f701;
    }

    @Override // android.view.View
    public final void onDraw(android.graphics.Canvas canvas) {
        for (int i = 0; i < this.f701; i++) {
            androidx.leanback.widget.C0139 c0139 = this.f699[i];
            float f = c0139.f987 + c0139.f985;
            androidx.leanback.widget.PagingIndicator pagingIndicator = c0139.f986;
            int i2 = pagingIndicator.f684;
            android.graphics.Paint paint = pagingIndicator.f690;
            canvas.drawCircle(f, i2, c0139.f993, pagingIndicator.f691);
            if (c0139.f992 > 0.0f) {
                paint.setColor(c0139.f991);
                canvas.drawCircle(f, pagingIndicator.f684, c0139.f993, paint);
                android.graphics.Bitmap bitmap = pagingIndicator.f681;
                android.graphics.Rect rect = pagingIndicator.f702;
                float f2 = c0139.f989;
                float f3 = pagingIndicator.f684;
                canvas.drawBitmap(bitmap, rect, new android.graphics.Rect((int) (f - f2), (int) (f3 - f2), (int) (f + f2), (int) (f3 + f2)), pagingIndicator.f693);
            }
        }
    }

    @Override // android.view.View
    public final void onMeasure(int i, int i2) {
        int desiredHeight = getDesiredHeight();
        int mode = android.view.View.MeasureSpec.getMode(i2);
        if (mode == Integer.MIN_VALUE) {
            desiredHeight = java.lang.Math.min(desiredHeight, android.view.View.MeasureSpec.getSize(i2));
        } else if (mode == 1073741824) {
            desiredHeight = android.view.View.MeasureSpec.getSize(i2);
        }
        int desiredWidth = getDesiredWidth();
        int mode2 = android.view.View.MeasureSpec.getMode(i);
        if (mode2 == Integer.MIN_VALUE) {
            desiredWidth = java.lang.Math.min(desiredWidth, android.view.View.MeasureSpec.getSize(i));
        } else if (mode2 == 1073741824) {
            desiredWidth = android.view.View.MeasureSpec.getSize(i);
        }
        setMeasuredDimension(desiredWidth, desiredHeight);
    }

    @Override // android.view.View
    public final void onRtlPropertiesChanged(int i) {
        super.onRtlPropertiesChanged(i);
        boolean z = i == 0;
        if (this.f683 != z) {
            this.f683 = z;
            this.f681 = m544();
            androidx.leanback.widget.C0139[] c0139Arr = this.f699;
            if (c0139Arr != null) {
                for (androidx.leanback.widget.C0139 c0139 : c0139Arr) {
                    c0139.f984 = c0139.f986.f683 ? 1.0f : -1.0f;
                }
            }
            m545();
            invalidate();
        }
    }

    @Override // android.view.View
    public final void onSizeChanged(int i, int i2, int i3, int i4) {
        setMeasuredDimension(i, i2);
        m545();
    }

    public void setArrowBackgroundColor(int i) {
        this.f692 = i;
    }

    public void setArrowColor(int i) {
        if (this.f693 == null) {
            this.f693 = new android.graphics.Paint();
        }
        this.f693.setColorFilter(new android.graphics.PorterDuffColorFilter(i, android.graphics.PorterDuff.Mode.SRC_IN));
    }

    public void setDotBackgroundColor(int i) {
        this.f691.setColor(i);
    }

    public void setPageCount(int i) {
        if (i <= 0) {
            throw new java.lang.IllegalArgumentException("The page count should be a positive integer");
        }
        this.f701 = i;
        this.f699 = new androidx.leanback.widget.C0139[i];
        for (int i2 = 0; i2 < this.f701; i2++) {
            this.f699[i2] = new androidx.leanback.widget.C0139(this);
        }
        m545();
        setSelectedPage(0);
    }

    /* renamed from: ʽ, reason: contains not printable characters */
    public final android.animation.ObjectAnimator m543() {
        android.animation.ObjectAnimator objectAnimatorOfFloat = android.animation.ObjectAnimator.ofFloat((java.lang.Object) null, f678, (-this.f695) + this.f686, 0.0f);
        objectAnimatorOfFloat.setDuration(417L);
        objectAnimatorOfFloat.setInterpolator(f680);
        return objectAnimatorOfFloat;
    }

    /* renamed from: ˈ, reason: contains not printable characters */
    public final android.graphics.Bitmap m544() {
        android.graphics.Bitmap bitmapDecodeResource = android.graphics.BitmapFactory.decodeResource(getResources(), ar.tvplayer.tv.R.drawable.uo);
        if (this.f683) {
            return bitmapDecodeResource;
        }
        android.graphics.Matrix matrix = new android.graphics.Matrix();
        matrix.preScale(-1.0f, 1.0f);
        return android.graphics.Bitmap.createBitmap(bitmapDecodeResource, 0, 0, bitmapDecodeResource.getWidth(), bitmapDecodeResource.getHeight(), matrix, false);
    }

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public final void m545() {
        int paddingLeft = getPaddingLeft();
        int paddingTop = getPaddingTop();
        int width = getWidth() - getPaddingRight();
        int requiredWidth = getRequiredWidth();
        int i = (paddingLeft + width) / 2;
        int i2 = this.f701;
        int[] iArr = new int[i2];
        this.f694 = iArr;
        int[] iArr2 = new int[i2];
        this.f698 = iArr2;
        int[] iArr3 = new int[i2];
        this.f700 = iArr3;
        boolean z = this.f683;
        int i3 = this.f682;
        int i4 = this.f695;
        int i5 = this.f686;
        int i6 = 1;
        if (z) {
            int i7 = i - (requiredWidth / 2);
            iArr[0] = ((i7 + i3) - i5) + i4;
            iArr2[0] = i7 + i3;
            iArr3[0] = (i4 * 2) + ((i7 + i3) - (i5 * 2));
            while (i6 < this.f701) {
                int[] iArr4 = this.f694;
                int[] iArr5 = this.f698;
                int i8 = i6 - 1;
                iArr4[i6] = iArr5[i8] + i4;
                iArr5[i6] = iArr5[i8] + i5;
                this.f700[i6] = iArr4[i8] + i4;
                i6++;
            }
        } else {
            int i9 = (requiredWidth / 2) + i;
            iArr[0] = ((i9 - i3) + i5) - i4;
            iArr2[0] = i9 - i3;
            iArr3[0] = ((i5 * 2) + (i9 - i3)) - (i4 * 2);
            while (i6 < this.f701) {
                int[] iArr6 = this.f694;
                int[] iArr7 = this.f698;
                int i10 = i6 - 1;
                iArr6[i6] = iArr7[i10] - i4;
                iArr7[i6] = iArr7[i10] - i5;
                this.f700[i6] = iArr6[i10] - i4;
                i6++;
            }
        }
        this.f684 = paddingTop + this.f689;
        m546();
    }

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final void m546() {
        int i;
        int i2 = 0;
        while (true) {
            i = this.f685;
            if (i2 >= i) {
                break;
            }
            this.f699[i2].m648();
            androidx.leanback.widget.C0139 c0139 = this.f699[i2];
            if (i2 != 0) {
                f = 1.0f;
            }
            c0139.f990 = f;
            c0139.f987 = this.f698[i2];
            i2++;
        }
        androidx.leanback.widget.C0139 c01392 = this.f699[i];
        c01392.f985 = 0.0f;
        c01392.f987 = 0.0f;
        androidx.leanback.widget.PagingIndicator pagingIndicator = c01392.f986;
        c01392.f988 = pagingIndicator.f697;
        float f = pagingIndicator.f689;
        c01392.f993 = f;
        c01392.f989 = f * pagingIndicator.f687;
        c01392.f992 = 1.0f;
        c01392.m649();
        androidx.leanback.widget.C0139[] c0139Arr = this.f699;
        int i3 = this.f685;
        androidx.leanback.widget.C0139 c01393 = c0139Arr[i3];
        c01393.f990 = i3 <= 0 ? 1.0f : -1.0f;
        c01393.f987 = this.f694[i3];
        while (true) {
            i3++;
            if (i3 >= this.f701) {
                return;
            }
            this.f699[i3].m648();
            androidx.leanback.widget.C0139 c01394 = this.f699[i3];
            c01394.f990 = 1.0f;
            c01394.f987 = this.f700[i3];
        }
    }
}
