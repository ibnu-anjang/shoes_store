        const API = window.location.origin;

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
            else if (tab === 'settings') fetchPaymentConfig();
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

                let actions = '';
                if (o.status === 'VERIFYING') {
                    actions = `
                <button onclick="doUpdateStatus('${o.id}','PAID')" class="bg-green-700/50 hover:bg-green-600 text-green-300 px-2.5 py-1 rounded-lg text-xs font-bold mr-1">✓ Setujui</button>
                <button onclick="doUpdateStatus('${o.id}','REJECTED')" class="bg-red-900/50 hover:bg-red-700 text-red-400 px-2.5 py-1 rounded-lg text-xs font-bold mr-1">✕ Tolak</button>`;
                } else if (o.status === 'PAID') {
                    actions = `<button onclick="doShip('${o.id}')" class="bg-blue-700/50 hover:bg-blue-600 text-blue-300 px-2.5 py-1 rounded-lg text-xs font-bold mr-1">📦 Kirim</button>`;
                } else if (o.status === 'SHIPPED') {
                    actions = `<button onclick="doUpdateStatus('${o.id}','DELIVERED')" class="bg-purple-700/50 hover:bg-purple-600 text-purple-300 px-2.5 py-1 rounded-lg text-xs font-bold mr-1">✅ Selesai</button>`;
                } else if (o.status === 'UNPAID') {
                    actions = `
                <button onclick="doUpdateStatus('${o.id}','PAID')" class="bg-green-700/50 hover:bg-green-600 text-green-300 px-2.5 py-1 rounded-lg text-xs font-bold mr-1">✓ Proses</button>
                <button onclick="doUpdateStatus('${o.id}','CANCELLED')" class="bg-gray-700 hover:bg-gray-600 text-gray-400 px-2.5 py-1 rounded-lg text-xs font-bold mr-1">Batal</button>`;
                }
                
                actions += `<button onclick="doDeleteOrder('${o.id}')" class="bg-red-900/40 hover:bg-red-700 text-red-500 px-2.5 py-1 rounded-lg text-xs font-bold mt-1 block w-max">🗑 Hapus</button>`;


                // Order items for expandable detail
                const itemsHtml = o.items && o.items.length ? o.items.map(item => `
            <div class="flex items-center gap-3 py-1">
                ${item.product_image ? `<img src="${item.product_image.startsWith('http') ? item.product_image : API + '/' + item.product_image}" class="w-8 h-8 rounded-lg object-cover bg-gray-800 flex-shrink-0" onerror="this.style.display='none'">` : '<div class="w-8 h-8 rounded-lg bg-gray-800 flex-shrink-0"></div>'}
                <div class="flex-1 min-w-0">
                    <p class="text-xs font-semibold text-gray-200 truncate">${item.product_name || 'Produk dihapus'}</p>
                    <p class="text-[11px] text-gray-500">
                        ${item.variant_name || '—'} × ${item.quantity}
                        ${item.color_hex ? `| <span class="inline-block w-2.5 h-2.5 rounded-full border border-gray-600 align-middle ml-1" style="background-color: ${item.color_hex}"></span> ${item.color_hex}` : ''}
                    </p>
                </div>
                <span class="text-xs font-semibold text-orange-300 flex-shrink-0">${fmtRp(item.price_at_checkout * item.quantity)}</span>
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
                <td colspan="8" class="bg-gray-800/50 border-b border-gray-800 px-8 py-4">
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <p class="text-xs font-bold text-gray-400 uppercase mb-2">Item Pesanan (${o.items?.length || 0})</p>
                            <div class="space-y-0.5">${itemsHtml}</div>
                        </div>
                        <div class="space-y-2">
                            <div>
                                <p class="text-xs font-bold text-gray-400 uppercase mb-1">Alamat Pengiriman</p>
                                <p class="text-sm text-gray-300">${o.shipping_address || '—'}</p>
                            </div>
                            <div>
                                <p class="text-xs font-bold text-gray-400 uppercase mb-1">Telepon</p>
                                <p class="text-sm text-gray-300">${o.phone || '—'}</p>
                            </div>
                            <div>
                                <p class="text-xs font-bold text-gray-400 uppercase mb-1">Metode Bayar</p>
                                <p class="text-sm text-gray-300">${o.payment_method || '—'}</p>
                            </div>
                            <div>
                                <p class="text-xs font-bold text-gray-400 uppercase mb-1">Kode Unik</p>
                                <p class="text-sm text-gray-300">+Rp ${o.unique_code}</p>
                            </div>
                            ${o.tracking_number ? `<div><p class="text-xs font-bold text-gray-400 uppercase mb-1">No. Resi</p><p class="text-sm font-semibold text-blue-300">${o.tracking_number}</p></div>` : ''}
                            ${o.expired_at ? `<div><p class="text-xs font-bold text-gray-400 uppercase mb-1">Expired</p><p class="text-xs text-gray-500">${fmtDate(o.expired_at)}</p></div>` : ''}
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
            const colors = colorInputs.map(inp => '0xFF' + inp.value.replace('#', '').toUpperCase());
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
                const imgUrl = p.image ? (p.image.startsWith('http') ? p.image : `${API}/${p.image}`) : '';
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
                const res = await fetch(`${API}/admin/skus/${skuId}/stock?stock=${val}`, { method: 'PUT', headers: getAdminHeaders() });
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
        function openPhotoModal(productId, productName) {
            currentPhotoProductId = productId;
            document.getElementById('photo-product-name').textContent = productName;
            document.getElementById('photo-file-input').value = '';
            document.getElementById('photo-preview-wrap').classList.add('hidden');
            document.getElementById('photo-submit-btn').disabled = true;
            const m = document.getElementById('photo-modal');
            m.classList.remove('hidden'); m.classList.add('flex');
        }
        function closePhotoModal() {
            document.getElementById('photo-modal').classList.replace('flex', 'hidden');
            currentPhotoProductId = null;
        }
        function previewPhoto(input) {
            const files = input.files;
            const wrap = document.getElementById('photo-preview-wrap');
            wrap.innerHTML = '';
            if (!files.length) { wrap.classList.add('hidden'); return; }

            wrap.classList.remove('hidden');
            document.getElementById('photo-submit-btn').disabled = false;

            Array.from(files).forEach(file => {
                const reader = new FileReader();
                reader.onload = e => {
                    const img = document.createElement('img');
                    img.src = e.target.result;
                    img.className = 'w-20 h-20 rounded-lg object-cover border border-gray-700';
                    wrap.appendChild(img);
                };
                reader.readAsDataURL(file);
            });
        }
        async function submitPhoto() {
            const files = document.getElementById('photo-file-input').files;
            if (!files.length || !currentPhotoProductId) return;
            const btn = document.getElementById('photo-submit-btn');
            btn.disabled = true; btn.textContent = 'Mengupload...';

            // Upload thumbnail (first image) and gallery (all images)
            try {
                const fd = new FormData();
                fd.append('file', files[0]);
                // Update main image
                const mainRes = await fetch(`${API}/admin/products/${currentPhotoProductId}/image`, {
                    method: 'POST', headers: getAdminHeaders(), body: fd
                });

                // If multiple, upload to gallery too
                if (files.length > 1) {
                    const fdG = new FormData();
                    for (let i = 0; i < files.length; i++) fdG.append('files', files[i]);
                    await fetch(`${API}/admin/products/${currentPhotoProductId}/gallery`, {
                        method: 'POST', headers: getAdminHeaders(), body: fdG
                    });
                }

                toast('Foto berhasil diupdate & galeri ditambahkan!');
                closePhotoModal(); fetchProducts();
            } catch (e) { toast('Error upload: ' + e.message, 'error'); }
            finally { btn.disabled = false; btn.textContent = 'Upload Foto'; }
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
            div.innerHTML = `
                <input type="color" value="${hexVal}"
                    class="w-12 h-12 rounded-xl cursor-pointer border-2 border-gray-600 hover:border-orange-500 transition-all p-0.5 bg-transparent"
                    onchange="updateSkuColorDropdownsEdit()">
                <button type="button"
                    onclick="this.parentElement.remove(); updateSkuColorDropdownsEdit();"
                    class="absolute -top-2 -right-2 w-5 h-5 bg-red-600 hover:bg-red-500 rounded-full text-white text-[10px] font-bold flex items-center justify-center shadow-lg border border-red-800 transition-colors">✕</button>
            `;
            list.appendChild(div);
            updateSkuColorDropdownsEdit();
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
                if (res.ok) { toast('Detail varian diperbarui!'); fetchProducts(); }
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

            const payload = {
                name: document.getElementById('edit-name').value.trim(),
                price: parsePrice(document.getElementById('edit-price').value),
                description: document.getElementById('edit-description').value.trim(),
                specification: document.getElementById('edit-specification').value.trim(),
                category,
                colors
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
