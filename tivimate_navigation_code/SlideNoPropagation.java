package androidx.leanback.transition;

/* loaded from: classes.dex */
public class SlideNoPropagation extends android.transition.Slide {
    public SlideNoPropagation(android.content.Context context, android.util.AttributeSet attributeSet) {
        super(context, attributeSet);
    }

    @Override // android.transition.Slide
    public final void setSlideEdge(int i) {
        super.setSlideEdge(i);
        setPropagation(null);
    }
}
