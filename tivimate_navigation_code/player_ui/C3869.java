package p312;

/* renamed from: ᐧⁱ.ᴵᵔ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class C3869 {

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public android.window.SurfaceSyncGroup f15054;

    /* renamed from: ﹳٴ, reason: contains not printable characters */
    public static /* synthetic */ void m8067(p312.C3869 c3869, android.view.SurfaceView surfaceView, p312.RunnableC3847 runnableC3847) {
        c3869.getClass();
        android.view.AttachedSurfaceControl rootSurfaceControl = surfaceView.getRootSurfaceControl();
        if (rootSurfaceControl == null) {
            return;
        }
        android.window.SurfaceSyncGroup surfaceSyncGroup = new android.window.SurfaceSyncGroup("exo-sync-b-334901521");
        c3869.f15054 = surfaceSyncGroup;
        p305.AbstractC3731.m7857(surfaceSyncGroup.add(rootSurfaceControl, (java.lang.Runnable) new ʿˋ.ˉٴ(2)));
        runnableC3847.run();
        rootSurfaceControl.applyTransactionOnDraw(new android.view.SurfaceControl.Transaction());
    }

    /* renamed from: ⁱˊ, reason: contains not printable characters */
    public final void m8068() {
        android.window.SurfaceSyncGroup surfaceSyncGroup = this.f15054;
        if (surfaceSyncGroup != null) {
            surfaceSyncGroup.markSyncReady();
            this.f15054 = null;
        }
    }
}
