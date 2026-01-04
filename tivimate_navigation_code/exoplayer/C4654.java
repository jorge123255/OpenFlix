package p392;

/* renamed from: ⁱי.ʿᵢ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C4654 {

    /* renamed from: ʽ, reason: contains not printable characters */
    public int f17442;

    /* renamed from: ˈ, reason: contains not printable characters */
    public java.lang.Object f17443;

    /* renamed from: ˑﹳ, reason: contains not printable characters */
    public final android.os.Looper f17444;

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public final p392.InterfaceC4663 f17445;

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final p392.InterfaceC4653 f17446;

    /* renamed from: ﾞᴵ, reason: contains not printable characters */
    public boolean f17447;

    public C4654(p392.InterfaceC4663 interfaceC4663, p392.InterfaceC4653 interfaceC4653, p055.AbstractC1445 abstractC1445, int i, android.os.Looper looper) {
        this.f17445 = interfaceC4663;
        this.f17446 = interfaceC4653;
        this.f17444 = looper;
    }

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public final void m9263() {
        p305.AbstractC3731.m7857(!this.f17447);
        this.f17447 = true;
        p392.C4683 c4683 = (p392.C4683) this.f17445;
        if (!c4683.f17630 && c4683.f17631.getThread().isAlive()) {
            c4683.f17615.m7753(14, this).m7816();
        } else {
            p305.AbstractC3731.m7850("ExoPlayerImplInternal", "Ignoring messages sent after release.");
            m9264(false);
        }
    }

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public final synchronized void m9264(boolean z) {
        notifyAll();
    }
}
