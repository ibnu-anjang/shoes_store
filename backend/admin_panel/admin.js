        const API = window.location.origin;
        function fixImageUrl(url) {
            if (!url) return '';
            if (url.startsWith('http')) return url;
            const path = url.startsWith('/') ? url : '/' + url;
            return (API + path).replace(/([^:])\/\//g, '$1/');
        }

        // ── State ────────────────────────────────────────────────────
        let allOrders = [];
        let allProducts = [];
        let allUsers = [];
        let activeOrderFilter = 'ALL';
        let currentPhotoProductId = null;
        let currentEditProductId = null;
        let editingProductData = null;
        let excludedMatrixRows = new Set(); // Tracks manually removed color-size combinations in creation matrix

        // Category list (persisted in localStorage)
        const DEFAULT_CATEGORIES = ['Sneakers', 'Running', 'Casual', 'Formal', 'Sport', 'Sandals', 'Kids', 'Boots'];
        function getCategories() {
            try {
                const stored = JSON.parse(localStorage.getItem('shoes_categories') || 'null');
                return stored || [...DEFAULT_CATEGORIES];
            } catch { return [...DEFAULT_CATEGORIES]; }
        }
        function saveCategories(cats) {
            localStorage.setItem('shoes_categories', JSON.stringify(cats));
        }

        // ── Admin Auth ───────────────────────────────────────────────
        let ADMIN_KEY = localStorage.getItem('shoes_admin_key') || '';
        function getHeaders(extra = {}) {
            return { 'X-Admin-Key': ADMIN_KEY, 'Content-Type': 'application/json', ...extra };
        }
        function getAdminHeaders(extra = {}) {
            return { 'X-Admin-Key': ADMIN_KEY, ...extra };
        }
        function promptAdminKey() {
            const key = prompt('🔐 Masukkan Admin Key:');
            if (key !== null) {
                ADMIN_KEY = key.trim();
                localStorage.setItem('shoes_admin_key', ADMIN_KEY);
                toast('Admin key diperbarui');
            }
        }
        if (!ADMIN_KEY) promptAdminKey();

        // ── Toast ────────────────────────────────────────────────────
        function toast(msg, type = 'success') {
            const el = document.getElementById('toast');
            const inner = document.getElementById('toast-inner');
            const colors = { success: 'bg-green-600', error: 'bg-red-600', warn: 'bg-yellow-600', info: 'bg-blue-600' };
            const icons = { success: '✓', error: '✕', warn: '⚠', info: 'ℹ' };
            inner.className = `px-5 py-3 rounded-xl shadow-2xl text-sm font-semibold text-white flex items-center gap-2 min-w-[220px] ${colors[type] || colors.success}`;
            inner.textContent = (icons[type] || '✓') + ' ' + msg;
            el.classList.remove('opacity-0', 'translate-y-[-12px]', 'pointer-events-none');
            clearTimeout(el._tid);
            el._tid = setTimeout(() => el.classList.add('opacity-0', 'translate-y-[-12px]', 'pointer-events-none'), 3000);
        }

        // ── Confirm Modal ────────────────────────────────────────────
        let _confirmCb = null;
        function confirm2(title, msg, cb) {
            document.getElementById('confirm-title').textContent = title;
            document.getElementById('confirm-msg').textContent = msg;
            _confirmCb = cb;
            const m = document.getElementById('confirm-modal');
            m.classList.remove('hidden'); m.classList.add('flex');
        }
        function closeConfirm() {
            const m = document.getElementById('confirm-modal');
            m.classList.add('hidden'); m.classList.remove('flex');
            _confirmCb = null;
        }
        document.getElementById('confirm-ok').onclick = () => { if (_confirmCb) _confirmCb(); closeConfirm(); };

        // ── Tab Switching ────────────────────────────────────────────
        const TABS = ['dashboard', 'orders', 'products', 'users', 'financial', 'settings'];
        function switchTab(tab) {
            TABS.forEach(t => {
                const el = document.getElementById(`tab-${t}`);
                if (el) el.classList.toggle('hidden', t !== tab);
                const nav = document.getElementById(`nav-${t}`);
                if (nav) nav.className = 'nav-btn ' + (t === tab ? 'nav-active' : 'nav-inactive');
            });
            if (tab === 'dashboard') { fetchOrders(); fetchProducts(); }
            else if (tab === 'orders') fetchOrders();
            else if (tab === 'products') fetchProducts();
            else if (tab === 'users') fetchUsers();
            else if (tab === 'financial') renderFinancial();
            else if (tab === 'settings') { fetchPaymentConfig(); fetchAdminPromos(); }
        }

        function renderFinancial() {
            const successStatus = ['PAID', 'SHIPPED', 'COMPLETED', 'DELIVERED'];
            const list = allOrders.filter(o => successStatus.includes(o.status))
                .sort((a, b) => new Date(b.tanggal) - new Date(a.tanggal));

            let netProfit = 0;
            const body = document.getElementById('financial-table-body');
            body.innerHTML = list.length ? list.map(o => {
                const sub = o.subtotal || (o.total - (o.unique_code || 0));
                netProfit += sub;
                return `
            <tr class="border-b border-gray-800 hover:bg-gray-800/30 transition">
                <td class="px-5 py-3 text-xs text-gray-500">${fmtDate(o.tanggal)}</td>
                <td class="px-5 py-3 font-mono text-xs text-orange-400 font-bold">#${o.id}</td>
                <td class="px-5 py-3 text-right text-sm text-gray-300">${fmtRp(sub)}</td>
                <td class="px-5 py-3 text-right text-xs text-gray-500">+${o.unique_code || 0}</td>
                <td class="px-5 py-3 text-right text-sm font-bold text-orange-300">${fmtRp(o.total)}</td>
            </tr>`;
            }).join('') : '<tr><td colspan="5" class="py-10 text-center text-gray-600 italic">Belum ada pendapatan yang valid.</td></tr>';

            document.getElementById('financial-net-profit').textContent = fmtRp(netProfit);
        }

        async function refreshAll() {
            await Promise.all([fetchOrders(), fetchProducts()]);
            toast('Data diperbarui', 'success');
        }

        // ── Status Badge ─────────────────────────────────────────────
        function statusBadge(status) {
            const map = {
                UNPAID: 'bg-yellow-900/60 text-yellow-300', // Pending
                VERIFYING: 'bg-orange-900/60 text-orange-300', // Waiting Validation
                PAID: 'bg-blue-900/60 text-blue-300',   // Processing
                SHIPPED: 'bg-purple-900/60 text-purple-300', // Shipped
                COMPLETED: 'bg-green-900/60 text-green-300',  // Completed
                DELIVERED: 'bg-green-900/60 text-green-300',
                CANCELLED: 'bg-red-900/60 text-red-300',
                REJECTED: 'bg-red-900/60 text-red-300',
            };
            return `<span class="status-badge ${map[status] || 'bg-gray-800 text-gray-400'}">${status}</span>`;
        }

        function fmtRp(n) {
            return 'Rp ' + Number(n).toLocaleString('id-ID');
        }
        function parsePrice(val) {
            if (!val) return 0;
            return parseFloat(val.toString().replace(/\./g, '')) || 0;
        }
        function fmtDate(d) {
            return new Date(d).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
        }

        // Helper: Convert 0xFFRRGGBB to #RRGGBB for CSS
        function formatHex(hex) {
            if (!hex) return '';
            if (hex.startsWith('0xFF')) return '#' + hex.substring(4);
            return hex;
        }

        // ═══════════════════════════════════════════════════════════
        // DASHBOARD
        // ═══════════════════════════════════════════════════════════
        function renderDashboard() {
            // Revenue: Sum of subtotal (ignore unique codes) for successful orders
            const successStatus = ['PAID', 'SHIPPED', 'COMPLETED', 'DELIVERED'];
            const successOrders = allOrders.filter(o => successStatus.includes(o.status));
            const revenue = successOrders.reduce((s, o) => s + (o.subtotal || (o.total - (o.unique_code || 0))), 0);

            document.getElementById('dash-revenue').textContent = fmtRp(revenue);
            document.getElementById('dash-total-orders').textContent = allOrders.length;

            // Pending Validations: VERIFYING + (TF/QRIS)
            const pendingValidations = allOrders.filter(o => o.status === 'VERIFYING' && ['TF', 'QRIS'].includes(o.payment_method)).length;
            document.getElementById('dash-verifying').textContent = pendingValidations;
            document.getElementById('dash-products').textContent = allProducts.length;

            // Badge on sidebar
            const badge = document.getElementById('badge-verifying');
            if (pendingValidations > 0) { badge.textContent = pendingValidations; badge.classList.remove('hidden'); }
            else badge.classList.add('hidden');

            // Status breakdown
            const statusOrder = ['UNPAID', 'VERIFYING', 'PAID', 'SHIPPED', 'COMPLETED', 'CANCELLED'];
            const statusColors = {
                UNPAID: 'bg-yellow-500', VERIFYING: 'bg-orange-500', PAID: 'bg-blue-500',
                SHIPPED: 'bg-purple-500', COMPLETED: 'bg-green-500', CANCELLED: 'bg-red-500'
            };
            const counts = {};
            statusOrder.forEach(s => counts[s] = allOrders.filter(o => o.status === s).length);
            const maxCount = Math.max(...Object.values(counts), 1);
            document.getElementById('dash-status-breakdown').innerHTML = statusOrder.map(s => `
        <div class="flex items-center gap-2">
            <span class="text-xs text-gray-400 w-20 font-medium">${s}</span>
            <div class="flex-1 h-2 bg-gray-800 rounded-full overflow-hidden">
                <div class="${statusColors[s] || 'bg-gray-500'} h-full rounded-full transition-all" style="width:${(counts[s] / maxCount * 100).toFixed(0)}%"></div>
            </div>
            <span class="text-xs font-bold text-gray-300 w-6 text-right">${counts[s]}</span>
        </div>
    `).join('');

            const recent = [...allOrders].sort((a, b) => new Date(b.tanggal) - new Date(a.tanggal)).slice(0, 10);
            document.getElementById('dash-recent-orders').innerHTML = recent.length ? recent.map(o => `
        <tr class="border-b border-gray-800 hover:bg-gray-800/30 transition">
            <td class="py-2 pr-3 font-mono text-xs text-orange-400 font-bold">#${o.id}</td>
            <td class="py-2 pr-3 text-xs text-gray-400">ID: ${o.user_id}</td>
            <td class="py-2 pr-3 text-xs font-semibold text-orange-300">${fmtRp(o.total)}</td>
            <td class="py-2 pr-3">${statusBadge(o.status)}</td>
            <td class="py-2 text-xs text-gray-500">${fmtDate(o.tanggal)}</td>
        </tr>
    `).join('') : '<tr><td colspan="5" class="py-6 text-center text-gray-600 text-xs">Belum ada pesanan</td></tr>';

            // Low stock SKUs
            const lowStock = [];
            allProducts.forEach(p => {
                p.skus.forEach(sku => {
                    if (sku.stock_available <= 5) {
                        lowStock.push({ product: p.name, variant: sku.variant_name, stock: sku.stock_available });
                    }
                });
            });
            lowStock.sort((a, b) => a.stock - b.stock);
            document.getElementById('dash-low-stock').innerHTML = lowStock.length
                ? lowStock.slice(0, 8).map(item => `
            <div class="flex items-center justify-between py-1.5 border-b border-gray-800 last:border-0">
                <span class="text-xs text-gray-300">${item.product} — <span class="text-gray-500">${item.variant}</span></span>
                <span class="text-xs font-bold ${item.stock === 0 ? 'text-red-400' : 'text-yellow-400'}">${item.stock === 0 ? 'HABIS' : item.stock + ' pcs'}</span>
            </div>`).join('')
                : '<p class="text-xs text-gray-600">Semua stok aman ✓</p>';
        }

        // ═══════════════════════════════════════════════════════════
        // ORDERS
        // ═══════════════════════════════════════════════════════════
        async function fetchOrders() {
            try {
                const res = await fetch(`${API}/admin/orders`, { headers: getAdminHeaders() });
                if (!res.ok) throw new Error('Gagal fetch orders');
                allOrders = await res.json();
                updateOrderStats();
                renderOrders();
                renderDashboard();
            } catch {
                document.getElementById('orders-table-body').innerHTML =
                    '<tr><td colspan="8" class="px-5 py-10 text-center text-red-500 text-sm">Gagal terhubung ke server.</td></tr>';
            }
        }

        function updateOrderStats() {
            document.getElementById('stat-total').textContent = allOrders.length;
            document.getElementById('stat-verifying').textContent = allOrders.filter(o => o.status === 'VERIFYING').length;
            document.getElementById('stat-paid').textContent = allOrders.filter(o => ['PAID', 'SHIPPED'].includes(o.status)).length;
            document.getElementById('stat-completed').textContent = allOrders.filter(o => ['COMPLETED', 'DELIVERED'].includes(o.status)).length;
        }

        function setOrderFilter(filter) {
            activeOrderFilter = filter;
            document.querySelectorAll('.filter-btn').forEach(btn => {
                const active = btn.dataset.filter === filter;
                btn.className = `filter-btn px-3 py-1.5 rounded-lg text-xs font-bold transition ${active ? 'bg-orange-500 text-white' : 'bg-gray-800 text-gray-400 hover:bg-gray-700'}`;
            });
            renderOrders();
        }

        function renderOrders() {
            const search = (document.getElementById('orders-search')?.value || '').toLowerCase().trim();
            let list = allOrders;

            if (activeOrderFilter === 'NEED_VALIDATION') {
                list = allOrders.filter(o => o.status === 'VERIFYING' && ['TF', 'QRIS'].includes(o.payment_method));
            } else if (activeOrderFilter === 'NEED_SHIPPING') {
                list = allOrders.filter(o => o.status === 'PAID'); // PAID Covers processing and COD orders
            } else if (activeOrderFilter !== 'ALL') {
                list = allOrders.filter(o => o.status === activeOrderFilter);
            }

            if (search) list = list.filter(o => o.id.toLowerCase().includes(search) || String(o.user_id).includes(search));
            list = [...list].sort((a, b) => new Date(b.tanggal) - new Date(a.tanggal));

            const tbody = document.getElementById('orders-table-body');
            if (!list.length) {
                tbody.innerHTML = '<tr><td colspan="8" class="px-5 py-10 text-center text-gray-600 text-sm">Tidak ada pesanan.</td></tr>';
                return;
            }

            tbody.innerHTML = list.map(o => {
                let proof = '<span class="text-gray-600 text-xs">—</span>';
                if (o.payment?.proof_image_url) {
                    const url = o.payment.proof_image_url.startsWith('http') ? o.payment.proof_image_url : `${API}/${o.payment.proof_image_url}`;
                    proof = `<a href="${url}" target="_blank" class="text-orange-400 hover:text-orange-300 text-xs underline font-semibold">Lihat Bukti</a>`;
                }

                const pmBadge = { TF: 'bg-blue-900/60 text-blue-300', QRIS: 'bg-purple-900/60 text-purple-300', COD: 'bg-green-900/60 text-green-300' }[o.payment_method] || 'bg-gray-800 text-gray-400';
                const pmLabel = o.payment_method || '—';

                let actions = '<div class="flex flex-wrap justify-center gap-1.5">';
                if (o.status === 'VERIFYING') {
                    actions += `
                <button onclick="doUpdateStatus('${o.id}','PAID')" class="bg-green-700/50 hover:bg-green-600 text-green-300 px-2.5 py-1 rounded-lg text-xs font-bold transition-all flex items-center gap-1">✓ Setujui</button>
                <button onclick="doUpdateStatus('${o.id}','REJECTED')" class="bg-red-900/50 hover:bg-red-700 text-red-400 px-2.5 py-1 rounded-lg text-xs font-bold transition-all flex items-center gap-1">✕ Tolak</button>`;
                } else if (o.status === 'PAID') {
                    actions += `<button onclick="doShip('${o.id}')" class="bg-blue-700/50 hover:bg-blue-600 text-blue-300 px-2.5 py-1 rounded-lg text-xs font-bold transition-all flex items-center gap-1">📦 Kirim</button>`;
                } else if (o.status === 'SHIPPED') {
                    actions += `<button onclick="doUpdateStatus('${o.id}','DELIVERED')" class="bg-purple-700/50 hover:bg-purple-600 text-purple-300 px-2.5 py-1 rounded-lg text-xs font-bold transition-all flex items-center gap-1">✅ Selesai</button>`;
                } else if (o.status === 'UNPAID') {
                    actions += `
                <button onclick="doUpdateStatus('${o.id}','PAID')" class="bg-green-700/50 hover:bg-green-600 text-green-300 px-2.5 py-1 rounded-lg text-xs font-bold transition-all flex items-center gap-1">✓ Proses</button>
                <button onclick="doUpdateStatus('${o.id}','CANCELLED')" class="bg-gray-700 hover:bg-gray-600 text-gray-400 px-2.5 py-1 rounded-lg text-xs font-bold transition-all flex items-center gap-1">Batal</button>`;
                }
                
                actions += `<button onclick="doDeleteOrder('${o.id}')" class="bg-red-900/40 hover:bg-red-700 text-red-500 px-2.5 py-1 rounded-lg text-xs font-bold transition-all flex items-center gap-1">🗑 Hapus</button></div>`;


                // Order items for expandable detail
                const itemsHtml = o.items && o.items.length ? o.items.map(item => `
            <div class="flex items-center gap-3 py-1.5 border-b border-gray-700/30 last:border-0 border-dashed">
                ${item.product_image ? `<img src="${fixImageUrl(item.product_image)}" class="w-10 h-10 rounded-lg object-cover bg-gray-800 flex-shrink-0" onerror="this.style.display='none'">` : '<div class="w-10 h-10 rounded-lg bg-gray-800 flex-shrink-0"></div>'}
                <div class="flex-1 min-w-0">
                    <p class="text-xs font-bold text-gray-200 truncate">${item.product_name || 'Produk dihapus'}</p>
                    <div class="flex items-center gap-2 mt-0.5">
                        <span class="text-[11px] text-gray-500">${item.variant_name || '—'} × ${item.quantity}</span>
                        ${item.color_hex ? `
                        <div class="flex items-center gap-1 bg-gray-800 px-1.5 py-0.5 rounded border border-gray-700">
                            <span class="inline-block w-2 h-2 rounded-full border border-white/20" style="background-color: ${formatHex(item.color_hex)}"></span>
                            <span class="text-[9px] font-mono text-gray-400 uppercase">${item.color_hex}</span>
                        </div>` : ''}
                    </div>
                </div>
                <span class="text-xs font-bold text-orange-400 flex-shrink-0">${fmtRp(item.price_at_checkout * item.quantity)}</span>
            </div>`).join('') : '<p class="text-xs text-gray-600">Tidak ada item</p>';

                return `
            <tr class="border-b border-gray-800 hover:bg-gray-800/30 transition fade-in cursor-pointer" onclick="toggleOrderDetail('${o.id}')">
                <td class="px-4 py-3 text-center">
                    <span id="expand-icon-${o.id}" class="text-gray-600 text-xs select-none">▶</span>
                </td>
                <td class="px-4 py-3">
                    <span class="font-mono text-xs font-bold text-orange-400">#${o.id}</span>
                    <span class="ml-1 px-1.5 py-0.5 rounded text-[10px] font-bold ${pmBadge}">${pmLabel}</span>
                </td>
                <td class="px-4 py-3 text-sm text-gray-400">ID: ${o.user_id}</td>
                <td class="px-4 py-3 text-sm font-bold text-orange-300">${fmtRp(o.total)}</td>
                <td class="px-4 py-3">${statusBadge(o.status)}</td>
                <td class="px-4 py-3">${proof}</td>
                <td class="px-4 py-3 text-xs text-gray-500">${fmtDate(o.tanggal)}</td>
                <td class="px-4 py-3 text-center" onclick="event.stopPropagation()">${actions}</td>
            </tr>
            <tr id="detail-${o.id}" class="detail-section">
                <td colspan="8" class="bg-gray-800/30 border-b border-gray-800 p-0">
                    <div class="grid grid-cols-1 lg:grid-cols-3 gap-0 divide-x divide-gray-800">
                        <!-- Kolom Detail Item -->
                        <div class="p-6 col-span-1">
                            <p class="text-[10px] font-bold text-gray-500 uppercase tracking-widest mb-4 flex items-center gap-2">
                                <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"></path></svg>
                                Item Pesanan (${o.items?.length || 0})
                            </p>
                            <div class="space-y-1">${itemsHtml}</div>
                        </div>

                        <!-- Kolom Data Pelanggan -->
                        <div class="p-6 col-span-1 bg-gray-900/20">
                            <p class="text-[10px] font-bold text-gray-500 uppercase tracking-widest mb-4 flex items-center gap-2">
                                <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path></svg>
                                Data Pelanggan
                            </p>
                            <div class="flex items-start gap-4 mb-5">
                                <img src="${o.profile_image ? fixImageUrl(o.profile_image) : 'https://ui-avatars.com/api/?name=' + (o.username || 'U') + '&background=f97316&color=fff'}" 
                                     class="w-12 h-12 rounded-full object-cover border-2 border-orange-500/20 p-0.5" alt="">
                                <div>
                                    <p class="text-sm font-bold text-white leading-none">${o.username || 'Anonymous'}</p>
                                    <p class="text-[11px] text-gray-500 mt-1">${o.email || 'No email'}</p>
                                    <p class="text-[10px] text-orange-400 font-mono mt-0.5 tracking-tighter">USER_ID: ${o.user_id}</p>
                                </div>
                            </div>
                            <div class="space-y-3 pt-4 border-t border-gray-800/50">
                                <div>
                                    <p class="text-[10px] font-bold text-gray-600 uppercase mb-1">Alamat Pengiriman</p>
                                    <p class="text-xs text-gray-300 leading-relaxed">${o.shipping_address || '—'}</p>
                                </div>
                                <div>
                                    <p class="text-[10px] font-bold text-gray-600 uppercase mb-1">Telepon</p>
                                    <p class="text-xs text-gray-300 font-mono tracking-wider">${o.phone || '—'}</p>
                                </div>
                            </div>
                        </div>

                        <!-- Kolom Info Pembayaran & Resi -->
                        <div class="p-6 col-span-1">
                            <p class="text-[10px] font-bold text-gray-500 uppercase tracking-widest mb-4 flex items-center gap-2">
                                <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                                Ringkasan Transaksi
                            </p>
                            <div class="space-y-4">
                                <div class="grid grid-cols-2 gap-2 bg-gray-900/40 p-3 rounded-xl border border-gray-800">
                                    <div>
                                        <p class="text-[9px] font-bold text-gray-600 uppercase">Metode Bayar</p>
                                        <p class="text-xs font-bold text-white mt-0.5">${o.payment_method || '—'}</p>
                                    </div>
                                    <div class="text-right">
                                        <p class="text-[9px] font-bold text-gray-600 uppercase">Kode Unik</p>
                                        <p class="text-xs font-bold text-orange-400 mt-0.5">+Rp ${o.unique_code}</p>
                                    </div>
                                </div>
                                
                                ${o.tracking_number ? `
                                <div class="bg-blue-900/10 p-3 rounded-xl border border-blue-500/20">
                                    <p class="text-[9px] font-bold text-blue-400 uppercase mb-1">No. Resi Pengiriman</p>
                                    <p class="text-xs font-bold text-blue-200 font-mono select-all">${o.tracking_number}</p>
                                </div>` : ''}

                                ${o.expired_at ? `
                                <div class="bg-red-900/10 p-3 rounded-xl border border-red-500/20">
                                    <p class="text-[9px] font-bold text-red-400 uppercase mb-1">Batas Waktu</p>
                                    <p class="text-[10px] text-red-300">${fmtDate(o.expired_at)}</p>
                                </div>` : ''}
                            </div>
                        </div>
                    </div>
                </td>
            </tr>`;
            }).join('');
        }

        function toggleOrderDetail(id) {
            const row = document.getElementById(`detail-${id}`);
            const icon = document.getElementById(`expand-icon-${id}`);
            const isOpen = row.classList.contains('open');
            row.classList.toggle('open', !isOpen);
            icon.textContent = isOpen ? '▶' : '▼';
            icon.classList.toggle('text-orange-400', !isOpen);
            icon.classList.toggle('text-gray-600', isOpen);
        }

        async function doUpdateStatus(orderId, newStatus) {
            const labels = { PAID: 'Setujui pembayaran', REJECTED: 'Tolak bukti bayar', DELIVERED: 'Selesaikan order', CANCELLED: 'Batalkan order' };
            confirm2(labels[newStatus] || 'Update Status', `Update order #${orderId} → ${newStatus}?`, async () => {
                try {
                    const res = await fetch(`${API}/admin/orders/${orderId}/status`, {
                        method: 'PUT',
                        headers: getHeaders(),
                        body: JSON.stringify({ status: newStatus })
                    });
                    if (res.ok) { toast(`Order #${orderId} → ${newStatus}`); fetchOrders(); }
                    else { const d = await res.json(); toast(d.detail || 'Gagal update', 'error'); }
                } catch { toast('Koneksi gagal', 'error'); }
            });
        }

        async function doDeleteOrder(orderId) {
            confirm2('Hapus Pesanan', `Hapus permanen order #${orderId}?`, async () => {
                try {
                    const res = await fetch(`${API}/admin/orders/${orderId}`, {
                        method: 'DELETE',
                        headers: getHeaders()
                    });
                    if (res.ok) { toast('Order berhasil dihapus'); fetchOrders(); }
                    else { const d = await res.json(); toast(d.detail || 'Gagal hapus', 'error'); }
                } catch { toast('Koneksi gagal', 'error'); }
            });
        }

        async function doDeleteUser(userId) {
            confirm2('Hapus Pengguna', `Hapus permanen pengguna #${userId}?`, async () => {
                try {
                    const res = await fetch(`${API}/admin/users/${userId}`, {
                        method: 'DELETE',
                        headers: getHeaders()
                    });
                    if (res.ok) { toast('Pengguna berhasil dihapus'); fetchUsers(); }
                    else { const d = await res.json(); toast(d.detail || 'Gagal hapus', 'error'); }
                } catch { toast('Koneksi gagal', 'error'); }
            });
        }

        async function doShip(orderId) {
            const resi = prompt(`Nomor resi pengiriman untuk order #${orderId} (kosongkan jika belum ada):`);
            if (resi === null) return; // User cancel prompt
            try {
                const res = await fetch(`${API}/admin/orders/${orderId}/status`, {
                    method: 'PUT',
                    headers: getHeaders(),
                    body: JSON.stringify({ status: 'SHIPPED', tracking_number: resi.trim() || null })
                });
                if (res.ok) { toast(`Order #${orderId} → SHIPPED${resi.trim() ? ', resi: ' + resi.trim() : ''}`); fetchOrders(); }
                else { const d = await res.json(); toast(d.detail || 'Gagal kirim', 'error'); }
            } catch { toast('Koneksi gagal', 'error'); }
        }

        // ═══════════════════════════════════════════════════════════
        // CATEGORIES
        // ═══════════════════════════════════════════════════════════
        function populateCategorySelects() {
            const cats = getCategories();
            ['p-category', 'edit-category', 'products-category-filter'].forEach(id => {
                const el = document.getElementById(id);
                if (!el) return;
                const isFilter = id === 'products-category-filter';
                const currentVal = el.value;
                el.innerHTML = isFilter ? '<option value="">Semua Kategori</option>' : '';
                cats.forEach(c => {
                    const opt = document.createElement('option');
                    opt.value = c; opt.textContent = c;
                    el.appendChild(opt);
                });
                if (!isFilter) {
                    const custom = document.createElement('option');
                    custom.value = '__custom__'; custom.textContent = '+ Tambah Kategori Baru...';
                    el.appendChild(custom);
                }
                if (currentVal) el.value = currentVal;
            });
        }

        function handleAddCategoryChange() {
            const wrap = document.getElementById('add-custom-category-wrap');
            wrap.classList.toggle('hidden', document.getElementById('p-category').value !== '__custom__');
        }
        function handleEditCategoryChange() {
            const wrap = document.getElementById('edit-custom-category-wrap');
            wrap.classList.toggle('hidden', document.getElementById('edit-category').value !== '__custom__');
        }
        function saveCustomCategory() {
            const val = document.getElementById('p-custom-category').value.trim();
            if (!val) { toast('Nama kategori tidak boleh kosong', 'warn'); return; }
            const cats = getCategories();
            if (!cats.includes(val)) { cats.push(val); saveCategories(cats); }
            populateCategorySelects();
            document.getElementById('p-category').value = val;
            document.getElementById('add-custom-category-wrap').classList.add('hidden');
            toast(`Kategori "${val}" ditambahkan`);
        }

        // ── Category Manager Modal ───────────────────────────────────
        function openCategoryModal() {
            renderCategoryList();
            document.getElementById('new-cat-input').value = '';
            const m = document.getElementById('category-modal');
            m.classList.remove('hidden'); m.classList.add('flex');
        }
        function closeCategoryModal() {
            document.getElementById('category-modal').classList.replace('flex', 'hidden');
        }
        function renderCategoryList() {
            const cats = getCategories();
            const el = document.getElementById('category-list');
            if (!cats.length) {
                el.innerHTML = '<p class="text-xs text-gray-600 italic text-center py-3">Belum ada kategori</p>';
                return;
            }
            el.innerHTML = cats.map((c, i) => `
                <div class="flex items-center justify-between bg-gray-700/50 rounded-xl px-3 py-2">
                    <span class="text-sm text-gray-200 font-medium">${c}</span>
                    <button onclick="deleteCategoryItem(${i})"
                        class="w-7 h-7 flex items-center justify-center bg-red-900/50 hover:bg-red-700 text-red-400 hover:text-white rounded-lg text-xs font-bold transition-colors flex-shrink-0">✕</button>
                </div>`).join('');
        }
        function deleteCategoryItem(index) {
            const cats = getCategories();
            const name = cats[index];
            cats.splice(index, 1);
            saveCategories(cats);
            populateCategorySelects();
            renderCategoryList();
            toast(`Kategori "${name}" dihapus`);
        }
        function addCategoryFromModal() {
            const val = document.getElementById('new-cat-input').value.trim();
            if (!val) { toast('Nama kategori tidak boleh kosong', 'warn'); return; }
            const cats = getCategories();
            if (cats.includes(val)) { toast('Kategori sudah ada', 'warn'); return; }
            cats.push(val);
            saveCategories(cats);
            populateCategorySelects();
            renderCategoryList();
            document.getElementById('new-cat-input').value = '';
            toast(`Kategori "${val}" ditambahkan`);
        }

        // ═══════════════════════════════════════════════════════════
        // PRODUCTS — SKU Builder
        // ═══════════════════════════════════════════════════════════
        // ═══════════════════════════════════════════════════════════
        // PRODUCTS — Matrix Variation Builder
        // ═══════════════════════════════════════════════════════════
        let productSizes = [];

        function initSkuRows() {
            productSizes = ['39', '40', '41', '42', '43'];
            excludedMatrixRows.clear();
            renderSizeTags();
            updateVariationMatrix();
        }

        function addSizeTag(val) {
            val = val.trim();
            if (!val) return;
            if (!productSizes.includes(val)) {
                productSizes.push(val);
                renderSizeTags();
                updateVariationMatrix();
            }
        }

        function removeSizeTag(index) {
            productSizes.splice(index, 1);
            renderSizeTags();
            updateVariationMatrix();
        }

        function renderSizeTags() {
            const container = document.getElementById('p-size-tags');
            container.innerHTML = productSizes.map((s, i) => `
        <span class="bg-orange-500/20 text-orange-400 text-[11px] font-bold px-2 py-1 rounded-lg border border-orange-500/30 flex items-center gap-1.5 fade-in">
            ${s}
            <button type="button" onclick="removeSizeTag(${i})" class="hover:text-red-400">✕</button>
        </span>
    `).join('');
        }

        function addColorInput() {
            const list = document.getElementById('p-color-list');
            const div = document.createElement('div');
            div.className = 'color-item relative fade-in';
            div.innerHTML = `
                <input type="color" value="#000000"
                    class="w-12 h-12 rounded-xl cursor-pointer border-2 border-gray-600 hover:border-orange-500 transition-all p-0.5 bg-transparent"
                    onchange="updateVariationMatrix()">
                <button type="button"
                    onclick="this.parentElement.remove(); updateVariationMatrix();"
                    class="absolute -top-2 -right-2 w-5 h-5 bg-red-600 hover:bg-red-500 rounded-full text-white text-[10px] font-bold flex items-center justify-center shadow-lg border border-red-800 transition-colors">✕</button>
            `;
            list.appendChild(div);
            updateVariationMatrix();
        }

        function updateVariationMatrix() {
            const colorInputs = Array.from(document.querySelectorAll('#p-color-list .color-item input[type="color"]'));
            let colors = colorInputs.map(inp => '0xFF' + inp.value.replace('#', '').toUpperCase());
            colors = [...new Set(colors)]; // Deduplicate identical colors
            const tbody = document.getElementById('sku-matrix-rows');
            const section = document.getElementById('matrix-section');
            const price = document.getElementById('p-price').value;

            if (colors.length === 0 || productSizes.length === 0) {
                section.classList.add('hidden');
                return;
            }
            section.classList.remove('hidden');

            // Keep existing data to avoid overwriting during incremental updates
            const existingData = {};
            document.querySelectorAll('.matrix-row').forEach(row => {
                const key = `${row.dataset.color}-${row.dataset.size}`;
                existingData[key] = {
                    price: row.querySelector('.m-price').value,
                    stock: row.querySelector('.m-stock').value
                };
            });

            tbody.innerHTML = '';
            colors.forEach(color => {
                const colorHex = color.replace('0xFF', '#');

                // Color group header row
                const headerRow = document.createElement('tr');
                headerRow.className = 'bg-gray-800/70';
                headerRow.innerHTML = `
                    <td colspan="4" class="py-2 px-3">
                        <div class="flex items-center gap-2">
                            <div style="background-color: ${colorHex}" class="w-4 h-4 rounded-full border border-gray-500 shadow-sm flex-shrink-0"></div>
                            <span class="text-xs font-bold text-gray-300">${colorHex}</span>
                        </div>
                    </td>
                `;
                tbody.appendChild(headerRow);

                productSizes.forEach(size => {
                    const key = `${color}-${size}`;
                    if (excludedMatrixRows.has(key)) return; // Skip manually deleted rows

                    const data = existingData[key] || { price: price || '', stock: '10' };
                    const tr = document.createElement('tr');
                    tr.className = 'matrix-row border-b border-gray-800/30 hover:bg-white/[0.02] transition-colors';
                    tr.dataset.color = color;
                    tr.dataset.size = size;
                    tr.innerHTML = `
                        <td class="py-2.5 pl-7">
                            <input type="hidden" class="m-color" value="${color}">
                            <span class="text-gray-600 text-xs">└</span>
                        </td>
                        <td class="py-2.5 pl-2">
                            <span class="text-xs font-bold text-gray-200">Size ${size}</span>
                            <input type="hidden" class="m-name" value="Size ${size}">
                        </td>
                        <td class="py-2.5 pl-2">
                            <div class="relative">
                                <span class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-600 text-[10px]">Rp</span>
                                <input type="text" value="${data.price}"
                                    class="m-price w-full bg-gray-900/50 border border-gray-800 rounded-lg pl-8 pr-3 py-1.5 text-xs text-white focus:outline-none focus:border-orange-500 transition-all">
                            </div>
                        </td>
                        <td class="py-2.5 pl-2 text-center">
                            <input type="number" value="${data.stock}"
                                class="m-stock w-16 bg-gray-900/50 border border-gray-800 rounded-lg px-2 py-1.5 text-xs text-white text-center focus:outline-none focus:border-orange-500 transition-all font-bold">
                        </td>
                        <td class="py-2.5 pr-4 text-right">
                             <button type="button" onclick="removeMatrixRow('${color}', '${size}')" 
                                class="text-red-600 hover:text-red-400 p-1 rounded-lg hover:bg-red-500/10 transition-all">
                                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                             </button>
                        </td>
                    `;
                    tbody.appendChild(tr);
                });
            });
        }

        function removeMatrixRow(color, size) {
            excludedMatrixRows.add(`${color}-${size}`);
            updateVariationMatrix();
        }




        function applyBulk() {
            const price = document.getElementById('bulk-price').value;
            const stock = document.getElementById('bulk-stock').value;
            if (price) {
                document.querySelectorAll('.m-price').forEach(el => el.value = price);
            }
            if (stock) {
                document.querySelectorAll('.m-stock').forEach(el => el.value = stock);
            }
            toast('Konfigurasi diterapkan ke semua variasi');
        }



        function handleGalleryInput(input) {
            const files = input.files;
            const preview = document.getElementById('p-gallery-preview');
            preview.innerHTML = '';
            if (!files.length) return;

            Array.from(files).forEach(file => {
                const reader = new FileReader();
                reader.onload = e => {
                    const div = document.createElement('div');
                    div.className = 'w-16 h-16 rounded-lg overflow-hidden border border-gray-700 bg-gray-800 flex-shrink-0';
                    div.innerHTML = `<img src="${e.target.result}" class="w-full h-full object-cover">`;
                    preview.appendChild(div);
                };
                reader.readAsDataURL(file);
            });
        }

        function syncSkuPrices() {
            const price = document.getElementById('p-price').value;
            document.querySelectorAll('#sku-rows .sku-price').forEach(inp => {
                if (!inp.dataset.overridden) inp.value = price;
            });
        }

        // ═══════════════════════════════════════════════════════════
        // PRODUCTS — CRUD
        // ═══════════════════════════════════════════════════════════
        async function fetchProducts() {
            try {
                const res = await fetch(`${API}/products`);
                allProducts = await res.json();
                renderProductsFiltered();
                renderDashboard();
            } catch {
                document.getElementById('products-table-body').innerHTML =
                    '<tr><td colspan="6" class="px-5 py-10 text-center text-red-500 text-sm">Gagal terhubung ke server.</td></tr>';
            }
        }

        function renderProductsFiltered() {
            const search = (document.getElementById('products-search')?.value || '').toLowerCase();
            const catFilter = document.getElementById('products-category-filter')?.value || '';
            let list = allProducts;
            if (search) list = list.filter(p => p.name.toLowerCase().includes(search));
            if (catFilter) list = list.filter(p => p.category === catFilter);
            renderProducts(list);
        }

        function renderProducts(products) {
            const tbody = document.getElementById('products-table-body');
            if (!products.length) {
                tbody.innerHTML = '<tr><td colspan="6" class="px-5 py-10 text-center text-gray-600 text-sm">Belum ada produk.</td></tr>';
                return;
            }
            tbody.innerHTML = products.map(p => {
                const imgUrl = fixImageUrl(p.image);
                const totalStock = p.skus.reduce((s, sku) => s + sku.stock_available, 0);
                const stockColor = totalStock === 0 ? 'text-red-400' : totalStock <= 10 ? 'text-yellow-400' : 'text-green-400';

                // Group SKUs by color (warna sebagai induk)
                const skuByColor = new Map();
                p.skus.forEach(sku => {
                    const key = sku.color_hex || 'null';
                    if (!skuByColor.has(key)) skuByColor.set(key, []);
                    skuByColor.get(key).push(sku);
                });
                const skusHtml = Array.from(skuByColor.entries()).map(([colorKey, colorSkus]) => {
                    const colorHex = colorKey !== 'null' ? colorKey.replace('0xFF', '#') : null;
                    const colorHeader = colorHex
                        ? `<div class="flex items-center gap-2 pt-2 pb-1">
                            <div style="background-color:${colorHex}" class="w-3 h-3 rounded-full border border-gray-500 flex-shrink-0"></div>
                            <span class="text-[11px] font-bold text-gray-400">${colorHex}</span>
                           </div>`
                        : `<div class="pt-2 pb-1"><span class="text-[11px] font-bold text-gray-500">Universal</span></div>`;
                    const rows = colorSkus.map(sku => `
                        <div class="flex items-center justify-between py-1 pl-5 border-b border-gray-700/50 last:border-0">
                            <span class="text-xs text-gray-300 w-20 flex-shrink-0">${sku.variant_name}</span>
                            <div class="flex items-center gap-2">
                                <span class="text-[11px] text-gray-600">${fmtRp(sku.price)}</span>
                                <input type="number" id="stock-${sku.id}" value="${sku.stock_available}" min="0"
                                    class="w-16 bg-gray-700 border border-gray-600 rounded-lg px-2 py-0.5 text-xs text-white text-center focus:outline-none focus:border-orange-500"
                                    onclick="event.stopPropagation()">
                                <button onclick="event.stopPropagation(); updateStock(${sku.id})"
                                    class="bg-orange-500/80 hover:bg-orange-500 text-white px-2 py-0.5 rounded-lg text-xs font-bold">Simpan</button>
                                <span class="text-gray-600 text-[10px]">res:${sku.stock_reserved}</span>
                                <button onclick="event.stopPropagation(); deleteSku(${sku.id}, '${sku.variant_name.replace(/'/g, "\\'")}', ${p.id})"
                                    class="text-red-600 hover:text-red-400 text-xs ml-1" title="Hapus varian ini">✕</button>
                            </div>
                        </div>`).join('');
                    return colorHeader + rows;
                }).join('');

                return `
            <tr class="border-b border-gray-800 hover:bg-gray-800/30 transition cursor-pointer" onclick="toggleProductDetail('${p.id}')">
                <td class="px-4 py-3 text-center">
                    <span id="prod-expand-${p.id}" class="text-gray-600 text-xs select-none">▶</span>
                </td>
                <td class="px-4 py-4">
                    <div class="flex items-center gap-3">
                        <img src="${imgUrl}" alt="" class="w-10 h-10 rounded-xl object-cover bg-gray-800 border border-gray-700 flex-shrink-0"
                            onerror="this.style.visibility='hidden'">
                        <div>
                            <p class="text-sm font-bold text-white">${p.name}</p>
                            <p class="text-xs text-gray-500 truncate max-w-[200px]">${p.description || '—'}</p>
                        </div>
                    </div>
                </td>
                <td class="px-4 py-4">
                    <span class="px-2.5 py-1 text-xs font-semibold rounded-lg bg-gray-800 text-gray-400 border border-gray-700">${p.category || '—'}</span>
                </td>
                <td class="px-4 py-4 text-sm font-bold text-orange-300">${fmtRp(p.price)}</td>
                <td class="px-4 py-4">
                    <span class="text-sm font-bold ${stockColor}">${totalStock}</span>
                    <span class="text-xs text-gray-600 ml-1">pcs</span>
                </td>
                <td class="px-4 py-4 text-center" onclick="event.stopPropagation()">
                    <div class="flex items-center justify-center gap-1.5 flex-wrap">
                        <button onclick="openEditModal(${p.id})" class="bg-indigo-700/50 hover:bg-indigo-600 text-indigo-300 px-2.5 py-1 rounded-lg text-xs font-bold">✏ Edit</button>
                        <button onclick="openPhotoModal(${p.id}, '${p.name.replace(/'/g, "\\'")}\')" class="bg-blue-700/50 hover:bg-blue-600 text-blue-300 px-2.5 py-1 rounded-lg text-xs font-bold">🖼 Foto</button>
                        <button onclick="deleteProduct(${p.id})" class="bg-red-900/40 hover:bg-red-700 text-red-400 px-2.5 py-1 rounded-lg text-xs font-bold">🗑 Hapus</button>
                    </div>
                </td>
            </tr>
            <tr id="prod-detail-${p.id}" class="detail-section">
                <td colspan="6" class="bg-gray-800/40 border-b border-gray-800 px-8 py-4">
                    <p class="text-xs font-bold text-gray-400 uppercase mb-3">Variasi & Stok — ${p.name}</p>
                    <div class="space-y-0.5 max-w-lg">${skusHtml || '<p class="text-xs text-gray-600">Tidak ada varian</p>'}</div>
                </td>
            </tr>`;
            }).join('');
        }

        function toggleProductDetail(id) {
            const row = document.getElementById(`prod-detail-${id}`);
            const icon = document.getElementById(`prod-expand-${id}`);
            const isOpen = row.classList.contains('open');
            row.classList.toggle('open', !isOpen);
            icon.textContent = isOpen ? '▶' : '▼';
            icon.classList.toggle('text-orange-400', !isOpen);
            icon.classList.toggle('text-gray-600', isOpen);
        }

        async function submitAddProduct(e) {
            e.preventDefault();
            const name = document.getElementById('p-name').value.trim();
            let category = document.getElementById('p-category').value;
            if (category === '__custom__') {
                category = document.getElementById('p-custom-category').value.trim();
                if (!category) { toast('Nama kategori wajib diisi', 'warn'); return; }
            }
            const price = parsePrice(document.getElementById('p-price').value);
            const description = document.getElementById('p-description').value.trim() || 'Produk baru.';
            const specification = document.getElementById('p-specification').value.trim() || 'No specification provided.';

            // Collect Colors
            const colorItems = document.querySelectorAll('#p-color-list .color-item input[type="color"]');
            const colors = Array.from(colorItems).map(inp => ({
                color_hex: '0xFF' + inp.value.replace('#', '').toUpperCase()
            }));
            if (colors.length === 0) { toast('Minimal pilih satu warna!', 'warn'); return; }

            if (!name || !price || !category) { toast('Lengkapi field wajib!', 'warn'); return; }

            // Collect SKUs from Matrix
            const matrixRows = document.querySelectorAll('#sku-matrix-rows .matrix-row');
            const skus = [];
            matrixRows.forEach(row => {
                const vName = row.querySelector('.m-name').value;
                const vColor = row.querySelector('.m-color').value;
                const vPrice = parsePrice(row.querySelector('.m-price').value) || price;
                const vStock = parseInt(row.querySelector('.m-stock').value) || 0;
                skus.push({ variant_name: vName, color_hex: vColor, price: vPrice, stock_available: vStock, stock_reserved: 0 });
            });
            if (skus.length === 0) { toast('Minimal harus memiliki satu kombinasi warna & ukuran', 'warn'); return; }

            const payload = {
                name, price, description, specification,
                image: 'uploads/default.jpg', category, rating: 5.0,
                skus, colors
            };

            try {
                const res = await fetch(`${API}/products`, {
                    method: 'POST', headers: getHeaders(),
                    body: JSON.stringify(payload)
                });
                if (res.ok) {
                    const prod = await res.json();

                    // Handle Gallery Uploads
                    const galleryInput = document.getElementById('p-gallery-input');
                    const files = galleryInput.files;
                    if (files.length > 0) {
                        toast('Mengupload galeri foto...');
                        // 1. Upload thumbnail (first image)
                        const fdThumb = new FormData();
                        fdThumb.append('file', files[0]);
                        await fetch(`${API}/admin/products/${prod.id}/image`, {
                            method: 'POST', headers: getAdminHeaders(), body: fdThumb
                        });

                        // 2. Upload all to gallery
                        const fdGallery = new FormData();
                        for (let i = 0; i < files.length; i++) fdGallery.append('files', files[i]);
                        await fetch(`${API}/admin/products/${prod.id}/gallery`, {
                            method: 'POST', headers: getAdminHeaders(), body: fdGallery
                        });
                    }

                    toast(`Produk "${prod.name}" berhasil dibuat!`, 'success');
                    document.getElementById('add-product-form').reset();
                    document.getElementById('p-gallery-preview').innerHTML = ''; // Clear preview
                    initSkuRows();
                    fetchProducts();
                    // Save category if new
                    const cats = getCategories();
                    if (!cats.includes(category)) { cats.push(category); saveCategories(cats); populateCategorySelects(); }
                } else {
                    const d = await res.json();
                    toast(d.detail || 'Gagal tambah produk', 'error');
                }
            } catch { toast('Koneksi gagal', 'error'); }
        }

        async function updateStock(skuId) {
            const val = document.getElementById(`stock-${skuId}`).value;
            try {
                const res = await fetch(`${API}/admin/skus/${skuId}?stock=${val}`, { method: 'PUT', headers: getAdminHeaders() });
                if (res.ok) { toast('Stok diperbarui!'); fetchProducts(); }
                else toast('Gagal update stok', 'error');
            } catch { toast('Koneksi gagal', 'error'); }
        }

        async function deleteSku(skuId, variantName, productId) {
            confirm2('Hapus Varian', `Hapus ukuran "${variantName}"?`, async () => {
                try {
                    const res = await fetch(`${API}/admin/skus/${skuId}`, { method: 'DELETE', headers: getAdminHeaders() });
                    if (res.ok) { toast('Varian dihapus'); fetchProducts(); }
                    else toast('Gagal hapus varian', 'error');
                } catch { toast('Koneksi gagal', 'error'); }
            });
        }

        async function deleteProduct(id) {
            confirm2('Hapus Produk', 'Produk dan semua variasinya dihapus permanen. Lanjutkan?', async () => {
                try {
                    const res = await fetch(`${API}/admin/products/${id}`, { method: 'DELETE', headers: getAdminHeaders() });
                    if (res.ok) { toast('Produk dihapus'); fetchProducts(); }
                    else toast('Gagal hapus produk', 'error');
                } catch { toast('Koneksi gagal', 'error'); }
            });
        }

        // ── Photo Modal ───────────────────────────────────────────
        let photoQueueFiles = [];
        let existingPhotoChanges = {};   // {imageId: newRole}
        let existingPhotoDeletions = new Set(); 

        function openPhotoModal(productId, productName) {
            currentPhotoProductId = productId;
            document.getElementById('photo-product-name').textContent = productName;
            document.getElementById('photo-file-input').value = '';
            document.getElementById('photo-queue-container').innerHTML = '';
            document.getElementById('photo-submit-btn').disabled = true; // Disabled until change detected
            photoQueueFiles = [];
            existingPhotoChanges = {};
            existingPhotoDeletions.clear();

            const p = allProducts.find(x => x.id === productId);
            const existContainer = document.getElementById('photo-existing-container');
            existContainer.innerHTML = '';

            if (p && p.gallery && p.gallery.length > 0) {
                const colorOptionsTemplate = (p.colors || []).map(c => 
                    `<option value="${c.color_hex}">Spesifik Warna: ${c.color_hex.replace('0xFF', '#')}</option>`
                ).join('');

                p.gallery.forEach(img => {
                    const row = document.createElement('div');
                    row.className = 'flex items-center gap-3 bg-gray-800 p-2 rounded-lg border border-gray-700 fade-in';
                    row.id = `existing-photo-row-${img.id}`;
                    
                    const normalizedUrl = fixImageUrl(img.image_url);
                    const isCurrentThumb = (img.image_url === p.image);
                    const hexValue = img.color_hex || 'gallery';

                    row.innerHTML = `
                        <div class="relative shrink-0">
                            <img src="${normalizedUrl}" class="w-12 h-12 rounded object-cover border border-gray-600">
                            ${isCurrentThumb ? '<span class="absolute -top-1 -left-1 bg-orange-500 text-white text-[8px] font-bold px-1 rounded border border-orange-300">THUMB</span>' : ''}
                        </div>
                        <div class="flex-1 min-w-0">
                            <div class="flex items-center gap-1.5 mb-1">
                                <p class="text-[10px] font-medium text-gray-500">ID: ${img.id}</p>
                                ${isCurrentThumb ? '<span class="text-[9px] text-orange-400 font-bold uppercase tracking-wider">Thumbnail Aktif</span>' : ''}
                            </div>
                            <select onchange="updateExistingPhotoRole(${img.id}, this.value)" class="bg-gray-700 border border-gray-600 text-xs rounded px-2 py-1 text-white w-full outline-none focus:border-orange-500">
                                <option value="gallery" ${hexValue === 'gallery' && !isCurrentThumb ? 'selected' : ''}>Galeri Umum (Bawaan)</option>
                                <option value="thumbnail" ${isCurrentThumb ? 'selected' : ''}>Jadikan Thumbnail Utama</option>
                                ${ (p.colors || []).map(c => 
                                    `<option value="${c.color_hex}" ${hexValue === c.color_hex && !isCurrentThumb ? 'selected' : ''}>Spesifik Warna: ${c.color_hex.replace('0xFF', '#')}</option>`
                                ).join('') }
                            </select>
                        </div>
                        <button type="button" onclick="deleteExistingPhoto(${img.id}, this)" class="text-red-400 hover:bg-red-500/20 p-1.5 rounded transition" title="Hapus Foto">
                           <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
                        </button>
                    `;
                    existContainer.appendChild(row);
                });
            }

            const m = document.getElementById('photo-modal');
            m.classList.remove('hidden'); m.classList.add('flex');
        }

        function deleteExistingPhoto(imageId, btnElement) {
            existingPhotoDeletions.add(imageId);
            document.getElementById(`existing-photo-row-${imageId}`).classList.add('opacity-30', 'grayscale', 'pointer-events-none');
            document.getElementById('photo-submit-btn').disabled = false;
        }

        function updateExistingPhotoRole(imageId, newRole) {
            existingPhotoChanges[imageId] = newRole;
            document.getElementById('photo-submit-btn').disabled = false;
        }

        function closePhotoModal() {
            document.getElementById('photo-modal').classList.replace('flex', 'hidden');
            currentPhotoProductId = null;
        }
        function previewPhotoQueue(input) {
            const files = Array.from(input.files);
            if (!files.length) return;
            
            const p = allProducts.find(x => x.id === currentPhotoProductId);
            const colorOptions = (p.colors || []).map(c => `<option value="${c.color_hex}">Spesifik Warna: ${c.color_hex.replace('0xFF', '#')}</option>`).join('');

            const container = document.getElementById('photo-queue-container');
            
            files.forEach((file, idx) => {
                const uniqueId = Date.now() + '-' + Math.random();
                photoQueueFiles.push({ id: uniqueId, file: file });

                const reader = new FileReader();
                reader.onload = e => {
                    const row = document.createElement('div');
                    row.className = 'flex items-center gap-3 bg-gray-800 p-2 rounded-lg border border-gray-700';
                    row.dataset.qid = uniqueId;
                    row.innerHTML = `
                        <img src="${e.target.result}" class="w-12 h-12 rounded object-cover border border-gray-600 shrink-0">
                        <div class="flex-1 min-w-0">
                            <p class="text-[11px] truncate font-medium text-gray-300 mb-1">${file.name}</p>
                            <select class="photo-role-select bg-gray-700 border border-gray-600 text-xs rounded px-2 py-1 text-white w-full outline-none focus:border-orange-500">
                                <option value="gallery">Galeri Umum (Bawaan)</option>
                                <option value="thumbnail">Jadikan Thumbnail Utama</option>
                                ${colorOptions}
                            </select>
                        </div>
                        <button type="button" onclick="removeQueueRow('${uniqueId}', this)" class="text-red-400 hover:bg-red-500/20 p-1.5 rounded transition">
                           <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                        </button>
                    `;
                    container.appendChild(row);
                };
                reader.readAsDataURL(file);
            });
            input.value = '';
            document.getElementById('photo-submit-btn').disabled = false;
        }
        function removeQueueRow(uid, btn) {
            photoQueueFiles = photoQueueFiles.filter(x => x.id !== uid);
            btn.closest('div[data-qid]').remove();
        }

        async function submitPhotoQueue() {
            if (!currentPhotoProductId) return;
            const hasNew = (photoQueueFiles.length > 0);
            const hasExistChanges = (Object.keys(existingPhotoChanges).length > 0);
            const hasDeletions = (existingPhotoDeletions.size > 0);

            if (!hasNew && !hasExistChanges && !hasDeletions) {
                toast('Tidak ada perubahan untuk disimpan', 'warn');
                return;
            }

            const btn = document.getElementById('photo-submit-btn');
            btn.disabled = true; btn.textContent = 'Sedang Menyimpan...';

            try {
                // 1. Process Deletions
                if (hasDeletions) {
                    for (const imgId of existingPhotoDeletions) {
                        await fetch(`${API}/admin/products/${currentPhotoProductId}/gallery/${imgId}`, {
                            method: 'DELETE', headers: getAdminHeaders()
                        });
                    }
                }

                // 2. Process Existing metadata changes (Role/Thumbnail)
                if (hasExistChanges) {
                    for (const [imgId, role] of Object.entries(existingPhotoChanges)) {
                        // Skip if image was marked for deletion
                        if (existingPhotoDeletions.has(parseInt(imgId))) continue;

                        if (role === 'thumbnail') {
                            await fetch(`${API}/admin/products/${currentPhotoProductId}/thumbnail/${imgId}`, {
                                method: 'PATCH', headers: getAdminHeaders()
                            });
                        } else {
                            await fetch(`${API}/admin/products/${currentPhotoProductId}/gallery/${imgId}`, {
                                method: 'PUT',
                                headers: getHeaders(),
                                body: JSON.stringify({ color_hex: role === 'gallery' ? null : role })
                            });
                        }
                    }
                }

                // 3. Process New Uploads (Original Logic)
                if (hasNew) {
                    const container = document.getElementById('photo-queue-container');
                    const selects = container.querySelectorAll('.photo-role-select');
                    
                    let thumbFile = null;
                    const galleryFiles = [];

                    selects.forEach((sel, i) => {
                        const role = sel.value;
                        const f = photoQueueFiles[i].file;
                        if (role === 'thumbnail' && !thumbFile) {
                            thumbFile = f;
                        } else if (role === 'gallery' || role === 'thumbnail') {
                            galleryFiles.push({ file: f, color_hex: null });
                        } else {
                            galleryFiles.push({ file: f, color_hex: role });
                        }
                    });

                    if (thumbFile) {
                        const fd = new FormData();
                        fd.append('file', thumbFile);
                        await fetch(`${API}/admin/products/${currentPhotoProductId}/image`, {
                            method: 'POST', headers: getAdminHeaders(), body: fd
                        });
                    }
                    
                    const groups = {};
                    galleryFiles.forEach(item => {
                        const k = item.color_hex || 'null';
                        if (!groups[k]) groups[k] = [];
                        groups[k].push(item.file);
                    });

                    for (const k of Object.keys(groups)) {
                        const fdG = new FormData();
                        groups[k].forEach(f => fdG.append('files', f));
                        if (k !== 'null') fdG.append('color_hex', k);
                        
                        await fetch(`${API}/admin/products/${currentPhotoProductId}/gallery`, {
                            method: 'POST', headers: getAdminHeaders(), body: fdG
                        });
                    }
                }

                toast('Semua perubahan galeri berhasil disimpan!');
                closePhotoModal(); 
                fetchProducts();
            } catch (e) { 
                toast('Gagal menyimpan: ' + e.message, 'error'); 
            } finally { 
                btn.disabled = false; btn.textContent = 'Simpan Perubahan'; 
            }
        }

        // ── Edit Product Modal ────────────────────────────────────
        function openEditModal(productId) {
            const p = allProducts.find(x => x.id === productId);
            if (!p) return;
            currentEditProductId = productId;
            editingProductData = p;

            document.getElementById('edit-product-id-label').textContent = `#${p.id}`;
            document.getElementById('edit-name').value = p.name;
            document.getElementById('edit-price').value = p.price;
            document.getElementById('edit-description').value = p.description || '';
            document.getElementById('edit-specification').value = p.specification || '';

            // Category dropdown
            const cats = getCategories();
            if (!cats.includes(p.category) && p.category) { cats.push(p.category); saveCategories(cats); populateCategorySelects(); }
            document.getElementById('edit-category').value = p.category || cats[0];
            document.getElementById('edit-custom-category-wrap').classList.add('hidden');

            // Colors
            const colorList = document.getElementById('edit-color-list');
            colorList.innerHTML = '';
            if (p.colors && p.colors.length) {
                p.colors.forEach(c => addColorInputEdit(c.color_hex));
            }

            // SKU list
            renderEditSkuList(p.skus);

            document.getElementById('add-sku-in-modal').classList.add('hidden');
            const m = document.getElementById('edit-modal');
            m.classList.remove('hidden'); m.classList.add('flex');
        }

        function addColorInputEdit(hex = '#000000') {
            const list = document.getElementById('edit-color-list');
            const div = document.createElement('div');
            div.className = 'color-item relative fade-in';
            const hexVal = hex.startsWith('0xFF') ? '#' + hex.replace('0xFF', '') : hex;
            const hexApi = '0xFF' + hexVal.replace('#', '').toUpperCase();
            
            div.innerHTML = `
                <input type="color" value="${hexVal}" data-prev="${hexApi}"
                    class="w-12 h-12 rounded-xl cursor-pointer border-2 border-gray-600 hover:border-orange-500 transition-all p-0.5 bg-transparent"
                    onchange="handleColorChangeEdit(this)">
                <button type="button"
                    onclick="removeColorInputEdit(this, '${hexVal}')"
                    class="absolute -top-2 -right-2 w-5 h-5 bg-red-600 hover:bg-red-500 rounded-full text-white text-[10px] font-bold flex items-center justify-center shadow-lg border border-red-800 transition-colors">✕</button>
            `;
            list.appendChild(div);
            updateSkuColorDropdownsEdit();
        }

        function handleColorChangeEdit(inp) {
            const oldHex = inp.getAttribute('data-prev');
            const newHexRaw = inp.value;
            const newHex = '0xFF' + newHexRaw.replace('#', '').toUpperCase();
            
            // 1. Update SKUs local data
            if (editingProductData && editingProductData.skus) {
                editingProductData.skus.forEach(s => {
                    if (s.color_hex === oldHex) s.color_hex = newHex;
                });
            }
            
            // 2. Update Product Colors local data
            if (editingProductData && editingProductData.colors) {
                const cIdx = editingProductData.colors.findIndex(c => c.color_hex === oldHex);
                if (cIdx !== -1) editingProductData.colors[cIdx].color_hex = newHex;
                else editingProductData.colors.push({ color_hex: newHex });
            }

            // 3. Update Gallery local data (Automatic migration)
            if (editingProductData && editingProductData.gallery) {
                editingProductData.gallery.forEach(img => {
                    if (img.color_hex === oldHex) img.color_hex = newHex;
                });
            }

            // 4. Update data-prev for next change
            inp.setAttribute('data-prev', newHex);

            // 4. Update UI
            updateSkuColorDropdownsEdit();
            renderEditSkuList(editingProductData.skus);
            toast('Warna diperbarui secara lokal. Simpan varian untuk menerapkan ke database.', 'info');
        }

        function removeColorInputEdit(btnElement, hexVal) {
            const hexApi = '0xFF' + hexVal.replace('#', '').toUpperCase();
            const skusToDel = editingProductData.skus.filter(s => s.color_hex === hexApi);
            if (skusToDel.length > 0) {
                confirm2('Hapus Warna', `Hapus warna ini dan ${skusToDel.length} ukurannya?`, async () => {
                    let failed = 0;
                    for (const s of skusToDel) {
                        try {
                            const res = await fetch(`${API}/admin/skus/${s.id}`, { method: 'DELETE', headers: getAdminHeaders() });
                            if (!res.ok) failed++;
                        } catch { failed++; }
                    }
                    if (failed) toast(`Gagal hapus ${failed} varian`, 'warn');
                    else toast('Warna dan ukurannya dihapus');
                    
                    btnElement.parentElement.remove();
                    updateSkuColorDropdownsEdit();
                    await fetchProducts();
                    const p = allProducts.find(x => x.id === currentEditProductId);
                    if (p) {
                        editingProductData = p; // Synchronize local data
                        renderEditSkuList(p.skus);
                    }
                });
            } else {
                btnElement.parentElement.remove();
                updateSkuColorDropdownsEdit();
            }
        }

        function updateSkuColorDropdownsEdit() {
            const colors = Array.from(document.querySelectorAll('#edit-color-list .color-item input[type="color"]')).map(inp => '0xFF' + inp.value.replace('#', '').toUpperCase());
            const el = document.getElementById('new-sku-color');
            if (!el) return;
            const currentVal = el.value;
            el.innerHTML = '<option value="">Universal / Semua</option>';
            colors.forEach(c => {
                const opt = document.createElement('option');
                opt.value = c;
                opt.textContent = '⬤ ' + c.replace('0xFF', '#');
                opt.className = 'text-xs';
                el.appendChild(opt);
            });
            if (currentVal && colors.includes(currentVal)) el.value = currentVal;
        }
        function closeEditModal() {
            document.getElementById('edit-modal').classList.replace('flex', 'hidden');
            currentEditProductId = null;
        }

        function renderEditSkuList(skus) {
            const productColors = editingProductData.colors || [];
            const groups = new Map();

            // Grouping SKUs by color
            skus.forEach(sku => {
                const key = sku.color_hex || 'null';
                if (!groups.has(key)) {
                    groups.set(key, { color: sku.color_hex || null, skus: [] });
                }
                groups.get(key).skus.push(sku);
            });

            // Ensure all productColors are represented as headers even if empty
            productColors.forEach(c => {
                if (!groups.has(c.color_hex)) {
                    groups.set(c.color_hex, { color: c.color_hex, skus: [] });
                }
            });

            let html = '';
            groups.forEach((group) => {
                const colorHex = group.color ? group.color.replace('0xFF', '#') : null;
                const headerHtml = colorHex
                    ? `<div class="flex items-center gap-2">
                        <div style="background-color: ${colorHex}" class="w-3.5 h-3.5 rounded-full border border-gray-500 shadow-sm"></div>
                        <span class="text-xs font-bold text-gray-300">${colorHex}</span>
                       </div>`
                    : `<span class="text-xs font-bold text-gray-500">Universal (tanpa warna)</span>`;

                html += `
                <tr class="bg-gray-700/30">
                    <td colspan="4" class="py-1.5 px-2">${headerHtml}</td>
                </tr>`;

                group.skus.forEach(sku => {
                    html += `
                    <tr class="group hover:bg-white/[0.02] transition-colors">
                        <td class="py-2 pl-5">
                            <span class="text-xs font-bold text-gray-200">${sku.variant_name}</span>
                            <input type="hidden" id="edit-color-${sku.id}" value="${sku.color_hex || 'null'}">
                        </td>
                        <td class="py-2 pl-2">
                            <div class="bg-gray-900 border border-gray-700 rounded-lg px-2 py-0.5 inline-flex items-center gap-1">
                                <span class="text-[9px] text-gray-500 font-bold">Rp</span>
                                <input type="text" id="edit-price-${sku.id}" value="${sku.price}"
                                    class="w-16 bg-transparent text-[11px] text-white focus:outline-none font-bold">
                            </div>
                        </td>
                        <td class="py-2 pl-2">
                            <div class="bg-gray-900 border border-gray-700 rounded-lg px-2 py-0.5 inline-flex items-center gap-1">
                                <input type="number" id="edit-stock-${sku.id}" value="${sku.stock_available}" min="0"
                                    class="w-10 bg-transparent text-[11px] text-white text-center focus:outline-none font-bold">
                            </div>
                        </td>
                        <td class="py-2 pl-2 text-right">
                            <div class="flex gap-1 justify-end">
                                <button onclick="updateSkuFromEdit(${sku.id})" class="p-1.5 text-green-500 hover:bg-green-500/10 rounded-lg transition-all" title="Simpan">
                                    <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"></path></svg>
                                </button>
                                <button onclick="deleteSkuFromEdit(${sku.id}, '${sku.variant_name.replace(/'/g, "\\'")}')" class="p-1.5 text-red-500 hover:bg-red-500/10 rounded-lg transition-all" title="Hapus">
                                    <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M6 18L18 6M6 6l12 12"></path></svg>
                                </button>
                            </div>
                        </td>
                    </tr>`;
                });
            });

            document.getElementById('edit-sku-list').innerHTML = html;
        }

        async function updateSkuFromEdit(skuId) {
            const stock = document.getElementById(`edit-stock-${skuId}`).value;
            const price = document.getElementById(`edit-price-${skuId}`).value;
            const color = document.getElementById(`edit-color-${skuId}`).value;

            const params = new URLSearchParams({ stock, price, color_hex: color });

            try {
                const res = await fetch(`${API}/admin/skus/${skuId}?${params.toString()}`, { method: 'PUT', headers: getAdminHeaders() });
                if (res.ok) { 
                    toast('Detail varian diperbarui!'); 
                    await fetchProducts(); 
                    // Update local editingProductData and re-render
                    const p = allProducts.find(x => x.id === currentEditProductId);
                    if (p) {
                        editingProductData = p;
                        renderEditSkuList(p.skus);
                    }
                }
                else toast('Gagal update', 'error');
            } catch { toast('Koneksi gagal', 'error'); }
        }

        async function deleteSkuFromEdit(skuId, variantName) {
            confirm2('Hapus Varian', `Hapus ukuran "${variantName}"?`, async () => {
                try {
                    const res = await fetch(`${API}/admin/skus/${skuId}`, { method: 'DELETE', headers: getAdminHeaders() });
                    if (res.ok) {
                        toast('Varian dihapus');
                        await fetchProducts();
                        const p = allProducts.find(x => x.id === currentEditProductId);
                        if (p) {
                            editingProductData = p; // Synchronize local data
                            renderEditSkuList(p.skus);
                        }
                    } else toast('Gagal hapus varian', 'error');
                } catch { toast('Koneksi gagal', 'error'); }
            });
        }

        function showAddSkuInModal() {
            const wrap = document.getElementById('add-sku-in-modal');
            wrap.classList.remove('hidden');
            const p = allProducts.find(x => x.id === currentEditProductId);
            document.getElementById('new-sku-price').value = p ? p.price : '';
        }

        async function submitAddSkuInModal() {
            const name = document.getElementById('new-sku-name').value.trim();
            const color = document.getElementById('new-sku-color').value || null;
            const price = parsePrice(document.getElementById('new-sku-price').value);
            const stock = parseInt(document.getElementById('new-sku-stock').value) || 0;
            if (!name || !price) { toast('Nama dan harga wajib diisi', 'warn'); return; }
            try {
                const res = await fetch(`${API}/admin/products/${currentEditProductId}/skus`, {
                    method: 'POST', headers: getHeaders(),
                    body: JSON.stringify({ variant_name: name, color_hex: color, price, stock_available: stock, stock_reserved: 0 })
                });
                if (res.ok) {
                    toast(`Varian "${name}" ditambahkan!`);
                    document.getElementById('add-sku-in-modal').classList.add('hidden');
                    document.getElementById('new-sku-name').value = '';
                    await fetchProducts();
                    const p = allProducts.find(x => x.id === currentEditProductId);
                    if (p) {
                        editingProductData = p; // Synchronize local data
                        renderEditSkuList(p.skus);
                    }
                } else { const d = await res.json(); toast(d.detail || 'Gagal', 'error'); }
            } catch { toast('Koneksi gagal', 'error'); }
        }

        async function submitEditProduct() {
            let category = document.getElementById('edit-category').value;
            if (category === '__custom__') {
                category = document.getElementById('edit-custom-category').value.trim();
                if (!category) { toast('Nama kategori wajib diisi', 'warn'); return; }
            }

            // Collect colors
            const colors = Array.from(document.querySelectorAll('#edit-color-list .color-item input[type="color"]'))
                .map(inp => ({ color_hex: '0xFF' + inp.value.replace('#', '').toUpperCase() }));

            // Collect SKUs (Variations) from the table
            const skus = [];
            document.querySelectorAll('#edit-sku-list tr.group').forEach(row => {
                const id = row.querySelector('button[onclick*="updateSkuFromEdit"]').getAttribute('onclick').match(/\d+/)[0];
                const vName = row.querySelector('span.font-bold.text-gray-200').textContent.trim();
                const vColor = row.querySelector(`input[id="edit-color-${id}"]`).value;
                const vPrice = parseFloat(row.querySelector(`input[id="edit-price-${id}"]`).value);
                const vStock = parseInt(row.querySelector(`input[id="edit-stock-${id}"]`).value);
                
                skus.push({ 
                    id: parseInt(id),
                    variant_name: vName,
                    color_hex: vColor !== 'null' ? vColor : null,
                    price: vPrice,
                    stock_available: vStock
                });
            });

            const payload = {
                name: document.getElementById('edit-name').value.trim(),
                price: parsePrice(document.getElementById('edit-price').value),
                description: document.getElementById('edit-description').value.trim(),
                specification: document.getElementById('edit-specification').value.trim(),
                category,
                colors,
                skus,
                gallery: editingProductData.gallery ? editingProductData.gallery.map(img => ({
                    id: img.id,
                    color_hex: img.color_hex
                })) : []
            };
            if (!payload.name || !payload.price) { toast('Nama dan harga wajib diisi', 'warn'); return; }
            try {
                const res = await fetch(`${API}/admin/products/${currentEditProductId}`, {
                    method: 'PUT', headers: getHeaders(), body: JSON.stringify(payload)
                });
                if (res.ok) {
                    toast('Produk diperbarui!');
                    // Save category if new
                    const cats = getCategories();
                    if (!cats.includes(category)) { cats.push(category); saveCategories(cats); populateCategorySelects(); }
                    closeEditModal();
                    fetchProducts();
                } else { const d = await res.json(); toast(d.detail || 'Gagal update', 'error'); }
            } catch { toast('Koneksi gagal', 'error'); }
        }

        // ═══════════════════════════════════════════════════════════
        // USERS
        // ═══════════════════════════════════════════════════════════
        async function fetchUsers() {
            try {
                const res = await fetch(`${API}/admin/users`, { headers: getAdminHeaders() });
                if (!res.ok) throw new Error();
                allUsers = await res.json();
                renderUsersFiltered();
            } catch {
                document.getElementById('users-table-body').innerHTML =
                    '<tr><td colspan="5" class="px-5 py-10 text-center text-red-500 text-sm">Gagal memuat pengguna.</td></tr>';
            }
        }

        function renderUsersFiltered() {
            const search = (document.getElementById('users-search')?.value || '').toLowerCase();
            let list = allUsers;
            if (search) list = list.filter(u => u.username.toLowerCase().includes(search) || u.email.toLowerCase().includes(search));
            renderUsers(list);
        }

        function renderUsers(users) {
            // Stats
            document.getElementById('user-stat-total').textContent = allUsers.length;
            const ordered = allUsers.filter(u => u.order_count > 0).length;
            document.getElementById('user-stat-ordered').textContent = ordered;
            const totalSpent = allUsers.reduce((s, u) => s + (u.total_spent || 0), 0);
            document.getElementById('user-stat-spent').textContent = fmtRp(totalSpent);

            const tbody = document.getElementById('users-table-body');
            if (!users.length) {
                tbody.innerHTML = '<tr><td colspan="5" class="px-5 py-10 text-center text-gray-600 text-sm">Tidak ada pengguna.</td></tr>';
                return;
            }
            tbody.innerHTML = users.map(u => `
        <tr class="border-b border-gray-800 hover:bg-gray-800/30 transition fade-in">
            <td class="px-5 py-3 text-xs text-gray-500 font-mono">#${u.id}</td>
            <td class="px-5 py-3">
                <div class="flex items-center gap-2.5">
                    ${u.profile_image
                    ? `<img src="${u.profile_image.startsWith('http') ? u.profile_image : API + '/' + u.profile_image}" class="w-8 h-8 rounded-full object-cover bg-gray-800 flex-shrink-0" onerror="this.style.display='none'">`
                    : `<div class="w-8 h-8 rounded-full bg-gray-700 flex-shrink-0 flex items-center justify-center text-xs text-gray-400 font-bold">${u.username[0].toUpperCase()}</div>`}
                    <span class="text-sm font-semibold text-white">${u.username}</span>
                </div>
            </td>
            <td class="px-5 py-3 text-sm text-gray-400">${u.email}</td>
            <td class="px-5 py-3 text-center">
                <span class="text-sm font-bold ${u.order_count > 0 ? 'text-orange-400' : 'text-gray-600'}">${u.order_count}</span>
            </td>
            <td class="px-5 py-3 text-right text-sm font-semibold ${u.total_spent > 0 ? 'text-orange-300' : 'text-gray-600'}">${fmtRp(u.total_spent || 0)}</td>
            <td class="px-5 py-3 text-center">
                <button onclick="doDeleteUser(${u.id})" class="bg-red-900/40 hover:bg-red-700 text-red-500 px-3 py-1.5 rounded-lg text-xs font-bold transition-colors">🗑 Hapus</button>
            </td>
        </tr>`).join('');
        }

        // ═══════════════════════════════════════════════════════════
        // PAYMENT CONFIG / SETTINGS
        // ═══════════════════════════════════════════════════════════
        async function fetchPaymentConfig() {
            try {
                const res = await fetch(`${API}/payment-config`);
                if (!res.ok) return;
                const cfg = await res.json();
                document.getElementById('tf-bank-name').value = cfg.tf_bank_name || '';
                document.getElementById('tf-account-number').value = cfg.tf_account_number || '';
                document.getElementById('tf-account-holder').value = cfg.tf_account_holder || '';
                if (cfg.qris_image) {
                    const wrap = document.getElementById('qris-current-wrap');
                    const img = document.getElementById('qris-current-img');
                    img.src = cfg.qris_image.startsWith('http') ? cfg.qris_image : API + cfg.qris_image;
                    wrap.classList.remove('hidden');
                }
            } catch (e) { console.error('fetchPaymentConfig', e); }
        }

        async function saveTfConfig() {
            const payload = {
                tf_bank_name: document.getElementById('tf-bank-name').value.trim(),
                tf_account_number: document.getElementById('tf-account-number').value.trim(),
                tf_account_holder: document.getElementById('tf-account-holder').value.trim(),
            };
            try {
                const res = await fetch(`${API}/admin/payment-config`, {
                    method: 'PUT', headers: getHeaders(), body: JSON.stringify(payload)
                });
                if (res.ok) { toast('Info TF berhasil disimpan ✓'); }
                else { const d = await res.json(); toast(d.detail || 'Gagal simpan', 'error'); }
            } catch (e) { toast('Error: ' + e.message, 'error'); }
        }

        function previewQris(input) {
            const file = input.files[0];
            if (!file) return;
            const reader = new FileReader();
            reader.onload = e => {
                document.getElementById('qris-preview-img').src = e.target.result;
                document.getElementById('qris-preview-wrap').classList.remove('hidden');
                document.getElementById('qris-upload-btn').disabled = false;
            };
            reader.readAsDataURL(file);
        }

        async function uploadQris() {
            const file = document.getElementById('qris-file-input').files[0];
            if (!file) return;
            const form = new FormData();
            form.append('file', file);
            const btn = document.getElementById('qris-upload-btn');
            btn.disabled = true; btn.textContent = 'Mengupload...';
            try {
                const res = await fetch(`${API}/admin/payment-config/qris`, {
                    method: 'POST',
                    headers: getAdminHeaders(), // Uses standardized headers with correct key
                    body: form
                });
                if (res.ok) {
                    const d = await res.json();
                    const img = document.getElementById('qris-current-img');
                    img.src = d.url.startsWith('http') ? d.url : API + d.url;
                    document.getElementById('qris-current-wrap').classList.remove('hidden');
                    document.getElementById('qris-preview-wrap').classList.add('hidden');
                    document.getElementById('qris-file-input').value = '';
                    toast('QRIS berhasil diupload ✓');
                } else { const d = await res.json(); toast(d.detail || 'Gagal upload', 'error'); }
            } catch (e) { toast('Error: ' + e.message, 'error'); }
            finally { btn.disabled = false; btn.textContent = 'Upload QRIS Baru'; }
        }

        // ═══════════════════════════════════════════════════════════
        // INIT
        // ═══════════════════════════════════════════════════════════
        populateCategorySelects();
        initSkuRows();
        switchTab('dashboard');

        // ── Promo Management (Banners) ─────────────────────────────
        async function fetchAdminPromos() {
            try {
                const r = await fetch(API + '/promos');
                const data = await r.json();
                
                // Reset select all checkbox
                const selectAll = document.getElementById('promo-select-all');
                if (selectAll) selectAll.checked = false;
                
                renderAdminPromos(data);
                updatePromoSelectedCount();
            } catch (e) {
                console.error("fetchPromos error", e);
                document.getElementById('promo-list').innerHTML = `<p class="col-span-full py-4 text-center text-red-400 text-xs italic">Gagal memuat banner</p>`;
            }
        }

        function renderAdminPromos(promos) {
            const list = document.getElementById('promo-list');
            if (promos.length === 0) {
                list.innerHTML = `<div class="col-span-full py-10 text-center"><p class="text-gray-500 text-xs italic">Belum ada banner aktif</p></div>`;
                return;
            }

            list.innerHTML = promos.map(p => `
                <div class="relative group bg-gray-800 rounded-lg overflow-hidden border border-gray-700 shadow-sm aspect-video">
                    <img src="${fixImageUrl(p.image_url)}" class="w-full h-full object-cover">
                    
                    <!-- Selection Checkbox -->
                    <div class="absolute top-2 left-2 z-20">
                        <input type="checkbox" data-promo-id="${p.id}" onchange="updatePromoSelectedCount()" 
                               class="promo-checkbox w-5 h-5 rounded-md bg-black/40 border-white/20 text-orange-500 focus:ring-orange-500/20 cursor-pointer backdrop-blur-sm transition-all hover:scale-110">
                    </div>

                    <div class="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition flex items-center justify-center gap-2">
                        <button onclick="deletePromo(${p.id})" class="w-8 h-8 rounded-full bg-red-500/80 hover:bg-red-500 text-white flex items-center justify-center transition">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                            </svg>
                        </button>
                    </div>
                </div>
            `).join('');
        }

        function toggleSelectAllPromos(inp) {
            const checkboxes = document.querySelectorAll('.promo-checkbox');
            checkboxes.forEach(cb => cb.checked = inp.checked);
            updatePromoSelectedCount();
        }

        function updatePromoSelectedCount() {
            const checkboxes = document.querySelectorAll('.promo-checkbox');
            const selected = Array.from(checkboxes).filter(cb => cb.checked);
            const countEl = document.getElementById('promo-selected-count');
            const actionsBar = document.getElementById('promo-bulk-actions');
            
            if (countEl) countEl.textContent = selected.length;
            if (actionsBar) {
                if (checkboxes.length > 0) actionsBar.classList.remove('hidden');
                else actionsBar.classList.add('hidden');
            }
            
            // Sync the master checkbox
            const master = document.getElementById('promo-select-all');
            if (master && checkboxes.length > 0) {
                master.checked = (selected.length === checkboxes.length);
            }
        }

        async function deleteSelectedPromos() {
            const selected = Array.from(document.querySelectorAll('.promo-checkbox:checked')).map(cb => cb.dataset.promoId);
            if (selected.length === 0) return;

            confirm2('Hapus Banner Terpilih?', `${selected.length} banner akan dihapus dari slider home secara permanen.`, async () => {
                try {
                    toast(`Sedang menghapus ${selected.length} banner...`, 'info');
                    let successCount = 0;
                    
                    for (const id of selected) {
                        try {
                            const r = await fetch(API + '/admin/promos/' + id, {
                                method: 'DELETE',
                                headers: getAdminHeaders()
                            });
                            if (r.ok) successCount++;
                        } catch (e) {
                            console.error(`Error deleting promo ${id}`, e);
                        }
                    }

                    if (successCount > 0) {
                        toast(`${successCount} banner berhasil dihapus`);
                        fetchAdminPromos();
                    } else {
                        toast('Gagal menghapus banner', 'error');
                    }
                } catch (e) {
                    toast('Terjadi kesalahan saat menghapus', 'error');
                }
            });
        }

        async function uploadPromo(inp) {
            if (!inp.files || inp.files.length === 0) return;
            const files = Array.from(inp.files);
            const fd = new FormData();
            files.forEach(f => fd.append('files', f));

            try {
                toast(`Sedang mengupload ${files.length} banner...`, 'info');
                const r = await fetch(API + '/admin/promos', {
                    method: 'POST',
                    headers: getAdminHeaders(),
                    body: fd
                });
                if (r.ok) {
                    toast(`${files.length} Banner berhasil ditambahkan`);
                    fetchAdminPromos();
                } else {
                    const data = await r.json();
                    toast(data.detail || 'Gagal tambah banner', 'error');
                }
            } catch (e) {
                toast('Gagal upload banner', 'error');
            } finally {
                inp.value = '';
            }
        }


        function deletePromo(id) {
            confirm2('Hapus Banner?', 'Gambar ini akan dihapus dari slider home.', async () => {
                try {
                    const r = await fetch(API + '/admin/promos/' + id, {
                        method: 'DELETE',
                        headers: getAdminHeaders()
                    });
                    if (r.ok) {
                        toast('Banner dihapus');
                        fetchAdminPromos();
                    } else {
                        const data = await r.json();
                        toast(data.detail || 'Gagal hapus banner', 'error');
                    }
                } catch (e) {
                    toast('Gagal menghapus banner', 'error');
                }
            });
        }
