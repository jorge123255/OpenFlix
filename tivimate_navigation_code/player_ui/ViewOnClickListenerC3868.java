package p312;

/* renamed from: ᐧⁱ.ᴵˊ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class ViewOnClickListenerC3868 implements p055.InterfaceC1487, android.view.View.OnClickListener, p312.InterfaceC3863, p312.InterfaceC3867 {

    /* renamed from: ʽʽ, reason: contains not printable characters */
    public final /* synthetic */ ar.tvplayer.tv.player.ui.CustomPlayerView f15051;

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public final p055.C1467 f15052 = new p055.C1467();

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public java.lang.Object f15053;

    public ViewOnClickListenerC3868(ar.tvplayer.tv.player.ui.CustomPlayerView customPlayerView) {
        this.f15051 = customPlayerView;
    }

    @Override // android.view.View.OnClickListener
    public final void onClick(android.view.View view) {
        this.f15051.m8040();
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ʻٴ */
    public final /* synthetic */ void mo2822(float f) {
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ʼʼ */
    public final /* synthetic */ void mo2823(int i) {
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ʼˈ */
    public final /* synthetic */ void mo2824(boolean z) {
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ʼᐧ */
    public final /* synthetic */ void mo2826(p055.C1463 c1463) {
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ʽʽ */
    public final void mo2828(int i) {
        ar.tvplayer.tv.player.ui.CustomPlayerView customPlayerView = this.f15051;
        customPlayerView.ᵔʾ();
        customPlayerView.m8025();
        if (!customPlayerView.m8041() || !customPlayerView.f14934) {
            customPlayerView.m8034(false);
            return;
        }
        p312.C3860 c3860 = customPlayerView.f14949;
        if (c3860 != null) {
            c3860.m8059();
        }
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ʽﹳ */
    public final void mo2829(int i, boolean z) {
        ar.tvplayer.tv.player.ui.CustomPlayerView customPlayerView = this.f15051;
        customPlayerView.ᵔʾ();
        if (!customPlayerView.m8041() || !customPlayerView.f14934) {
            customPlayerView.m8034(false);
            return;
        }
        p312.C3860 c3860 = customPlayerView.f14949;
        if (c3860 != null) {
            c3860.m8059();
        }
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ʾᵎ */
    public final /* synthetic */ void mo2831(p055.C1475 c1475) {
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ˆʾ */
    public final /* synthetic */ void mo2832(int i) {
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ˆﾞ */
    public final void mo2833(int i, p055.C1456 c1456, p055.C1456 c14562) {
        p312.C3860 c3860;
        ar.tvplayer.tv.player.ui.CustomPlayerView customPlayerView = this.f15051;
        if (customPlayerView.m8041() && customPlayerView.f14934 && (c3860 = customPlayerView.f14949) != null) {
            c3860.m8059();
        }
        if (i == 1 || i == 4) {
            customPlayerView.ᵔʾ();
        }
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ˈ */
    public final /* synthetic */ void mo2834(int i) {
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ˈʿ */
    public final /* synthetic */ void mo2835(p055.C1482 c1482) {
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ˉʿ */
    public final /* synthetic */ void mo2837(boolean z) {
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ˉˆ */
    public final /* synthetic */ void mo2838(boolean z) {
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ˉٴ */
    public final /* synthetic */ void mo2839(androidx.media3.common.PlaybackException playbackException) {
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ˏי */
    public final /* synthetic */ void mo2843(int i, boolean z) {
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ˑٴ */
    public final void mo2844(p388.C4620 c4620) {
        androidx.media3.ui.SubtitleView subtitleView = this.f15051.f14948;
        if (subtitleView != null) {
            subtitleView.setCues(c4620.f17229);
        }
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ˑﹳ */
    public final /* synthetic */ void mo2845(p055.C1485 c1485) {
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ٴᵢ */
    public final /* synthetic */ void mo2850(p055.C1483 c1483) {
    }

    /* JADX WARN: Removed duplicated region for block: B:18:0x0065  */
    @Override // p055.InterfaceC1487
    /* renamed from: ٴﹶ */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct add '--show-bad-code' argument
    */
    public final void mo2851(p055.C1454 r8) {
        /*
            r7 = this;
            ar.tvplayer.tv.player.ui.CustomPlayerView r8 = r7.f15051
            ʽⁱ.ᵔٴ r0 = r8.f14918
            r0.getClass()
            r1 = r0
            ʽⁱ.ᵎﹶ r1 = (ʽⁱ.ᵎﹶ) r1
            r2 = 17
            boolean r2 = r1.ᐧﹶ(r2)
            if (r2 == 0) goto L1a
            r2 = r0
            ⁱי.ʼʼ r2 = (p392.C4644) r2
            ʽⁱ.ʼˈ r2 = r2.m9254()
            goto L1c
        L1a:
            ʽⁱ.ˑٴ r2 = p055.AbstractC1445.f5630
        L1c:
            boolean r3 = r2.m4217()
            r4 = 0
            r5 = 0
            if (r3 == 0) goto L27
            r7.f15053 = r5
            goto L81
        L27:
            r3 = 30
            boolean r1 = r1.ᐧﹶ(r3)
            ʽⁱ.ˋᵔ r3 = r7.f15052
            if (r1 == 0) goto L65
            r1 = r0
            ⁱי.ʼʼ r1 = (p392.C4644) r1
            ʽⁱ.ʿᵢ r6 = r1.m9236()
            ʼʻ.ᵎⁱ r6 = r6.f5658
            boolean r6 = r6.isEmpty()
            if (r6 != 0) goto L65
            r1.m9241()
            ⁱי.ᴵˑ r0 = r1.f17415
            ʽⁱ.ʼˈ r0 = r0.f17591
            boolean r0 = r0.m4217()
            if (r0 == 0) goto L4f
            r0 = r4
            goto L5b
        L4f:
            ⁱי.ᴵˑ r0 = r1.f17415
            ʽⁱ.ʼˈ r1 = r0.f17591
            ﹳᵢ.ᵢˏ r0 = r0.f17590
            java.lang.Object r0 = r0.f18631
            int r0 = r1.mo4228(r0)
        L5b:
            r1 = 1
            ʽⁱ.ˋᵔ r0 = r2.mo4231(r0, r3, r1)
            java.lang.Object r0 = r0.f5748
            r7.f15053 = r0
            goto L81
        L65:
            java.lang.Object r1 = r7.f15053
            if (r1 == 0) goto L81
            int r1 = r2.mo4228(r1)
            r6 = -1
            if (r1 == r6) goto L7f
            ʽⁱ.ˋᵔ r1 = r2.mo4231(r1, r3, r4)
            int r1 = r1.f5744
            ⁱי.ʼʼ r0 = (p392.C4644) r0
            int r0 = r0.m9238()
            if (r0 != r1) goto L7f
            return
        L7f:
            r7.f15053 = r5
        L81:
            r8.m8037(r4)
            return
        */
        throw new UnsupportedOperationException("Method not decompiled: p312.ViewOnClickListenerC3868.mo2851(ʽⁱ.ʿᵢ):void");
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ᵎˊ */
    public final void mo2854(int i, int i2) {
        ar.tvplayer.tv.player.ui.CustomPlayerView customPlayerView = this.f15051;
        android.view.View view = customPlayerView.f14926;
        if (android.os.Build.VERSION.SDK_INT == 34 && (view instanceof android.view.SurfaceView) && customPlayerView.f14917) {
            p312.C3869 c3869 = customPlayerView.f14930;
            c3869.getClass();
            customPlayerView.f14924.post(new com.parse.ˊﾞ(c3869, (android.view.SurfaceView) view, new p312.RunnableC3847(customPlayerView, 1), 9));
        }
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ᵎⁱ */
    public final /* synthetic */ void mo2855(boolean z) {
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ᵎﹶ */
    public final /* synthetic */ void mo2856(p055.C1480 c1480, int i) {
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ᵔʾ */
    public final void mo2857() {
        ar.tvplayer.tv.player.ui.CustomPlayerView customPlayerView = this.f15051;
        customPlayerView.f14925 = true;
        android.view.View view = customPlayerView.f14919;
        if (view != null && view.getVisibility() == 0) {
            view.animate().alpha(0.0f).withLayer().setDuration(150L).withEndAction(new p312.RunnableC3847(customPlayerView, 0));
        }
        customPlayerView.f14937 = false;
        if (!customPlayerView.m8026()) {
            customPlayerView.m8031();
            return;
        }
        android.widget.ImageView imageView = customPlayerView.f14939;
        if (imageView != null) {
            imageView.setVisibility(4);
        }
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ᵔᵢ */
    public final /* synthetic */ void mo2860(p055.C1476 c1476) {
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ᵔﹳ */
    public final /* synthetic */ void mo2861(p055.C1471 c1471) {
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ᵢˏ */
    public final /* synthetic */ void mo2862(androidx.media3.common.PlaybackException playbackException) {
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ⁱˊ */
    public final /* synthetic */ void mo2863(int i) {
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ﹳٴ */
    public final void mo2865(p055.C1469 c1469) {
        ar.tvplayer.tv.player.ui.CustomPlayerView customPlayerView;
        p055.InterfaceC1488 interfaceC1488;
        if (c1469.equals(p055.C1469.f5752) || (interfaceC1488 = (customPlayerView = this.f15051).f14918) == null || ((p392.C4644) interfaceC1488).m9259() == 1) {
            return;
        }
        customPlayerView.m8029();
    }

    @Override // p055.InterfaceC1487
    /* renamed from: ﹳᐧ */
    public final /* synthetic */ void mo2866(java.util.List list) {
    }
}
