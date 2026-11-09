import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/movie.dart';
import '../providers/movie_provider.dart';
import 'movie_detail_screen.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _mainScrollController = ScrollController();
  final PageController _pageController = PageController();
  Timer? _sliderTimer;
  int _currentSlide = 0;
  String _activePill = 'Trending';

  // GlobalKeys for auto-scrolling to specific genre rows
  final GlobalKey _trendingKey = GlobalKey();
  final GlobalKey _actionKey = GlobalKey();
  final GlobalKey _sciFiKey = GlobalKey();
  final GlobalKey _animationKey = GlobalKey();
  final GlobalKey _dramaKey = GlobalKey();
  final GlobalKey _thrillerKey = GlobalKey();

  // 5 Featured Movies with 100% Verified 4K TMDB Backdrops
  final List<Map<String, dynamic>> _featuredMovies = [
    {
      'id': 157336,
      'title': 'Interstellar',
      'rating': 8.7,
      'year': '2014',
      'overview':
          'When Earth becomes uninhabitable, a team of explorers embarks on the most important mission in human history: traveling through a wormhole beyond this galaxy.',
      'backdrop':
          'https://image.tmdb.org/t/p/original/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
      'poster':
          'https://image.tmdb.org/t/p/original/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
      'genreIds': [878, 12, 18],
    },
    {
      'id': 299534,
      'title': 'Avengers: Endgame',
      'rating': 8.4,
      'year': '2019',
      'overview':
          'After the devastating events of Infinity War, the universe is in ruins. The Avengers assemble once more to reverse Thanos actions and restore balance.',
      'backdrop':
          'https://image.tmdb.org/t/p/original/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg',
      'poster':
          'https://image.tmdb.org/t/p/original/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg',
      'genreIds': [28, 878, 12],
    },
    {
      'id': 354912,
      'title': 'Coco',
      'rating': 8.2,
      'year': '2017',
      'overview':
          'Despite his family ban on music, Miguel dreams of becoming an accomplished musician and journeys to the vibrant Land of the Dead.',
      'backdrop':
          'https://image.tmdb.org/t/p/original/6AANwKhjIEVyya95oW4IA6joL1Z.jpg',
      'poster':
          'https://image.tmdb.org/t/p/original/6AANwKhjIEVyya95oW4IA6joL1Z.jpg',
      'genreIds': [16, 10751, 35],
    },
    {
      'id': 420818,
      'title': 'Mufasa: The Lion King',
      'rating': 8.0,
      'year': '2024',
      'overview':
          'Witness the untold origin of the beloved king of the Pride Lands and his bond with brother Taka in stunning photorealistic live-action.',
      'backdrop':
          'https://image.tmdb.org/t/p/original/1TUg5pO1VZ4B0Q1amk3OlXvlpXV.jpg',
      'poster':
          'https://image.tmdb.org/t/p/original/1TUg5pO1VZ4B0Q1amk3OlXvlpXV.jpg',
      'genreIds': [12, 18, 10751],
    },
    {
      'id': 862,
      'title': 'Toy Story',
      'rating': 8.0,
      'year': '1995',
      'overview':
          'Led by Woody, Andy toys live happily until Buzz Lightyear arrives. When separated from their owner, the duo must find their way back home.',
      'backdrop':
          'https://image.tmdb.org/t/p/original/2LqaLgk4Z226KkgPJuiOQ58wvrm.jpg',
      'poster':
          'https://image.tmdb.org/t/p/original/2LqaLgk4Z226KkgPJuiOQ58wvrm.jpg',
      'genreIds': [16, 35, 10751],
    },
  ];

  @override
  void initState() {
    super.initState();
    // 4 seconds auto slide
    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentSlide + 1) % _featuredMovies.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MovieProvider>(context, listen: false);
      try {
        (provider as dynamic).fetchMovies();
      } catch (_) {
        try {
          (provider as dynamic).fetchTrendingMovies();
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _pageController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  // Smooth scroll to specific genre row key
  void _scrollToGenre(GlobalKey key, String name) {
    setState(() {
      _activePill = name;
    });
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
        alignment: 0.12,
      );
    }
  }

  Movie _mapToMovieModel(Map<String, dynamic> item) {
    return Movie(
      id: item['id'] as int,
      title: item['title'] as String,
      overview: item['overview'] as String,
      posterPath: item['poster'] as String,
      backdropPath: item['backdrop'] as String,
      voteAverage: (item['rating'] as num).toDouble(),
      releaseDate: '${item['year']}-01-01',
      genreIds: (item['genreIds'] as List<int>?) ?? const [],
    );
  }

  List<Movie> _filterByGenre(List<Movie> list, int genreId) {
    return list.where((m) => m.genreIds.contains(genreId)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final movieProvider = Provider.of<MovieProvider>(context);

    final List<Movie> allMovies = movieProvider.movies.isNotEmpty
        ? movieProvider.movies
        : _featuredMovies.map((m) => _mapToMovieModel(m)).toList();

    // Categorized lists
    final actionMovies = _filterByGenre(allMovies, 28);
    final sciFiMovies = _filterByGenre(allMovies, 878);
    final animationMovies = _filterByGenre(allMovies, 16);
    final dramaMovies = _filterByGenre(allMovies, 18);
    final thrillerMovies = _filterByGenre(allMovies, 53);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15),
      body: Stack(
        children: [
          // 1. MAIN SCROLLABLE BODY
          SingleChildScrollView(
            controller: _mainScrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 4K AUTO SLIDER
                SizedBox(
                  height: 520,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: _featuredMovies.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentSlide = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final item = _featuredMovies[index];
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                item['backdrop'],
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF141622),
                                  child: const Center(
                                    child: Icon(Icons.movie, size: 80, color: Colors.white24),
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.55),
                                      Colors.transparent,
                                      const Color(0xFF0D0E15).withOpacity(0.85),
                                      const Color(0xFF0D0E15),
                                    ],
                                    stops: const [0.0, 0.4, 0.82, 1.0],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 24,
                                right: 24,
                                bottom: 35,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF334B),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            '4K ULTRA HD',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.white12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${item['rating']}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '(${item['year']})',
                                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      item['title'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item['overview'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFFBAC0D4),
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => MovieDetailScreen(
                                                  movie: _mapToMovieModel(item),
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                                          label: const Text(
                                            'Watch Now',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFFF334B),
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(24),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => MovieDetailScreen(
                                                  movie: _mapToMovieModel(item),
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.info_outline, color: Colors.white),
                                          label: const Text(
                                            'Details',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: Colors.black.withOpacity(0.4),
                                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(24),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      Positioned(
                        right: 24,
                        bottom: 45,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            _featuredMovies.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _currentSlide == index ? 22 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _currentSlide == index ? const Color(0xFFFF334B) : Colors.white24,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. QUICK JUMP GENRE PILLS (CLICK TO AUTO SCROLL)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildScrollPill('Trending', _trendingKey, Icons.local_fire_department),
                        _buildScrollPill('Action', _actionKey, Icons.flash_on),
                        _buildScrollPill('Sci-Fi', _sciFiKey, Icons.rocket_launch),
                        _buildScrollPill('Animation', _animationKey, Icons.auto_awesome),
                        _buildScrollPill('Drama', _dramaKey, Icons.theater_comedy),
                        _buildScrollPill('Thriller', _thrillerKey, Icons.psychology),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 3. ROW 1: TRENDING THIS WEEK
                _buildMovieRowSection(
                  key: _trendingKey,
                  title: 'Trending This Week',
                  movies: allMovies,
                  tag: 'Popular',
                ),

                // 4. ROW 2: ACTION BLOCKBUSTERS
                _buildMovieRowSection(
                  key: _actionKey,
                  title: 'Action Blockbusters',
                  movies: actionMovies.isNotEmpty ? actionMovies : allMovies.take(6).toList(),
                  tag: 'Action',
                ),

                // 5. ROW 3: SCI-FI & FUTURE WORLDS
                _buildMovieRowSection(
                  key: _sciFiKey,
                  title: 'Sci-Fi & Future Worlds',
                  movies: sciFiMovies.isNotEmpty ? sciFiMovies : allMovies.reversed.take(6).toList(),
                  tag: 'Sci-Fi',
                ),

                // 6. ROW 4: ANIMATED & FAMILY HITS
                _buildMovieRowSection(
                  key: _animationKey,
                  title: 'Animation & Family',
                  movies: animationMovies.isNotEmpty ? animationMovies : allMovies.take(5).toList(),
                  tag: 'Family',
                ),

                // 7. ROW 5: DRAMA & AWARD WINNERS
                _buildMovieRowSection(
                  key: _dramaKey,
                  title: 'Drama & Acclaimed',
                  movies: dramaMovies.isNotEmpty ? dramaMovies : allMovies.take(6).toList(),
                  tag: 'Drama',
                ),

                // 8. ROW 6: THRILLER & SUSPENSE
                _buildMovieRowSection(
                  key: _thrillerKey,
                  title: 'Thriller & Suspense',
                  movies: thrillerMovies.isNotEmpty ? thrillerMovies : allMovies.reversed.take(5).toList(),
                  tag: 'Thriller',
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),

          // 2. DESKTOP / MOBILE RESPONSIVE TOP NAVBAR
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo + Responsive Navigation Links
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF334B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'CinePulse',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      // Links tabhi dikhenge jab screen desktop/tablet width (> 700px) par ho
                      if (MediaQuery.of(context).size.width > 700) ...[
                        const SizedBox(width: 28),
                        _buildHeaderLink('Home', true, () {}),
                        _buildHeaderLink('Trending', false, () => _scrollToGenre(_trendingKey, 'Trending')),
                        _buildHeaderLink('Movies', false, () => _scrollToGenre(_actionKey, 'Action')),
                        _buildHeaderLink('Watchlist', false, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
                        }),
                      ],
                    ],
                  ),

                  // Search + Watchlist Heart
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.search, color: Colors.white70, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Search movies...',
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.favorite_outline, color: Color(0xFFFF334B)),
                        tooltip: 'Watchlist',
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header Nav Text Links
  Widget _buildHeaderLink(String title, bool isActive, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: InkWell(
        onTap: onTap,
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white60,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // Genre Pill Button with Click-to-Scroll
  Widget _buildScrollPill(String name, GlobalKey key, IconData icon) {
    final isSelected = _activePill == name;
    return GestureDetector(
      onTap: () => _scrollToGenre(key, name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF334B) : const Color(0xFF161824),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF334B) : Colors.white.withOpacity(0.08),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF334B).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.white60),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Individual Genre Row Section
  Widget _buildMovieRowSection({
    required GlobalKey key,
    required String title,
    required List<Movie> movies,
    required String tag,
  }) {
    final movieProvider = Provider.of<MovieProvider>(context);

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF334B),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E212E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${movies.length} titles',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 245,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movie = movies[index];
                final isFav = movieProvider.isFavorite(movie.id);
                return _buildMovieCard(context, movie, isFav, movieProvider);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Movie Card with Tap to Detail
  Widget _buildMovieCard(BuildContext context, Movie movie, bool isFav, MovieProvider provider) {
    final posterUrl = movie.posterPath.isNotEmpty
        ? (movie.posterPath.startsWith('http')
            ? movie.posterPath
            : 'https://image.tmdb.org/t/p/w500${movie.posterPath}')
        : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovieDetailScreen(movie: movie),
          ),
        );
      },
      child: Container(
        width: 145,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 200,
                    width: 145,
                    color: const Color(0xFF161824),
                    child: posterUrl.isNotEmpty
                        ? Image.network(
                            posterUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.movie, color: Colors.white24),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.movie, color: Colors.white24),
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black.withOpacity(0.65),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? const Color(0xFFFF334B) : Colors.white,
                        size: 16,
                      ),
                      onPressed: () {
                        provider.toggleFavorite(movie);
                      },
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 14),
                        const SizedBox(width: 3),
                        Text(
                          movie.voteAverage.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
