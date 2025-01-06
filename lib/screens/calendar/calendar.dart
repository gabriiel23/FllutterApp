import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutterapp/theme/theme_provider.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  int _currentIndex = 0;

  final List<String> _routes = ['/', '/Calendar', '/favorites', '/profile'];
  final List<String> _imageUrls = [
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR7RHPAFCjHycB4JdtiptgWppGvozldOJvb7A&s',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRvKJkBFL3FzV7cHLFJMgohaD3rbBjEQCe05Q&s',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRvKJkBFL3FzV7cHLFJMgohaD3rbBjEQCe05Q&s',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR7RHPAFCjHycB4JdtiptgWppGvozldOJvb7A&s',
  ];

  final List<String> _titles = [
    'San Sebastian',
    'El Bolivar',
    'Ciudad Victoria',
    'Calva & Calva'
  ];

  final List<int> _prices = [30, 25, 35, 20, 18, 16, 17, 22];

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
    Navigator.pushReplacementNamed(context, _routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF19382F),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
            16.0, 0.0, 16.0, 16.0), // Reduced top padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 4.0),
            _buildSubtitle(),
            const SizedBox(height: 24.0),
            _buildSearchBar(),
            const SizedBox(height: 24.0),
            _buildCourtGrid(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          "Reservas",
          style: GoogleFonts.sansita(
            fontSize: 86,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              const Shadow(
                offset: Offset(1.0, 1.0),
                blurRadius: 20.0,
                color: Colors.black,
              ),
            ],
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Icon(
            Icons.sports_soccer,
            color: Colors.white,
            size: 72,
          ),
        )
      ],
    );
  }

  Widget _buildSubtitle() {
    return Text(
      "Encuentra otras cosas (calendario o reservas):",
      style: GoogleFonts.sansita(
        fontSize: 16,
        color: Colors.black,
        shadows: [
          const Shadow(
            offset: Offset(2.0, 2.0),
            blurRadius: 20.0,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white70),
          const SizedBox(width: 8.0),
          Expanded(
            child: TextField(
              style: GoogleFonts.sansita(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Otro...",
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtGrid() {
    return Expanded(
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 6 / 10,
        ),
        itemCount: _imageUrls.length,
        itemBuilder: (context, index) {
          return _CourtCard(
            rating: "4.5",
            imageUrl: _imageUrls[index],
            title: _titles[index],
            dayPrice: "\$${_prices[index]}", // Precio del día
            nightPrice:
                "\$${_prices[index] - 5}", // Precio de la noche (ejemplo, ajusta como desees)
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(4, (index) {
          final icons = [
            Icons.home,
            Icons.shopping_cart,
            Icons.favorite,
            Icons.person
          ];
          return IconButton(
            icon: Icon(
              icons[index],
              color: _currentIndex == index ? Colors.white : Colors.grey,
            ),
            onPressed: () => _onItemTapped(index),
          );
        }),
      ),
    );
  }
}

class _CourtCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String dayPrice; // Precio de día
  final String nightPrice; // Precio de noche
  final String rating;

  const _CourtCard({
    required this.imageUrl,
    required this.title,
    required this.dayPrice,
    required this.nightPrice,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A4E43),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating Row
            Row(
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 4.0),
                Text(
                  rating,
                  style: GoogleFonts.sansita(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            // Image
            const SizedBox(height: 8.0),
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.network(
                imageUrl,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            // Title
            const SizedBox(height: 12.0),
            Text(
              title,
              style: GoogleFonts.sansita(
                fontSize: 30,
                color: Colors.white,
              ),
            ),

            // Day and Night Price Column
            const SizedBox(height: 18.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Precio de día
                Row(
                  children: [
                    const Icon(
                      Icons.wb_sunny, // Ícono de sol
                      color: Colors.yellow,
                      size: 24,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      dayPrice,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                // Precio de noche y botón de agregar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.nightlight_round, // Ícono de luna
                          color: Colors.white70,
                          size: 24,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          nightPrice,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    // Botón de agregar
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
