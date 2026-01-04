package androidx.leanback.transition;

/* renamed from: androidx.leanback.transition.ˈ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C0074 extends com.google.android.gms.internal.play_billing.י {

    /* renamed from: ᵔٴ, reason: contains not printable characters */
    public final /* synthetic */ int f572;

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final float m447(android.view.View view) {
        switch (this.f572) {
            case 0:
                return view.getTranslationX() - view.getWidth();
            case 1:
                return view.getTranslationX() + view.getWidth();
            case 2:
                return view.getLayoutDirection() == 1 ? view.getTranslationX() + view.getWidth() : view.getTranslationX() - view.getWidth();
            default:
                return view.getLayoutDirection() == 1 ? view.getTranslationX() - view.getWidth() : view.getTranslationX() + view.getWidth();
        }
    }
}
