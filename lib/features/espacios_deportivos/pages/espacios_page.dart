import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'detalle_espacio_deportivo.dart';
import 'package:flutterapp/config.dart';

class ListaEspaciosDeportivosPage extends StatefulWidget {
  const ListaEspaciosDeportivosPage({super.key});

  @override
  _ListaEspaciosDeportivosPageState createState() =>
      _ListaEspaciosDeportivosPageState();
}

class _ListaEspaciosDeportivosPageState
    extends State<ListaEspaciosDeportivosPage> {
  List<dynamic> espacios = [];
  List<dynamic> espaciosFiltrados = [];
  bool isLoading = true;
  bool hasError = false;
  String baseUrl = Config.baseUrl;
  TextEditingController searchController = TextEditingController();
  String _filtroActivo = 'Todos';

  final Color _primaryDeep = const Color(0xFF19382F);

  final List<Map<String, dynamic>> _filtros = [
    {'label': 'Todos', 'icon': Icons.apps_rounded},
    {'label': 'Fútbol', 'icon': Icons.sports_soccer},
    {'label': 'Voley', 'icon': Icons.sports_volleyball},
    {'label': 'Tenis', 'icon': Icons.sports_tennis},
    {'label': 'Básquet', 'icon': Icons.sports_basketball},
  ];

  @override
  void initState() {
    super.initState();
    obtenerEspaciosDeportivos();
  }

  Future<void> obtenerEspaciosDeportivos() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/espacio/espacios-deportivos'));
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (mounted) {
          setState(() {
            if (decodedData is List) {
              espacios = decodedData;
            } else if (decodedData is Map &&
                decodedData.containsKey('data')) {
              espacios = decodedData['data'];
            } else {
              hasError = true;
            }
            espaciosFiltrados = List.from(espacios);
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() { hasError = true; isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { hasError = true; isLoading = false; });
    }
  }

  void filtrarEspacios(String query) {
    setState(() {
      espaciosFiltrados = espacios
          .where((e) => e['nombre']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  void _aplicarFiltro(String filtro) {
    setState(() {
      _filtroActivo = filtro;
      espaciosFiltrados = filtro == 'Todos'
          ? List.from(espacios)
          : espacios
              .where((e) =>
                  (e['deportes'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(filtro.toLowerCase()) ||
                  (e['nombre'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(filtro.toLowerCase()))
              .toList();
    });
  }

  Future<void> guardarEspacioSeleccionado(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('espacio_id', id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildPremiumHeader(),
          _buildSearchBar(),
          _buildFiltros(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────
  Widget _buildPremiumHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Fila 1: Icono recargar ──
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Material(
                    color: _primaryDeep.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: obtenerEspaciosDeportivos,
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          Icons.refresh_rounded,
                          size: 22,
                          color: _primaryDeep,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ── Fila 2: Icono + Título ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _primaryDeep.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.explore_rounded,
                      size: 24,
                      color: _primaryDeep,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Explorar',
                    style: GoogleFonts.sansita(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: _primaryDeep,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // ── Fila 3: Descripción ──
              Text(
                'Encuentra espacios en Loja',
                style: GoogleFonts.sansita(
                  fontSize: 16,
                  color: _primaryDeep.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── BUSCADOR ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: _primaryDeep.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _primaryDeep.withValues(alpha: 0.08)),
        ),
        child: TextField(
          controller: searchController,
          onChanged: filtrarEspacios,
          style: GoogleFonts.sansita(fontSize: 15, color: _primaryDeep),
          decoration: InputDecoration(
            hintText: "Buscar espacios deportivos...",
            hintStyle: GoogleFonts.sansita(
                color: _primaryDeep.withValues(alpha: 0.35), fontSize: 15),
            prefixIcon:
                Icon(Icons.search_rounded, color: _primaryDeep.withValues(alpha: 0.5)),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
        ),
      ),
    );
  }

  // ── FILTROS ───────────────────────────────────────────────────────────────
  Widget _buildFiltros() {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: _filtros.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filtro = _filtros[index];
          final isActive = _filtroActivo == filtro['label'];
          return GestureDetector(
            onTap: () => _aplicarFiltro(filtro['label']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? _primaryDeep : _primaryDeep.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    filtro['icon'] as IconData,
                    size: 15,
                    color: isActive
                        ? Colors.white
                        : _primaryDeep.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filtro['label'],
                    style: GoogleFonts.sansita(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? Colors.white
                          : _primaryDeep.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── BODY ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Error al cargar espacios",
                style: GoogleFonts.sansita(fontSize: 16, color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: obtenerEspaciosDeportivos,
                child: const Text("Reintentar")),
          ],
        ),
      );
    }
    if (espaciosFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64, color: _primaryDeep.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text("No se encontraron espacios",
                style: GoogleFonts.sansita(
                    fontSize: 16,
                    color: _primaryDeep.withValues(alpha: 0.4))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: espaciosFiltrados.length,
      itemBuilder: (context, index) {
        final espacio = espaciosFiltrados[index];
        final imageUrl =
            (espacio['imagen'] != null &&
                    espacio['imagen'].toString().startsWith('http'))
                ? espacio['imagen']
                : 'https://img.freepik.com/foto-gratis/vista-cancha-futbol-iluminacion_23-2150888562.jpg';

        return GestureDetector(
          onTap: () async {
            await guardarEspacioSeleccionado(espacio['_id'] ?? '');
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      DetalleEspacioDeportivoPage(espacio: espacio)),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: _primaryDeep.withValues(alpha: 0.07)),
              boxShadow: [
                BoxShadow(
                  color: _primaryDeep.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Imagen con badge ──
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24)),
                      child: Image.network(
                        imageUrl,
                        height: 175,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Badge disponible
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Disponible',
                              style: GoogleFonts.sansita(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Info ──
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              espacio['nombre'] ?? "Espacio Deportivo",
                              style: GoogleFonts.sansita(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _primaryDeep,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 14, color: Colors.orange),
                                const SizedBox(width: 3),
                                Text(
                                  '4.8',
                                  style: GoogleFonts.sansita(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 14,
                              color: _primaryDeep.withValues(alpha: 0.45)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              espacio['ubicacion'] ?? "Ubicación",
                              style: GoogleFonts.sansita(
                                fontSize: 13,
                                color: _primaryDeep.withValues(alpha: 0.45),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // ── Chips deportes + flecha ──
                      Row(
                        children: [
                          _buildAmenityChip(
                              Icons.sports_soccer, "Fútbol"),
                          const SizedBox(width: 8),
                          _buildAmenityChip(
                              Icons.sports_volleyball, "Voley"),
                          const Spacer(),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _primaryDeep,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmenityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _primaryDeep.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: _primaryDeep.withValues(alpha: 0.7)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.sansita(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _primaryDeep.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
