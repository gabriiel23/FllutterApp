import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutterapp/core/routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutterapp/config.dart';


class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final PageController _newsPageController;

  Timer? _newsTimer;

  int _newsCurrentPage = 0;

  String? _userRol;
  String? nombreUsuario;

  // --- Paleta de Colores CanchAPP ---
  final Color _primaryDeep = const Color(0xFF19382F);
  final Color _primaryLight = const Color(0xFF4CB050);
  final Color _bg = const Color(0xFFF8F9FA);
  final Color _card = Colors.white;
  final Color _textPrimary = const Color(0xFF1D1D1D);
  final Color _textSecondary = const Color(0xFF6B7280);

  // --- Datos Mockeados ---
  final List<Map<String, String>> _noticiasMock = [
    {
      "titulo": "Cancha El Campus Loja",
      "descripcion": "Cerrado por feriado el 28 de febrero y 1 de marzo.",
      "imagen":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT7iPQkoJvHMKAoL1gygV7KDFGoAQ9Fc-q8AG4-GNgnX8XSfFuhVXObZMQD891BHGP0m_Y&usqp=CAU",
      "etiqueta": "AVISO"
    },
    {
      "titulo": "Nuevo Césped Sintético",
      "descripcion": "La Bombonera renueva sus instalaciones con césped 5G.",
      "imagen":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT7iPQkoJvHMKAoL1gygV7KDFGoAQ9Fc-q8AG4-GNgnX8XSfFuhVXObZMQD891BHGP0m_Y&usqp=CAU",
      "etiqueta": "MEJORA"
    },
  ];

  final List<Map<String, String>> _canchasMock = [
    {
      "nombre": "Cancha La Pradera",
      "ubicacion": "Av. Occidental, Quito",
      "precio": "\$15.00/h",
      "imagen":
          "https://thumbs.dreamstime.com/b/ni%C3%B1os-que-entrenan-al-gimnasio-interior-futsal-del-f%C3%BAtbol-muchacho-joven-con-el-bal%C3%B3n-de-f%C3%BAtbol-80732309.jpg",
      "valoracion": "4.9"
    },
    {
      "nombre": "El Fortín Arena",
      "ubicacion": "Cerca del Parque Central",
      "precio": "\$12.00/h",
      "imagen":
          "https://thumbs.dreamstime.com/b/ni%C3%B1os-que-entrenan-al-gimnasio-interior-futsal-del-f%C3%BAtbol-muchacho-joven-con-el-bal%C3%B3n-de-f%C3%BAtbol-80732309.jpg",
      "valoracion": "4.7"
    },
  ];

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
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _newsPageController = PageController();
    _initData();
    _cargarNombreUsuario();
  }

  Future<void> _cargarNombreUsuario() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId'); // Obtener el userId
    String? token = prefs.getString('userToken'); // Obtener el token
    _userRol = prefs.getString('userRol'); // Obtener el rol

    if (userId != null && token != null) {
      try {
        String nombre = await obtenerNombreUsuario(
            userId, token); // Obtener el nombre del usuario
        setState(() {
          nombreUsuario =
              nombre; // Actualizar el estado con el nombre del usuario
        });
        await prefs.setString(
            'nombre_usuario', nombre); // Guardar el nombre en SharedPreferences
      } catch (e) {
        print("Error al cargar el nombre del usuario: $e");
        setState(() {
          nombreUsuario = 'Usuario'; // Valor predeterminado en caso de error
        });
      }
    } else {
      setState(() {
        nombreUsuario =
            'Usuario'; // Valor predeterminado si no hay userId o token
      });
    }
  }

  Future<String> obtenerNombreUsuario(String userId, String token) async {
    final String url =
        '${Config.baseUrl}/api/usuario/$userId'; // Endpoint para obtener el usuario por ID
    print("Obteniendo nombre del usuario desde: $url"); // Depuración

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token'
        }, // Enviar el token en el header
      );

      print("Código de respuesta: ${response.statusCode}"); // Depuración
      print("Respuesta: ${response.body}"); // Depuración

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData[
            'nombre']; // Ajusta según la estructura de la respuesta
      } else {
        throw Exception(
            "Error al obtener el nombre del usuario: ${response.statusCode}");
      }
    } catch (e) {
      print("Error de conexión: $e"); // Depuración
      throw Exception("Error de conexión: $e");
    }
  }

  Future<void> _initData() async {
    _startAutoCarousels();
  }

  void _startAutoCarousels() {
    _newsTimer?.cancel();
    _newsTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _noticiasMock.isEmpty) return;
      final next = (_newsCurrentPage + 1) % _noticiasMock.length;
      _newsPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _newsTimer?.cancel();
    _newsPageController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    await _initData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: _primaryDeep,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_userRol == 'superadmin') _buildAdminButton(),
                    if (_userRol == 'superadmin') const SizedBox(height: 28),
                    _buildSectionHeader('Novedades', Icons.newspaper_rounded),
                    const SizedBox(height: 20),
                    _newsCarousel(),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                        'Canchas destacadas', Icons.star_rounded),
                    _buildFeaturedCourtsList(),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                        'Opiniones de usuarios', Icons.forum_rounded),
                    _buildResenasList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── HEADER (BLANCO PREMIUM) ──────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
      ),
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila Superior: Drawer e Iconos de Acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_userRol == 'superadmin')
                        _HeaderIconButton(
                          icon: Icons.menu,
                          backgroundColor: _primaryDeep.withValues(alpha: 0.10),
                          iconColor: _primaryDeep,
                          onTap: () => Scaffold.of(context).openDrawer(),
                        )
                      else
                        const SizedBox(width: 42),
                      Row(
                        children: [
                          _HeaderIconButton(
                            icon: Icons.notifications_none,
                            backgroundColor:
                                _primaryDeep.withValues(alpha: 0.10),
                            iconColor: _primaryDeep,
                            onTap: () {},
                          ),
                          const SizedBox(width: 8),
                          _buildProfileMenu(isDark: false),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Textos de Bienvenida
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Hola ${nombreUsuario ?? 'Usuario'}",
                      style: GoogleFonts.sansita(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: _primaryDeep,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bienvenido a CanchAPP',
                    style: GoogleFonts.sansita(
                      fontSize: 20,
                      color: _primaryDeep.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenu({bool isDark = false}) {
    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.15)
          : _primaryDeep.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, Routes.settings);
        },
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            Icons.settings_outlined,
            size: 22,
            color: isDark ? Colors.white : _primaryDeep,
          ),
        ),
      ),
    );
  }

  // ── TITULOS DE SECCION ──────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _primaryDeep.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              Icon(icon, size: 18, color: _primaryDeep.withValues(alpha: 0.8)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.sansita(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  // ── NEWS CAROUSEL ───────────────────────────────────────────────────────
  Widget _newsCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _newsPageController,
            itemCount: _noticiasMock.length,
            onPageChanged: (index) => setState(() => _newsCurrentPage = index),
            itemBuilder: (_, index) {
              final item = _noticiasMock[index];
              return _NewsCardItem(
                novedad: item,
                primaryDeep: _primaryDeep,
                onTap: () {},
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _dotIndicator(_noticiasMock.length, _newsCurrentPage),
      ],
    );
  }

  // ── CANCHAS DESTACADAS (LISTA) ──────────────────────────────────────────
  Widget _buildFeaturedCourtsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _canchasMock.length,
      itemBuilder: (context, index) {
        final cancha = _canchasMock[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _primaryDeep.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  child: Image.network(
                    cancha["imagen"]!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          cancha["nombre"]!,
                          style: GoogleFonts.sansita(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                cancha["ubicacion"]!,
                                style: GoogleFonts.sansita(
                                  fontSize: 13,
                                  color: _textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cancha["precio"]!,
                              style: GoogleFonts.sansita(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _primaryLight,
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
                                  const Icon(Icons.star,
                                      size: 14, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Text(
                                    cancha["valoracion"]!,
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── RESEÑAS (LISTA) ─────────────────────────────────────────────────────
  Widget _buildResenasList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _resenasMock.length,
      itemBuilder: (context, index) {
        final resena = _resenasMock[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _primaryDeep.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _primaryDeep.withValues(alpha: 0.1),
                    child: Text(
                      resena["autor"]![0],
                      style: GoogleFonts.sansita(
                        fontWeight: FontWeight.bold,
                        color: _primaryDeep,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resena["autor"]!,
                          style: GoogleFonts.sansita(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              Icons.star,
                              size: 14,
                              color: i < resena["rating"]
                                  ? Colors.orange
                                  : Colors.grey.shade300,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "\"${resena["opinion"]}\"",
                style: GoogleFonts.sansita(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: _textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── DOT INDICATOR ───────────────────────────────────────────────────────
  Widget _dotIndicator(int length, int current) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        length,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i == current ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: i == current
                ? _primaryDeep.withValues(alpha: 0.8)
                : _primaryDeep.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // ── ADMIN BUTTON ────────────────────────────────────────────────────────
  Widget _buildAdminButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryDeep,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: _primaryDeep.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () => Navigator.pushNamed(context, Routes.gestionarUsuarios),
        child: Text(
          'PANEL DE ADMINISTRACIÓN',
          style: GoogleFonts.sansita(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

// ── HEADER ICON BUTTON ────────────────────────────────────────────────────
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 22, color: iconColor),
        ),
      ),
    );
  }
}

// ── NEWS CARD ITEM ────────────────────────────────────────────────────────
class _NewsCardItem extends StatelessWidget {
  final Map<String, String> novedad;
  final Color primaryDeep;
  final VoidCallback onTap;

  const _NewsCardItem({
    required this.novedad,
    required this.primaryDeep,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: primaryDeep,
          image: DecorationImage(
            image: NetworkImage(novedad["imagen"]!),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.10),
                Colors.black.withValues(alpha: 0.85),
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: primaryDeep,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  novedad["etiqueta"]!,
                  style: GoogleFonts.sansita(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                novedad["titulo"]!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.sansita(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.4,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                novedad["descripcion"]!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.sansita(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
