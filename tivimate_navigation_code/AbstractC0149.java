package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ﹳـ, reason: contains not printable characters */
/* loaded from: classes.dex */
public abstract class AbstractC0149 {

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public static final android.graphics.Rect f1015 = new android.graphics.Rect();

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public static int m667(android.view.View view, androidx.leanback.widget.C0123 c0123, int i) {
        android.view.View viewFindViewById;
        int height;
        int width;
        int width2;
        int width3;
        androidx.leanback.widget.C0151 c0151 = (androidx.leanback.widget.C0151) view.getLayoutParams();
        int i2 = c0123.f969;
        if (i2 == 0 || (viewFindViewById = view.findViewById(i2)) == null) {
            viewFindViewById = view;
        }
        int paddingBottom = c0123.f968;
        android.graphics.Rect rect = f1015;
        if (i != 0) {
            if (c0123.f966) {
                float f = c0123.f965;
                if (f == 0.0f) {
                    paddingBottom += viewFindViewById.getPaddingTop();
                } else if (f == 100.0f) {
                    paddingBottom -= viewFindViewById.getPaddingBottom();
                }
            }
            if (c0123.f965 != -1.0f) {
                if (viewFindViewById == view) {
                    c0151.getClass();
                    height = (viewFindViewById.getHeight() - c0151.f1024) - c0151.f1022;
                } else {
                    height = viewFindViewById.getHeight();
                }
                paddingBottom += (int) ((height * c0123.f965) / 100.0f);
            }
            if (view != viewFindViewById) {
                rect.top = paddingBottom;
                ((android.view.ViewGroup) view).offsetDescendantRectToMyCoords(viewFindViewById, rect);
                paddingBottom = rect.top - c0151.f1024;
            }
            return c0123.f967 ? viewFindViewById.getBaseline() + paddingBottom : paddingBottom;
        }
        if (view.getLayoutDirection() != 1) {
            if (c0123.f966) {
                float f2 = c0123.f965;
                if (f2 == 0.0f) {
                    paddingBottom += viewFindViewById.getPaddingLeft();
                } else if (f2 == 100.0f) {
                    paddingBottom -= viewFindViewById.getPaddingRight();
                }
            }
            if (c0123.f965 != -1.0f) {
                if (viewFindViewById == view) {
                    c0151.getClass();
                    width = (viewFindViewById.getWidth() - c0151.f1019) - c0151.f1021;
                } else {
                    width = viewFindViewById.getWidth();
                }
                paddingBottom += (int) ((width * c0123.f965) / 100.0f);
            }
            if (view == viewFindViewById) {
                return paddingBottom;
            }
            rect.left = paddingBottom;
            ((android.view.ViewGroup) view).offsetDescendantRectToMyCoords(viewFindViewById, rect);
            return rect.left - c0151.f1019;
        }
        if (viewFindViewById == view) {
            c0151.getClass();
            width2 = (viewFindViewById.getWidth() - c0151.f1019) - c0151.f1021;
        } else {
            width2 = viewFindViewById.getWidth();
        }
        int paddingLeft = width2 - paddingBottom;
        if (c0123.f966) {
            float f3 = c0123.f965;
            if (f3 == 0.0f) {
                paddingLeft -= viewFindViewById.getPaddingRight();
            } else if (f3 == 100.0f) {
                paddingLeft += viewFindViewById.getPaddingLeft();
            }
        }
        if (c0123.f965 != -1.0f) {
            if (viewFindViewById == view) {
                c0151.getClass();
                width3 = (viewFindViewById.getWidth() - c0151.f1019) - c0151.f1021;
            } else {
                width3 = viewFindViewById.getWidth();
            }
            paddingLeft -= (int) ((width3 * c0123.f965) / 100.0f);
        }
        if (view == viewFindViewById) {
            return paddingLeft;
        }
        rect.right = paddingLeft;
        ((android.view.ViewGroup) view).offsetDescendantRectToMyCoords(viewFindViewById, rect);
        return rect.right + c0151.f1021;
    }
}
