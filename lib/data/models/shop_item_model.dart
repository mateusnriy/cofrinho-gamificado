import 'package:flutter/material.dart';

enum CosmeticCategory {
  skin,
  hat,
  cloth,
  backdrop,
}

class ShopItem {
  final String id;
  final String name;
  final String description;
  final CosmeticCategory category;
  final int price;
  final IconData icon;
  final Color accentColor;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.icon,
    required this.accentColor,
  });

  bool get isFree => price == 0;
}

class ShopCatalog {
  static const List<ShopItem> allItems = [
    // --- SKINS ---
    ShopItem(
      id: 'pink_classic',
      name: 'Rosa Clássico',
      description: 'O visual original e fofinho do Porko.',
      category: CosmeticCategory.skin,
      price: 0,
      icon: Icons.pets_rounded,
      accentColor: Color(0xFFFF8DA1),
    ),
    ShopItem(
      id: 'chocolate',
      name: 'Porko Chocolate',
      description: 'Um tom aconchegante de chocolate belga.',
      category: CosmeticCategory.skin,
      price: 500,
      icon: Icons.cookie_rounded,
      accentColor: Color(0xFF8D6E63),
    ),
    ShopItem(
      id: 'cyberpunk',
      name: 'Cyberpunk Neon',
      description: 'Cores elétricas de neon direto do futuro.',
      category: CosmeticCategory.skin,
      price: 1200,
      icon: Icons.electric_bolt_rounded,
      accentColor: Color(0xFFEC4899),
    ),
    ShopItem(
      id: 'golden',
      name: 'Porco Dourado Lendário',
      description: 'Brilho puro de ouro para mestres poupadores.',
      category: CosmeticCategory.skin,
      price: 3000,
      icon: Icons.star_rounded,
      accentColor: Color(0xFFFFD700),
    ),

    // --- CABEÇA ---
    ShopItem(
      id: 'hat_cap',
      name: 'Boné Street',
      description: 'Estilo urbano para o dia a dia.',
      category: CosmeticCategory.hat,
      price: 150,
      icon: Icons.sports_baseball_rounded,
      accentColor: Color(0xFF3B82F6),
    ),
    ShopItem(
      id: 'hat_glasses',
      name: 'Óculos Boss',
      description: 'Óculos escuros para quem poupa com classe.',
      category: CosmeticCategory.hat,
      price: 250,
      icon: Icons.visibility_rounded,
      accentColor: Color(0xFF10B981),
    ),
    ShopItem(
      id: 'hat_beanie',
      name: 'Gorro de Inverno',
      description: 'Quentinho e estiloso para dias frios.',
      category: CosmeticCategory.hat,
      price: 300,
      icon: Icons.cloud_rounded,
      accentColor: Color(0xFF06B6D4),
    ),
    ShopItem(
      id: 'hat_tophat',
      name: 'Cartola Elegante',
      description: 'Requinte para ocasiões especiais.',
      category: CosmeticCategory.hat,
      price: 600,
      icon: Icons.theater_comedy_rounded,
      accentColor: Color(0xFF8B5CF6),
    ),
    ShopItem(
      id: 'hat_crown',
      name: 'Coroa Real',
      description: 'Digna do rei das economias.',
      category: CosmeticCategory.hat,
      price: 2500,
      icon: Icons.workspace_premium_rounded,
      accentColor: Color(0xFFEAB308),
    ),

    // --- ROUPAS ---
    ShopItem(
      id: 'cloth_tshirt',
      name: 'Camiseta Padrão',
      description: 'Casual, leve e confortável.',
      category: CosmeticCategory.cloth,
      price: 100,
      icon: Icons.checkroom_rounded,
      accentColor: Color(0xFF10B981),
    ),
    ShopItem(
      id: 'cloth_bowtie',
      name: 'Gravata Borboleta',
      description: 'Elegância e simpatia inconfundíveis.',
      category: CosmeticCategory.cloth,
      price: 200,
      icon: Icons.style_rounded,
      accentColor: Color(0xFFEF4444),
    ),
    ShopItem(
      id: 'cloth_jacket',
      name: 'Jaqueta de Couro',
      description: 'Atitude rebelde e aventureira.',
      category: CosmeticCategory.cloth,
      price: 800,
      icon: Icons.shield_rounded,
      accentColor: Color(0xFF334155),
    ),
    ShopItem(
      id: 'cloth_cape',
      name: 'Manto de Herói',
      description: 'Para quem protege seu futuro financeiro.',
      category: CosmeticCategory.cloth,
      price: 1500,
      icon: Icons.auto_awesome_rounded,
      accentColor: Color(0xFFF97316),
    ),

    // --- CENÁRIOS ---
    ShopItem(
      id: 'backdrop_default',
      name: 'Quarto Minimalista',
      description: 'O cantinho clássico e tranquilo do Porko.',
      category: CosmeticCategory.backdrop,
      price: 0,
      icon: Icons.home_rounded,
      accentColor: Color(0xFF64748B),
    ),
    ShopItem(
      id: 'backdrop_park',
      name: 'Parque Ensolarado',
      description: 'Ar puro e grama verde para passear.',
      category: CosmeticCategory.backdrop,
      price: 350,
      icon: Icons.park_rounded,
      accentColor: Color(0xFF10B981),
    ),
    ShopItem(
      id: 'backdrop_beach',
      name: 'Praia Tropical',
      description: 'Sol, ondas e tranquilidade financeira.',
      category: CosmeticCategory.backdrop,
      price: 700,
      icon: Icons.beach_access_rounded,
      accentColor: Color(0xFFF59E0B),
    ),
    ShopItem(
      id: 'backdrop_city',
      name: 'Cidade Noturna',
      description: 'Luzes neon e arranha-céus reluzentes.',
      category: CosmeticCategory.backdrop,
      price: 1000,
      icon: Icons.location_city_rounded,
      accentColor: Color(0xFF8B5CF6),
    ),
  ];

  static List<ShopItem> getByCategory(CosmeticCategory category) {
    return allItems.where((item) => item.category == category).toList();
  }

  static ShopItem? findById(String id) {
    try {
      return allItems.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }
}
