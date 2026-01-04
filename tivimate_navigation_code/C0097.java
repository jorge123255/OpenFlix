package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ʿᵢ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C0097 extends android.util.Property {

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final /* synthetic */ int f883;

    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public /* synthetic */ C0097(java.lang.Class cls, java.lang.String str, int i) {
        super(cls, str);
        this.f883 = i;
    }

    @Override // android.util.Property
    public final java.lang.Object get(java.lang.Object obj) {
        switch (this.f883) {
            case 0:
                return java.lang.Float.valueOf(((androidx.leanback.widget.C0139) obj).f992);
            case 1:
                return java.lang.Float.valueOf(((androidx.leanback.widget.C0139) obj).f988);
            case 2:
                return java.lang.Float.valueOf(((androidx.leanback.widget.C0139) obj).f985);
            case 3:
                return java.lang.Integer.valueOf(((androidx.leanback.widget.AbstractC0093) obj).getStreamPosition());
            case 4:
                return java.lang.Float.valueOf(((androidx.appcompat.widget.SwitchCompat) obj).f168);
            case 5:
                return null;
            case p223.C3056.STRING_SET_FIELD_NUMBER /* 6 */:
                return null;
            case p223.C3056.DOUBLE_FIELD_NUMBER /* 7 */:
                return null;
            case p223.C3056.BYTES_FIELD_NUMBER /* 8 */:
                return null;
            case 9:
                return null;
            case 10:
                return null;
            case 11:
                return null;
            case 12:
                return null;
            case 13:
                return null;
            case 14:
                return null;
            case 15:
                return java.lang.Float.valueOf(p230.AbstractC3168.f12105.mo5067((android.view.View) obj));
            default:
                return ((android.view.View) obj).getClipBounds();
        }
    }

    @Override // android.util.Property
    public final void set(java.lang.Object obj, java.lang.Object obj2) {
        switch (this.f883) {
            case 0:
                androidx.leanback.widget.C0139 c0139 = (androidx.leanback.widget.C0139) obj;
                c0139.f992 = ((java.lang.Float) obj2).floatValue();
                c0139.m649();
                c0139.f986.invalidate();
                break;
            case 1:
                androidx.leanback.widget.C0139 c01392 = (androidx.leanback.widget.C0139) obj;
                float fFloatValue = ((java.lang.Float) obj2).floatValue();
                c01392.f988 = fFloatValue;
                float f = fFloatValue / 2.0f;
                c01392.f993 = f;
                androidx.leanback.widget.PagingIndicator pagingIndicator = c01392.f986;
                c01392.f989 = f * pagingIndicator.f687;
                pagingIndicator.invalidate();
                break;
            case 2:
                androidx.leanback.widget.C0139 c01393 = (androidx.leanback.widget.C0139) obj;
                c01393.f985 = ((java.lang.Float) obj2).floatValue() * c01393.f990 * c01393.f984;
                c01393.f986.invalidate();
                break;
            case 3:
                ((androidx.leanback.widget.AbstractC0093) obj).setStreamPosition(((java.lang.Integer) obj2).intValue());
                break;
            case 4:
                ((androidx.appcompat.widget.SwitchCompat) obj).setThumbPosition(((java.lang.Float) obj2).floatValue());
                break;
            case 5:
                p230.C3154 c3154 = (p230.C3154) obj;
                android.graphics.PointF pointF = (android.graphics.PointF) obj2;
                c3154.getClass();
                c3154.f12075 = java.lang.Math.round(pointF.x);
                int iRound = java.lang.Math.round(pointF.y);
                c3154.f12074 = iRound;
                int i = c3154.f12076 + 1;
                c3154.f12076 = i;
                if (i == c3154.f12073) {
                    p230.AbstractC3168.m6980(c3154.f12072, c3154.f12075, iRound, c3154.f12070, c3154.f12071);
                    c3154.f12076 = 0;
                    c3154.f12073 = 0;
                    break;
                }
                break;
            case p223.C3056.STRING_SET_FIELD_NUMBER /* 6 */:
                p230.C3154 c31542 = (p230.C3154) obj;
                android.graphics.PointF pointF2 = (android.graphics.PointF) obj2;
                c31542.getClass();
                c31542.f12070 = java.lang.Math.round(pointF2.x);
                int iRound2 = java.lang.Math.round(pointF2.y);
                c31542.f12071 = iRound2;
                int i2 = c31542.f12073 + 1;
                c31542.f12073 = i2;
                if (c31542.f12076 == i2) {
                    p230.AbstractC3168.m6980(c31542.f12072, c31542.f12075, c31542.f12074, c31542.f12070, iRound2);
                    c31542.f12076 = 0;
                    c31542.f12073 = 0;
                    break;
                }
                break;
            case p223.C3056.DOUBLE_FIELD_NUMBER /* 7 */:
                android.view.View view = (android.view.View) obj;
                android.graphics.PointF pointF3 = (android.graphics.PointF) obj2;
                p230.AbstractC3168.m6980(view, view.getLeft(), view.getTop(), java.lang.Math.round(pointF3.x), java.lang.Math.round(pointF3.y));
                break;
            case p223.C3056.BYTES_FIELD_NUMBER /* 8 */:
                android.view.View view2 = (android.view.View) obj;
                android.graphics.PointF pointF4 = (android.graphics.PointF) obj2;
                p230.AbstractC3168.m6980(view2, java.lang.Math.round(pointF4.x), java.lang.Math.round(pointF4.y), view2.getRight(), view2.getBottom());
                break;
            case 9:
                android.view.View view3 = (android.view.View) obj;
                android.graphics.PointF pointF5 = (android.graphics.PointF) obj2;
                int iRound3 = java.lang.Math.round(pointF5.x);
                int iRound4 = java.lang.Math.round(pointF5.y);
                p230.AbstractC3168.m6980(view3, iRound3, iRound4, view3.getWidth() + iRound3, view3.getHeight() + iRound4);
                break;
            case 10:
                p230.C3185 c3185 = (p230.C3185) obj;
                android.graphics.PointF pointF6 = (android.graphics.PointF) obj2;
                c3185.getClass();
                c3185.f12155 = java.lang.Math.round(pointF6.x);
                int iRound5 = java.lang.Math.round(pointF6.y);
                c3185.f12154 = iRound5;
                int i3 = c3185.f12156 + 1;
                c3185.f12156 = i3;
                if (i3 == c3185.f12153) {
                    p230.AbstractC3168.m6980(c3185.f12152, c3185.f12155, iRound5, c3185.f12150, c3185.f12151);
                    c3185.f12156 = 0;
                    c3185.f12153 = 0;
                    break;
                }
                break;
            case 11:
                p230.C3185 c31852 = (p230.C3185) obj;
                android.graphics.PointF pointF7 = (android.graphics.PointF) obj2;
                c31852.getClass();
                c31852.f12150 = java.lang.Math.round(pointF7.x);
                int iRound6 = java.lang.Math.round(pointF7.y);
                c31852.f12151 = iRound6;
                int i4 = c31852.f12153 + 1;
                c31852.f12153 = i4;
                if (c31852.f12156 == i4) {
                    p230.AbstractC3168.m6980(c31852.f12152, c31852.f12155, c31852.f12154, c31852.f12150, iRound6);
                    c31852.f12156 = 0;
                    c31852.f12153 = 0;
                    break;
                }
                break;
            case 12:
                android.view.View view4 = (android.view.View) obj;
                android.graphics.PointF pointF8 = (android.graphics.PointF) obj2;
                p230.AbstractC3168.m6980(view4, view4.getLeft(), view4.getTop(), java.lang.Math.round(pointF8.x), java.lang.Math.round(pointF8.y));
                break;
            case 13:
                android.view.View view5 = (android.view.View) obj;
                android.graphics.PointF pointF9 = (android.graphics.PointF) obj2;
                p230.AbstractC3168.m6980(view5, java.lang.Math.round(pointF9.x), java.lang.Math.round(pointF9.y), view5.getRight(), view5.getBottom());
                break;
            case 14:
                android.view.View view6 = (android.view.View) obj;
                android.graphics.PointF pointF10 = (android.graphics.PointF) obj2;
                int iRound7 = java.lang.Math.round(pointF10.x);
                int iRound8 = java.lang.Math.round(pointF10.y);
                p230.AbstractC3168.m6980(view6, iRound7, iRound8, view6.getWidth() + iRound7, view6.getHeight() + iRound8);
                break;
            case 15:
                float fFloatValue2 = ((java.lang.Float) obj2).floatValue();
                p230.AbstractC3168.f12105.mo5068((android.view.View) obj, fFloatValue2);
                break;
            default:
                ((android.view.View) obj).setClipBounds((android.graphics.Rect) obj2);
                break;
        }
    }
}
