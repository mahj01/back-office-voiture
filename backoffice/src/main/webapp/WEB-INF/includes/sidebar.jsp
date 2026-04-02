<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String ctx = request.getContextPath();
    String uri = request.getRequestURI();
%>
<!-- Sidebar Navigation -->
<nav id="sidebar">
    <div class="sidebar-header">
        <a href="<%= ctx %>/" class="sidebar-brand">
            <i class="bi bi-speedometer2"></i>
            <b>3344 - 3275 - 3342</b>
        </a>
    </div>
    <ul class="sidebar-nav">
        <!-- Voiture -->
        <li class="nav-section<%= uri.contains("/voiture") ? " active" : "" %>">
            <a href="#voitureMenu" class="nav-link section-toggle" data-bs-toggle="collapse"
               aria-expanded="<%= uri.contains("/voiture") ? "true" : "false" %>">
                <i class="bi bi-car-front-fill"></i>
                <span>Voitures</span>
                <i class="bi bi-chevron-down toggle-icon"></i>
            </a>
            <ul class="collapse<%= uri.contains("/voiture") ? " show" : "" %>" id="voitureMenu">
                <li><a href="<%= ctx %>/voiture/liste" class="<%= uri.contains("voitureList") || uri.endsWith("/voiture/liste") ? "active" : "" %>">
                    <i class="bi bi-list-ul"></i> Liste
                </a></li>
                <li><a href="<%= ctx %>/voiture/saisie" class="<%= uri.contains("createVoiture") || uri.endsWith("/voiture/saisie") ? "active" : "" %>">
                    <i class="bi bi-plus-circle"></i> Créer
                </a></li>
            </ul>
        </li>
        <!-- Reservation -->
        <li class="nav-section<%= uri.contains("/reservation") || uri.contains("Reservation") ? " active" : "" %>">
            <a href="#reservationMenu" class="nav-link section-toggle" data-bs-toggle="collapse"
               aria-expanded="<%= uri.contains("/reservation") || uri.contains("Reservation") ? "true" : "false" %>">
                <i class="bi bi-calendar-check"></i>
                <span>Réservations</span>
                <i class="bi bi-chevron-down toggle-icon"></i>
            </a>
            <ul class="collapse<%= uri.contains("/reservation") || uri.contains("Reservation") ? " show" : "" %>" id="reservationMenu">
                <li><a href="<%= ctx %>/reservation/saisie" class="<%= uri.contains("createReservation") || uri.endsWith("/reservation/saisie") ? "active" : "" %>">
                    <i class="bi bi-plus-circle"></i> Créer
                </a></li>
            </ul>
        </li>
        <!-- Assignation -->
        <li class="nav-section<%= uri.contains("/assignation") ? " active" : "" %>">
            <a href="#assignationMenu" class="nav-link section-toggle" data-bs-toggle="collapse"
               aria-expanded="<%= uri.contains("/assignation") ? "true" : "false" %>">
                <i class="bi bi-arrow-left-right"></i>
                <span>Assignation</span>
                <i class="bi bi-chevron-down toggle-icon"></i>
            </a>
            <ul class="collapse<%= uri.contains("/assignation") ? " show" : "" %>" id="assignationMenu">
                <li><a href="<%= ctx %>/assignation/saisie" class="<%= uri.endsWith("/assignation/saisie") ? "active" : "" %>">
                    <i class="bi bi-calendar-plus"></i> Saisie
                </a></li>
                <li><a href="<%= ctx %>/assignation/resultatStatique.jsp" class="<%= uri.contains("resultatStatique") ? "active" : "" %>">
                    <i class="bi bi-braces"></i> Résultats
                </a></li>
            </ul>
        </li>
    </ul>
</nav>

<style>
/* ── Sidebar ─────────────────────────────────── */
#sidebar {
    position: fixed;
    top: 0;
    left: 0;
    width: 250px;
    height: 100vh;
    background: #fff;
    box-shadow: 3px 0 10px rgba(0,0,0,0.06);
    border-right: 2px solid #4a90d9;
    z-index: 1000;
    overflow-y: auto;
    transition: transform 0.3s;
}

.sidebar-header {
    padding: 20px 16px 12px;
    border-bottom: 1px solid #e9ecef;
}
.sidebar-brand {
    font-size: 18px;
    font-weight: 700;
    color: #1a56db;
    text-decoration: none;
    display: flex;
    align-items: center;
    gap: 8px;
}
.sidebar-brand:hover { color: #0d3b9e; }

.sidebar-nav {
    list-style: none;
    padding: 12px 0;
    margin: 0;
}

/* Section parent */
.nav-section { border-left: 3px solid transparent; }
.nav-section.active { border-left-color: #4a90d9; }
.nav-section > .nav-link {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 12px 16px;
    color: #333;
    text-decoration: none;
    font-weight: 600;
    font-size: 14px;
    transition: background 0.15s;
}
.nav-section > .nav-link:hover { background: #f0f4ff; }
.nav-section > .nav-link .toggle-icon {
    margin-left: auto;
    font-size: 12px;
    transition: transform 0.2s;
}
.nav-section > .nav-link[aria-expanded="true"] .toggle-icon {
    transform: rotate(180deg);
}

/* Sub-items */
.nav-section ul {
    list-style: none;
    padding: 0;
    margin: 0;
}
.nav-section ul li a {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 9px 16px 9px 42px;
    color: #555;
    text-decoration: none;
    font-size: 13px;
    transition: background 0.15s, color 0.15s;
}
.nav-section ul li a:hover {
    background: #f0f4ff;
    color: #1a56db;
}
.nav-section ul li a.active {
    color: #1a56db;
    background: #e8f0fe;
    font-weight: 600;
}

/* ── Main content shift ──────────────────────── */
.main-content {
    margin-left: 250px;
    min-height: 100vh;
    padding: 24px;
    background: #f5f5f5;
}

/* ── Mobile burger ───────────────────────────── */
.sidebar-toggle {
    display: none;
    position: fixed;
    top: 12px;
    left: 12px;
    z-index: 1100;
    background: #fff;
    border: 1px solid #ddd;
    border-radius: 6px;
    padding: 6px 10px;
    font-size: 20px;
    cursor: pointer;
    box-shadow: 0 2px 6px rgba(0,0,0,0.08);
}
@media (max-width: 768px) {
    #sidebar { transform: translateX(-100%); }
    #sidebar.show { transform: translateX(0); }
    .sidebar-toggle { display: block; }
    .main-content { margin-left: 0; }
    .sidebar-overlay {
        display: none;
        position: fixed;
        inset: 0;
        background: rgba(0,0,0,0.3);
        z-index: 999;
    }
    .sidebar-overlay.show { display: block; }
}
</style>

<!-- Mobile toggle button -->
<button class="sidebar-toggle" onclick="toggleSidebar()">
    <i class="bi bi-list"></i>
</button>
<div class="sidebar-overlay" onclick="toggleSidebar()"></div>

<script>
function toggleSidebar() {
    document.getElementById('sidebar').classList.toggle('show');
    document.querySelector('.sidebar-overlay').classList.toggle('show');
}
</script>
