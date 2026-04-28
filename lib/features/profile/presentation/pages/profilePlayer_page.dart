import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterapp/config.dart';
import 'dart:async';

class ProfilePlayerPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const ProfilePlayerPage({super.key, this.initialData});

  @override
  _ProfilePlayerPageState createState() => _ProfilePlayerPageState();
}

class _ProfilePlayerPageState extends State<ProfilePlayerPage> {
  final Color _primaryDeep = const Color(0xFF19382F);

  String? selectedRole;
  int height = 170;
  int age = 18;
  String? userId;
  String? userName = "JUGADOR";
  bool _isLoading = false;

  Timer? _holdTimer;

  final List<String> _posiciones = [
    'Portero',
    'Defensa',
    'Mediocampista',
    'Delantero'
  ];

  Map<String, int> attributes = {
    'Tiro': 50,
    'Regate': 50,
    'Pase': 50,
    'Ritmo': 50,
    'Defensa': 50,
    'Físico': 50,
    'Reflejos': 50,
    'Saque': 50,
    'Manejo': 50,
    'Estirada': 50,
    'Velocidad': 50,
    'Posicionamiento': 50,
  };

  final String apiUrl = '${Config.baseUrl}/api/jugadores';

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      selectedRole = widget.initialData!['posicion'];
      height = widget.initialData!['estatura'] ?? 170;
      age = widget.initialData!['edad'] ?? 18;

      final Map<String, dynamic>? attrs = widget.initialData!['atributos'];
      if (attrs != null) {
        attrs.forEach((key, value) {
          if (attributes.containsKey(key)) {
            attributes[key] = (value as num).toInt();
          }
        });
      }
    }
    _loadUserData();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => userId = prefs.getString('userId'));
  }

  int get _overallRating {
    if (selectedRole == null) return 50;
    final attrs = _getCurrentAttributesList();
    if (attrs.isEmpty) return 50;
    int sum = 0;
    for (var a in attrs) sum += attributes[a]!;
    return (sum / attrs.length).round();
  }

  List<String> _getCurrentAttributesList() {
    if (selectedRole == 'Portero') {
      return [
        'Reflejos',
        'Saque',
        'Manejo',
        'Estirada',
        'Velocidad',
        'Posicionamiento'
      ];
    }
    return ['Ritmo', 'Tiro', 'Pase', 'Regate', 'Defensa', 'Físico'];
  }

  String _getPosAbbreviation() {
    switch (selectedRole) {
      case 'Portero':
        return 'POR';
      case 'Defensa':
        return 'DEF';
      case 'Mediocampista':
        return 'MED';
      case 'Delantero':
        return 'DEL';
      default:
        return '-';
    }
  }

  Color _getAttrColor(int value) {
    if (value >= 90) return const Color.fromARGB(255, 255, 176, 79); // Naranja
    if (value >= 80) return Colors.blue.shade600; // Azul
    if (value >= 70) return Colors.green.shade600; // Verde
    if (value >= 60) return const Color.fromARGB(255, 210, 133, 0); // Amarillo
    if (value >= 50) return Colors.red.shade400; // Rojo
    return Colors.grey.shade500; // Gris
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.sansita()),
      backgroundColor: _primaryDeep,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> saveProfile() async {
    if (selectedRole == null || userId == null) {
      _showSnack("Faltan datos o no estás autenticado");
      return;
    }
    setState(() => _isLoading = true);
    try {
      final isUpdate = widget.initialData != null;
      final uri = isUpdate
          ? Uri.parse('$apiUrl/${widget.initialData!['_id']}')
          : Uri.parse(apiUrl);
      final method = isUpdate ? 'PUT' : 'POST';

      var request = http.MultipartRequest(method, uri);
      request.fields['usuario'] = userId!;
      request.fields['posicion'] = selectedRole!;
      request.fields['estatura'] = height.toString();
      request.fields['edad'] = age.toString();

      Map<String, int> finalAttributes = {};
      for (var attr in _getCurrentAttributesList()) {
        finalAttributes[attr] = attributes[attr]!;
      }
      request.fields['atributos'] = jsonEncode(finalAttributes);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      setState(() => _isLoading = false);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnack('¡Perfil de jugador guardado correctamente!');
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        final bodyDecoded = jsonDecode(response.body);
        final errorMsg =
            bodyDecoded['error'] ?? bodyDecoded['mensaje'] ?? response.body;
        throw Exception(errorMsg);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryDeep))
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Carta FIFA ──
                        Center(child: _buildFifaCard()),
                        const SizedBox(height: 32),

                        // ── Posición ──
                        _buildSectionTitle(
                            Icons.sports_soccer_rounded, 'Tu posición'),
                        const SizedBox(height: 12),
                        _buildPositionSelector(),
                        const SizedBox(height: 28),

                        // ── Datos físicos ──
                        _buildSectionTitle(
                            Icons.accessibility_new_rounded, 'Datos físicos'),
                        const SizedBox(height: 12),
                        _buildPhysicalData(),
                        const SizedBox(height: 28),

                        // ── Atributos ──
                        if (selectedRole != null) ...[
                          _buildSectionTitle(
                              Icons.trending_up_rounded, 'Atributos técnicos'),
                          const SizedBox(height: 12),
                          _buildAttributesGrid(),
                          const SizedBox(height: 28),
                        ],

                        // ── Galería ──
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _primaryDeep.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: _primaryDeep.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.photo_library_rounded,
                                  size: 18,
                                  color: _primaryDeep.withValues(alpha: 0.5)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'La galería de fotos se gestiona desde la sección "Galería" de tu perfil.',
                                  style: GoogleFonts.sansita(
                                      fontSize: 12,
                                      color:
                                          _primaryDeep.withValues(alpha: 0.5)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),

                        // ── Botón guardar ──
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed:
                                selectedRole == null ? null : saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryDeep,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  _primaryDeep.withValues(alpha: 0.3),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text('Guardar perfil',
                                style: GoogleFonts.sansita(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
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

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
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
                children: [
                  Material(
                    color: _primaryDeep.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                          width: 42,
                          height: 42,
                          child: Icon(Icons.arrow_back_rounded,
                              size: 22, color: _primaryDeep)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Perfil de jugador',
                    style: GoogleFonts.sansita(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: _primaryDeep,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Configura tu perfil de jugador y destaca en la comunidad',
                style: GoogleFonts.sansita(
                    fontSize: 14,
                    color: _primaryDeep.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── CARTA FIFA ────────────────────────────────────────────────────────────
  Widget _buildFifaCard() {
    return IntrinsicHeight(
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE5C07B), Color(0xFFC49A45)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 20, offset: Offset(0, 10)),
          ],
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -30,
              child: Icon(Icons.sports_soccer,
                  size: 120, color: Colors.white.withValues(alpha: 0.08)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_overallRating',
                          style: GoogleFonts.sansita(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              height: 1),
                        ),
                        Text(
                          _getPosAbbreviation(),
                          style: GoogleFonts.sansita(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.black12, width: 2),
                        image: const DecorationImage(
                          image: NetworkImage(
                              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSeK0gW1HYfQOp7FPzueC8sufR7nv0Bi2WejZyhEbIO9gEuBKtoEbiPs_oTOivMRzu4Jjs&usqp=CAU'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  userName!.toUpperCase(),
                  style: GoogleFonts.sansita(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: 1),
                ),
                Divider(
                    color: Colors.black.withValues(alpha: 0.2),
                    thickness: 1,
                    height: 16),
                _buildCardAttributes(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardAttributes() {
    if (selectedRole == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text('Selecciona tu posición',
              style: GoogleFonts.sansita(fontSize: 13, color: Colors.black54),
              textAlign: TextAlign.center),
        ),
      );
    }
    final attrs = _getCurrentAttributesList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: attrs.sublist(0, 3).map((a) => _buildCardStat(a)).toList(),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: attrs.sublist(3).map((a) => _buildCardStat(a)).toList(),
        ),
      ],
    );
  }

  Widget _buildCardStat(String stat) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('${attributes[stat]} ',
              style: GoogleFonts.sansita(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87)),
          Text(stat.substring(0, 3).toUpperCase(),
              style: GoogleFonts.sansita(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }

  // ── SELECTOR DE POSICIÓN ──────────────────────────────────────────────────
  Widget _buildPositionSelector() {
    final icons = {
      'Portero': Icons.back_hand_rounded,
      'Defensa': Icons.shield_rounded,
      'Mediocampista': Icons.sync_alt_rounded,
      'Delantero': Icons.rocket_launch_rounded,
    };

    return Row(
      children: _posiciones.map((pos) {
        final isSelected = selectedRole == pos;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedRole = pos),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: pos != _posiciones.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? _primaryDeep
                    : _primaryDeep.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isSelected
                        ? _primaryDeep
                        : _primaryDeep.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  Icon(icons[pos],
                      size: 22,
                      color: isSelected
                          ? Colors.white
                          : _primaryDeep.withValues(alpha: 0.5)),
                  const SizedBox(height: 5),
                  Text(
                    pos == 'Mediocampista' ? 'Medio' : pos,
                    style: GoogleFonts.sansita(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : _primaryDeep.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── DATOS FÍSICOS CON STEPPER ─────────────────────────────────────────────
  Widget _buildPhysicalData() {
    return Row(
      children: [
        Expanded(
          child: _buildStepperField(
            label: 'Estatura',
            value: height,
            unit: 'cm',
            min: 140,
            max: 210,
            icon: Icons.height_rounded,
            onDecrement: () {
              if (height > 140) setState(() => height--);
            },
            onIncrement: () {
              if (height < 210) setState(() => height++);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStepperField(
            label: 'Edad',
            value: age,
            unit: 'años',
            min: 10,
            max: 70,
            icon: Icons.cake_rounded,
            onDecrement: () {
              if (age > 10) setState(() => age--);
            },
            onIncrement: () {
              if (age < 70) setState(() => age++);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStepperField({
    required String label,
    required int value,
    required String unit,
    required int min,
    required int max,
    required IconData icon,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _primaryDeep.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryDeep.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: _primaryDeep.withValues(alpha: 0.5)),
              const SizedBox(width: 5),
              Text(label,
                  style: GoogleFonts.sansita(
                      fontSize: 12,
                      color: _primaryDeep.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepBtn(Icons.remove_rounded, onDecrement),
              Column(
                children: [
                  Text('$value',
                      style: GoogleFonts.sansita(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _primaryDeep)),
                  Text(unit,
                      style: GoogleFonts.sansita(
                          fontSize: 11,
                          color: _primaryDeep.withValues(alpha: 0.4))),
                ],
              ),
              _buildStepBtn(Icons.add_rounded, onIncrement),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: _primaryDeep.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 18, color: _primaryDeep),
        ),
      ),
    );
  }

  // ── ATRIBUTOS EN GRID CON STEPPER ─────────────────────────────────────────
  Widget _buildAttributesGrid() {
    final attrs = _getCurrentAttributesList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.7,
      ),
      itemCount: attrs.length,
      itemBuilder: (_, i) => _buildAttrCard(attrs[i]),
    );
  }

  Widget _buildAttrCard(String attr) {
    final val = attributes[attr]!;
    final color = _getAttrColor(val);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: _primaryDeep.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(attr,
                  style: GoogleFonts.sansita(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _primaryDeep.withValues(alpha: 0.6))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('$val',
                    style: GoogleFonts.sansita(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAttrBtn(Icons.remove_rounded, attr, false),
              // Mini barra de progreso
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: val / 99,
                      minHeight: 6,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
              ),
              _buildAttrBtn(Icons.add_rounded, attr, true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttrBtn(IconData icon, String attr, bool isIncrement) {
    return GestureDetector(
      onTap: () {
        final val = attributes[attr]!;
        if (isIncrement) {
          if (val < 99) setState(() => attributes[attr] = val + 1);
        } else {
          if (val > 1) setState(() => attributes[attr] = val - 1);
        }
      },
      onLongPressStart: (_) {
        _holdTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
          final val = attributes[attr]!;
          if (isIncrement) {
            if (val < 99)
              setState(() => attributes[attr] = val + 1);
            else
              timer.cancel();
          } else {
            if (val > 1)
              setState(() => attributes[attr] = val - 1);
            else
              timer.cancel();
          }
        });
      },
      onLongPressEnd: (_) {
        _holdTimer?.cancel();
      },
      child: Material(
        color: _primaryDeep.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(icon, size: 16, color: _primaryDeep),
        ),
      ),
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
              borderRadius: BorderRadius.circular(10)),
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
