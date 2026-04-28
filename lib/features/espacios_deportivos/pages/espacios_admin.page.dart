import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'detalle_espacio_deportivo.dart';
import 'package:flutterapp/core/routes/routes.dart';
import 'package:flutterapp/config.dart';

class ListaEspaciosAdminDeportivosPage extends StatefulWidget {
  const ListaEspaciosAdminDeportivosPage({super.key});

  @override
  _ListaEspaciosDeportivosPageState createState() =>
      _ListaEspaciosDeportivosPageState();
}

class _ListaEspaciosDeportivosPageState
    extends State<ListaEspaciosAdminDeportivosPage> {
  List<dynamic> espacios = [];
  bool isLoading = true;
  bool hasError = false;
  String baseUrl = Config.baseUrl;
  String? _userRol;

  final Color _primaryDeep = const Color(0xFF19382F);

  final List<Map<String, dynamic>> _resenasMock = [
    {
      "autor": "Juan Pérez",
      "opinion":
          "Excelente servicio, la app es rápida y muy confiable para reservar.",
      "rating": 5
    },
    {
      "autor": "Rosa Gonzales",
      "opinion":
          "Reservar en línea nunca fue tan fácil. Totalmente recomendada.",
      "rating": 4
    },
    {
      "autor": "Carlos Ruiz",
      "opinion": "Las canchas están en muy buen estado y la atención es buena.",
      "rating": 5
    },
  ];

  @override
  void initState() {
    super.initState();
    obtenerEspaciosDeportivos();
  }

  Future<void> obtenerEspaciosDeportivos() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? propietarioId = prefs.getString('userId');
      _userRol = prefs.getString('userRol');
      
      if (propietarioId == null) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        return;
      }

      final url = _userRol == 'superadmin' 
        ? '$baseUrl/api/espacio/espacios-deportivos' 
        : '$baseUrl/api/espacio/espacios-deportivos/$propietarioId';

      final response = await http.get(
        Uri.parse(url),
      );
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        setState(() {
          if (decodedData is List)
            espacios = decodedData;
          else if (decodedData is Map && decodedData.containsKey('data'))
            espacios = decodedData['data'];
          else
            hasError = true;
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          espacios = [];
          hasError = false;
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> guardarEspacioSeleccionado(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('espacio_id', id);
  }

  double get _promedioRating {
    if (_resenasMock.isEmpty) return 0;
    int sum = _resenasMock.fold(0, (acc, r) => acc + (r['rating'] as int));
    return sum / _resenasMock.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _userRol != 'superadmin' && espacios.isEmpty && !isLoading && !hasError
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.pushNamed(context, Routes.newEspacioPage);
                setState(() => isLoading = true);
                obtenerEspaciosDeportivos();
              },
              backgroundColor: _primaryDeep,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text("Registrar Espacio",
                  style: GoogleFonts.sansita(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Material(
                    color: _primaryDeep.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        setState(() => isLoading = true);
                        obtenerEspaciosDeportivos();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                          width: 42,
                          height: 42,
                          child: Icon(Icons.refresh_rounded,
                              size: 22, color: _primaryDeep)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                    child: Icon(Icons.stadium_rounded,
                        size: 24, color: _primaryDeep),
                  ),
                  const SizedBox(width: 12),
                  Text('Mi Espacio',
                      style: GoogleFonts.sansita(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: _primaryDeep,
                          letterSpacing: -0.5)),
                ],
              ),
              const SizedBox(height: 6),
              Text('Panel de gestión de tu espacio deportivo',
                  style: GoogleFonts.sansita(
                      fontSize: 15,
                      color: _primaryDeep.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  // ── BODY ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (isLoading)
      return Center(child: CircularProgressIndicator(color: _primaryDeep));

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: _primaryDeep.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text("Error al cargar tu espacio",
                style: GoogleFonts.sansita(fontSize: 16, color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: obtenerEspaciosDeportivos,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryDeep,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: Text("Reintentar",
                  style: GoogleFonts.sansita(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    if (espacios.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                    color: _primaryDeep.withValues(alpha: 0.06),
                    shape: BoxShape.circle),
                child: Icon(Icons.add_business_rounded,
                    size: 44, color: _primaryDeep.withValues(alpha: 0.3)),
              ),
              const SizedBox(height: 20),
              Text('Aún no tienes un espacio registrado',
                  style: GoogleFonts.sansita(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _primaryDeep),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                  'Registra tu instalación deportiva para empezar a recibir reservas.',
                  style: GoogleFonts.sansita(
                      fontSize: 14,
                      color: _primaryDeep.withValues(alpha: 0.45)),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tip contextual ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _primaryDeep.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _primaryDeep.withValues(alpha: 0.10)),
            ),
            child: Row(
              children: [
                Icon(Icons.touch_app_rounded,
                    size: 20, color: _primaryDeep.withValues(alpha: 0.6)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Toca tu espacio para ver los servicios, gestionar reservas o editar la información.',
                    style: GoogleFonts.sansita(
                        fontSize: 13,
                        color: _primaryDeep.withValues(alpha: 0.6),
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Label sección ──
          _buildSectionTitle(Icons.business_rounded, 'Tu espacio deportivo'),
          const SizedBox(height: 14),

          // ── Cards de espacios ──
          ...espacios.map((espacio) {
            final String imageUrl = (espacio['imagen'] != null &&
                    espacio['imagen'].toString().startsWith('http'))
                ? espacio['imagen']
                : 'https://img.freepik.com/foto-gratis/vista-cancha-futbol-iluminacion_23-2150888562.jpg';

            return GestureDetector(
              onTap: () async {
                await guardarEspacioSeleccionado(espacio['_id'] ?? '');
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DetalleEspacioDeportivoPage(espacio: espacio),
                    ));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: _primaryDeep.withValues(alpha: 0.08)),
                  boxShadow: [
                    BoxShadow(
                        color: _primaryDeep.withValues(alpha: 0.07),
                        blurRadius: 18,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Imagen hero ──
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24)),
                          child: Image.network(imageUrl,
                              height: 185,
                              width: double.infinity,
                              fit: BoxFit.cover),
                        ),
                        // Badge
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _primaryDeep.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.shield_rounded,
                                    color: Colors.white, size: 12),
                                const SizedBox(width: 5),
                                Text('Mi espacio',
                                    style: GoogleFonts.sansita(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                        // Overlay tap hint
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.open_in_new_rounded,
                                    color: Colors.white, size: 12),
                                const SizedBox(width: 5),
                                Text('Ver detalle',
                                    style: GoogleFonts.sansita(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── Info ──
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(espacio['nombre'] ?? "Mi Espacio",
                                    style: GoogleFonts.sansita(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: _primaryDeep,
                                        letterSpacing: -0.3),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                    color: _primaryDeep,
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.arrow_forward_rounded,
                                    size: 18, color: Colors.white),
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
                                child: Text(espacio['ubicacion'] ?? "Ubicación",
                                    style: GoogleFonts.sansita(
                                        fontSize: 13,
                                        color: _primaryDeep.withValues(
                                            alpha: 0.45)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── Divider ──
                          Divider(color: _primaryDeep.withValues(alpha: 0.07)),
                          const SizedBox(height: 12),

                          // ── Texto orientador ──
                          Text('¿Qué puedes hacer desde aquí?',
                              style: GoogleFonts.sansita(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryDeep.withValues(alpha: 0.5))),
                          const SizedBox(height: 10),

                          // ── Acciones ──
                          Row(
                            children: [
                              Expanded(
                                  child: _buildActionTile(
                                      Icons.calendar_month_rounded,
                                      'Eventos',
                                      'Crear y publicar')),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: _buildActionTile(
                                      Icons.miscellaneous_services_rounded,
                                      'Servicios',
                                      'Gestionar canchas')),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: _buildActionTile(Icons.edit_rounded,
                                      'Editar', 'Info del espacio')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 12),

          // ── Reseñas ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle(Icons.star_rounded, 'Reseñas'),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(_promedioRating.toStringAsFixed(1),
                        style: GoogleFonts.sansita(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800)),
                    Text(' / 5',
                        style: GoogleFonts.sansita(
                            fontSize: 12, color: Colors.orange.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Lo que tus usuarios opinan de tu espacio deportivo.',
              style: GoogleFonts.sansita(
                  fontSize: 13, color: _primaryDeep.withValues(alpha: 0.45))),
          const SizedBox(height: 14),
          _buildResenasList(),
        ],
      ),
    );
  }

  // ── ACTION TILE ───────────────────────────────────────────────────────────
  Widget _buildActionTile(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: _primaryDeep.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primaryDeep.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: _primaryDeep),
          const SizedBox(height: 6),
          Text(title,
              style: GoogleFonts.sansita(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _primaryDeep),
              textAlign: TextAlign.center),
          Text(subtitle,
              style: GoogleFonts.sansita(
                  fontSize: 10, color: _primaryDeep.withValues(alpha: 0.45)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── RESEÑAS ───────────────────────────────────────────────────────────────
  Widget _buildResenasList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _resenasMock.length,
      itemBuilder: (_, index) {
        final resena = _resenasMock[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _primaryDeep.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                  color: _primaryDeep.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _primaryDeep.withValues(alpha: 0.1),
                    child: Text(resena["autor"][0],
                        style: GoogleFonts.sansita(
                            fontWeight: FontWeight.bold, color: _primaryDeep)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(resena["autor"],
                            style: GoogleFonts.sansita(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _primaryDeep)),
                        Row(
                          children: List.generate(
                              5,
                              (i) => Icon(Icons.star,
                                  size: 13,
                                  color: i < resena["rating"]
                                      ? Colors.orange
                                      : Colors.grey.shade300)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('"${resena["opinion"]}"',
                  style: GoogleFonts.sansita(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: _primaryDeep.withValues(alpha: 0.55),
                      height: 1.4)),
            ],
          ),
        );
      },
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────
  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _primaryDeep.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: _primaryDeep),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.sansita(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _primaryDeep,
                letterSpacing: -0.3)),
      ],
    );
  }
}
