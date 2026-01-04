package androidx.leanback.widget;

/* renamed from: androidx.leanback.widget.ʼʼ, reason: contains not printable characters */
/* loaded from: classes.dex */
public final class ViewOnClickListenerC0083 implements android.view.View.OnClickListener {

    /* renamed from: ʾˋ, reason: contains not printable characters */
    public final /* synthetic */ int f840;

    /* renamed from: ᴵˊ, reason: contains not printable characters */
    public final /* synthetic */ java.lang.Object f841;

    public /* synthetic */ ViewOnClickListenerC0083(int i, java.lang.Object obj) {
        this.f840 = i;
        this.f841 = obj;
    }

    @Override // android.view.View.OnClickListener
    public final void onClick(android.view.View view) {
        android.os.Message message;
        android.os.Message message2;
        android.os.Message message3;
        switch (this.f840) {
            case 0:
                androidx.leanback.widget.C0108 c0108 = (androidx.leanback.widget.C0108) this.f841;
                androidx.leanback.widget.InterfaceC0136 interfaceC0136 = c0108.f914;
                androidx.leanback.widget.VerticalGridView verticalGridView = c0108.f910;
                if (view != null && view.getWindowToken() != null && verticalGridView.f1499) {
                    androidx.leanback.widget.C0101 c0101 = (androidx.leanback.widget.C0101) verticalGridView.m946(view);
                    androidx.leanback.widget.C0095 c0095 = c0101.f896;
                    android.view.KeyEvent.Callback callback = c0101.f895;
                    int i = c0095.f878;
                    if (i != 1 && i != 2) {
                        if (c0095.m585()) {
                            if (interfaceC0136 != null) {
                                interfaceC0136.mo441(c0101.f896);
                                break;
                            }
                        } else {
                            java.util.ArrayList arrayList = c0108.f909;
                            androidx.leanback.widget.C0117 c0117 = c0108.f918;
                            androidx.leanback.widget.C0095 c00952 = c0101.f896;
                            int i2 = c00952.f874;
                            if (verticalGridView.f1499 && i2 != 0) {
                                if (i2 != -1) {
                                    int size = arrayList.size();
                                    for (int i3 = 0; i3 < size; i3++) {
                                        androidx.leanback.widget.C0095 c00953 = (androidx.leanback.widget.C0095) arrayList.get(i3);
                                        if (c00953 != c00952 && c00953.f874 == i2 && c00953.m584()) {
                                            c00953.m583(0, 1);
                                            androidx.leanback.widget.C0101 c01012 = (androidx.leanback.widget.C0101) verticalGridView.m979(i3, false);
                                            if (c01012 != null) {
                                                c0117.getClass();
                                                android.view.KeyEvent.Callback callback2 = c01012.f895;
                                                if (callback2 instanceof android.widget.Checkable) {
                                                    ((android.widget.Checkable) callback2).setChecked(false);
                                                }
                                            }
                                        }
                                    }
                                }
                                if (!c00952.m584()) {
                                    c00952.m583(1, 1);
                                    c0117.getClass();
                                    if (callback instanceof android.widget.Checkable) {
                                        ((android.widget.Checkable) callback).setChecked(true);
                                    }
                                } else if (i2 == -1) {
                                    c00952.m583(0, 1);
                                    c0117.getClass();
                                    if (callback instanceof android.widget.Checkable) {
                                        ((android.widget.Checkable) callback).setChecked(false);
                                    }
                                }
                            }
                            if (c0095.m580() && (c0095.f875 & 8) != 8 && interfaceC0136 != null) {
                                interfaceC0136.mo441(c0101.f896);
                                break;
                            }
                        }
                    } else {
                        c0108.f911.m1596(c0108, c0101);
                        break;
                    }
                }
                break;
            case 1:
                androidx.leanback.widget.SearchBar searchBar = (androidx.leanback.widget.SearchBar) this.f841;
                if (searchBar.f735) {
                    searchBar.m552();
                    break;
                } else {
                    searchBar.m548();
                    break;
                }
            case 2:
                com.google.android.material.datepicker.C0678 c0678 = (com.google.android.material.datepicker.C0678) this.f841;
                int i4 = c0678.f2770;
                if (i4 == 2) {
                    c0678.m2414(1);
                } else if (i4 == 1) {
                    c0678.m2414(2);
                }
                c0678.m2416(c0678.f11908);
                break;
            case 3:
                ((androidx.preference.Preference) this.f841).mo811(view);
                break;
            case 4:
                ((p136.AbstractC2228) this.f841).mo5223();
                break;
            case 5:
                p137.C2304 c2304 = ((androidx.appcompat.widget.Toolbar) this.f841).f204;
                p353.C4329 c4329 = c2304 == null ? null : c2304.f8996;
                if (c4329 != null) {
                    c4329.collapseActionView();
                    break;
                }
                break;
            case p223.C3056.STRING_SET_FIELD_NUMBER /* 6 */:
                androidx.media3.ui.TrackSelectionView trackSelectionView = (androidx.media3.ui.TrackSelectionView) this.f841;
                java.util.HashMap map = trackSelectionView.f1321;
                boolean z = true;
                if (view == trackSelectionView.f1315) {
                    trackSelectionView.f1326 = true;
                    map.clear();
                } else if (view == trackSelectionView.f1317) {
                    trackSelectionView.f1326 = false;
                    map.clear();
                } else {
                    trackSelectionView.f1326 = false;
                    java.lang.Object tag = view.getTag();
                    tag.getClass();
                    p312.C3861 c3861 = (p312.C3861) tag;
                    p055.C1453 c1453 = c3861.f15036;
                    p055.C1474 c1474 = c1453.f5655;
                    int i5 = c3861.f15035;
                    p055.C1493 c1493 = (p055.C1493) map.get(c1474);
                    if (c1493 == null) {
                        if (!trackSelectionView.f1325 && !map.isEmpty()) {
                            map.clear();
                        }
                        map.put(c1474, new p055.C1493(c1474, p017.AbstractC0993.m3260(java.lang.Integer.valueOf(i5))));
                    } else {
                        java.util.ArrayList arrayList2 = new java.util.ArrayList(c1493.f5896);
                        boolean zIsChecked = ((android.widget.CheckedTextView) view).isChecked();
                        boolean z2 = trackSelectionView.f1318 && c1453.f5652;
                        if (!z2 && (!trackSelectionView.f1325 || trackSelectionView.f1319.size() <= 1)) {
                            z = false;
                        }
                        if (zIsChecked && z) {
                            arrayList2.remove(java.lang.Integer.valueOf(i5));
                            if (arrayList2.isEmpty()) {
                                map.remove(c1474);
                            } else {
                                map.put(c1474, new p055.C1493(c1474, arrayList2));
                            }
                        } else if (!zIsChecked) {
                            if (z2) {
                                arrayList2.add(java.lang.Integer.valueOf(i5));
                                map.put(c1474, new p055.C1493(c1474, arrayList2));
                            } else {
                                map.put(c1474, new p055.C1493(c1474, p017.AbstractC0993.m3260(java.lang.Integer.valueOf(i5))));
                            }
                        }
                    }
                }
                trackSelectionView.m810();
                break;
            default:
                p363.C4435 c4435 = (p363.C4435) this.f841;
                android.os.Message messageObtain = (view != c4435.f16546 || (message3 = c4435.f16564) == null) ? (view != c4435.f16575 || (message2 = c4435.f16568) == null) ? (view != c4435.f16557 || (message = c4435.f16570) == null) ? null : android.os.Message.obtain(message) : android.os.Message.obtain(message2) : android.os.Message.obtain(message3);
                if (messageObtain != null) {
                    messageObtain.sendToTarget();
                }
                c4435.f16558.obtainMessage(1, c4435.f16572).sendToTarget();
                break;
        }
    }
}
