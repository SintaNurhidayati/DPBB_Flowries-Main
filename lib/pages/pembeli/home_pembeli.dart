import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/custom_navbar.dart';
import '../../widgets/cart_badge_icon.dart';
class HomePembeli extends StatefulWidget {
  const HomePembeli({super.key});

  @override
  State<HomePembeli> createState() => _HomePembeliState();
}

class _HomePembeliState extends State<HomePembeli> with SingleTickerProviderStateMixin {
  int _currentNavIndex = 0;
  Timer? _carouselTimer;

  final List<String> _carouselImages = [
    'assets/images/slider1.png',
    'assets/images/slider2.png',
    'assets/images/slider3.png',
    'assets/images/slider4.png',
  ];

  final List<String> _carouselTitles = [
    'Fresh Flowers Daily',
    'Bespoke Artisan Designs',
    'Same Day Delivery',
    'Hand-Selected Petals',
  ];

  int _currentCarouselIndex = 0;

  final String _imgTentang = 'assets/images/tentang.png';
  final String _imgCustom = 'assets/images/custom.png';
  final String _imgLiveChat = 'assets/images/livechat.png';
  final String _imgCollection = 'assets/images/collection.png';

  @override
  void initState() {
    super.initState();
    _startCarouselAutoPlay();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    super.dispose();
  }

  void _startCarouselAutoPlay() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentCarouselIndex = (_currentCarouselIndex + 1) % _carouselImages.length;
        });
      }
    });
  }

  Future<void> _openWhatsApp() async {
    final phoneNumber = '6282211878020';
    final message = 'Halo Flowries, saya ingin bertanya tentang bunga...';
    final whatsappUrl = 'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';

    try {
      final Uri url = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Tidak dapat membuka WhatsApp';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pastikan WhatsApp terinstall di perangkat Anda'),
          ),
        );
      }
    }
  }

  void _handleNavigation(int index) {
    if (_currentNavIndex == index) return;
    setState(() => _currentNavIndex = index);
    switch (index) {
      case 0: break;
      case 1: Navigator.pushReplacementNamed(context, '/katalog'); break;
      case 2: Navigator.pushReplacementNamed(context, '/custom-order'); break;
      case 3: Navigator.pushReplacementNamed(context, '/riwayat'); break;
      case 4: Navigator.pushReplacementNamed(context, '/profil-pembeli'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 600;
    final primaryColor = Theme.of(context).primaryColor;
    final containerColor = Colors.white;
    final cardBorderColor = const Color(0xFFFFE4EB);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        elevation: 0,
        centerTitle: true,
        actions: const [
          CartBadgeIcon(),
          SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh logic if needed
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carousel
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: cardBorderColor, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: SizedBox(
                      height: 250,
                      child: Stack(
                        children: [
                          PageView.builder(
                            onPageChanged: (index) {
                              setState(() {
                                _currentCarouselIndex = index;
                              });
                            },
                            itemCount: _carouselImages.length,
                            itemBuilder: (context, index) {
                              return Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(_carouselImages[index]),
                                    fit: BoxFit.cover,
                                    colorFilter: ColorFilter.mode(
                                      Colors.black.withOpacity(0.3),
                                      BlendMode.darken,
                                    ),
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _carouselTitles[index],
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 10,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Flowries Bouquet',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.9),
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_carouselImages.length, (index) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: _currentCarouselIndex == index ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: _currentCarouselIndex == index
                                        ? primaryColor
                                        : Colors.white.withOpacity(0.6),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildTentangCard(isDesktop),
              const SizedBox(height: 16),
              _buildCardRight(
                imagePath: _imgCustom,
                title: 'Customize yours!',
                description: 'Tailor a bouquet to your specific dreams. Pilih bunga favorit, pilih warna, tambahkan pesan spesial - kami akan rangkai penuh cinta.',
                buttonText: 'Build Bouquet',
                onButtonPressed: () {
                  _handleNavigation(2);
                },
                isDesktop: isDesktop,
              ),
              const SizedBox(height: 16),
              _buildCardLeft(
                imagePath: _imgLiveChat,
                title: 'Live Chat',
                description: 'Send your questions to Flowries Bouquet. Tim kami siap membantu Anda 24/7 melalui WhatsApp.',
                buttonText: 'Chat WhatsApp',
                buttonColor: const Color(0xFF25D366),
                onButtonPressed: _openWhatsApp,
                isDesktop: isDesktop,
              ),
              const SizedBox(height: 16),
              _buildCardRight(
                imagePath: _imgCollection,
                title: 'Collection',
                description: 'Celebrate the height of summer with our seasonal curation of vibrant sun-kissed petals. Temukan koleksi bunga terbaik kami.',
                buttonText: 'Lihat Katalog',
                onButtonPressed: () => _handleNavigation(1),
                isDesktop: isDesktop,
              ),
              const SizedBox(height: 30),
              _buildFooterCard(isDesktop),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentNavIndex,
        onIndexChanged: _handleNavigation,
      ),
    );
  }

  Widget _buildTentangCard(bool isDesktop) {
    final primaryColor = Theme.of(context).primaryColor;
    final containerColor = Colors.white;
    final cardBorderColor = const Color(0xFFFFE4EB);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: cardBorderColor, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: Image.asset(
                _imgTentang,
                width: isDesktop ? 200 : 150,
                height: isDesktop ? 220 : 170,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: isDesktop ? 200 : 150,
                    height: isDesktop ? 220 : 170,
                    color: primaryColor.withOpacity(0.15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined, color: primaryColor, size: 40),
                        const SizedBox(height: 8),
                        Text('Tentang Flowries', style: TextStyle(color: primaryColor, fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🌸 Tentang Flowries',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Flowries Bouquet adalah toko bunga yang menghadirkan keindahan alam dalam setiap rangkaian bunga kami. Didirikan pada tahun 2020, kami berkomitmen memberikan bunga segar berkualitas premium dengan desain yang artistik dan penuh cinta.',
                      style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardLeft({
    required String imagePath,
    required String title,
    required String description,
    required String buttonText,
    Color buttonColor = const Color(0xFFD06696),
    required VoidCallback onButtonPressed,
    bool isDesktop = false,
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    final containerColor = Colors.white;
    final cardBorderColor = const Color(0xFFFFE4EB);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: cardBorderColor, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: Image.asset(
                imagePath,
                width: isDesktop ? 180 : 140,
                height: isDesktop ? 180 : 140,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: isDesktop ? 180 : 140,
                    height: isDesktop ? 180 : 140,
                    color: primaryColor.withOpacity(0.15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined, color: primaryColor, size: 40),
                        const SizedBox(height: 8),
                        Text('Foto', style: TextStyle(color: primaryColor, fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.4),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 120,
                      height: 30,
                      child: ElevatedButton(
                        onPressed: onButtonPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 2,
                        ),
                        child: Text(buttonText),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardRight({
    required String imagePath,
    required String title,
    required String description,
    required String buttonText,
    Color buttonColor = const Color(0xFFD06696),
    required VoidCallback onButtonPressed,
    bool isDesktop = false,
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    final containerColor = Colors.white;
    final cardBorderColor = const Color(0xFFFFE4EB);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: cardBorderColor, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.4),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 120,
                      height: 30,
                      child: ElevatedButton(
                        onPressed: onButtonPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 2,
                        ),
                        child: Text(buttonText),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
              child: Image.asset(
                imagePath,
                width: isDesktop ? 180 : 140,
                height: isDesktop ? 180 : 140,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: isDesktop ? 180 : 140,
                    height: isDesktop ? 180 : 140,
                    color: primaryColor.withOpacity(0.15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined, color: primaryColor, size: 40),
                        const SizedBox(height: 8),
                        Text('Foto', style: TextStyle(color: primaryColor, fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterCard(bool isDesktop) {
    final primaryColor = Theme.of(context).primaryColor;
    final containerColor = Colors.white;
    final cardBorderColor = const Color(0xFFFFE4EB);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: cardBorderColor, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.favorite, color: primaryColor, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Terima Kasih Telah Memilih Kami',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Flowries Bouquet selalu berusaha memberikan pelayanan dan kualitas terbaik untuk setiap momen berharga Anda.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialIcon(Icons.facebook, Colors.blue),
                  const SizedBox(width: 12),
                  _buildSocialIcon(Icons.camera_alt, Colors.pink),
                  const SizedBox(width: 12),
                  _buildSocialIcon(Icons.email, Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}