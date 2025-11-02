import 'dart:io';
import 'dart:convert';

/// Generate comprehensive 3D product model metadata
class ProductMetadataGenerator {
  static void generateAllProductMetadata() {
    final products = [
      // Tops and T-Shirts
      _generateTshirtMetadata('tshirt_men_basic_white', 'Classic White T-Shirt'),
      _generateTshirtMetadata('tshirt_men_premium_navy', 'Premium Navy T-Shirt'),
      _generateBlouseMetadata('blouse_women_silk_red', 'Elegant Red Silk Blouse'),
      _generateBlouseMetadata('blouse_women_cotton_white', 'White Cotton Blouse'),
      
      // Dresses
      _generateDressMetadata('dress_women_formal_black', 'Formal Black Evening Dress'),
      _generateDressMetadata('dress_women_casual_floral', 'Casual Floral Summer Dress'),
      
      // Pants and Bottoms
      _generateJeansMetadata('jeans_men_classic_blue', 'Classic Blue Jeans'),
      _generateJeansMetadata('jeans_women_skinny_black', 'Black Skinny Jeans'),
      _generatePantsMetadata('pants_men_dress_gray', 'Gray Dress Pants'),
      _generateShortsMetadata('shorts_men_athletic_gray', 'Athletic Gray Shorts'),
      _generateShortsMetadata('shorts_women_denim_blue', 'Denim Blue Shorts'),
      
      // Outerwear
      _generateJacketMetadata('jacket_women_leather_brown', 'Brown Leather Jacket'),
      _generateCoatMetadata('coat_women_winter_beige', 'Beige Winter Coat'),
      _generateJacketMetadata('jacket_men_denim_blue', 'Blue Denim Jacket'),
      
      // Activewear
      _generateTankTopMetadata('tank_top_men_athletic_white', 'White Athletic Tank Top'),
      _generateLeggingsMetadata('leggings_women_black', 'Black Sports Leggings'),
      _generateHoodieMetadata('hoodie_unisex_gray', 'Gray Unisex Hoodie'),
    ];
    
    // Write all metadata files
    for (final product in products) {
      _writeMetadataFile(product);
    }
    
    print('Generated ${products.length} product metadata files');
  }
  
  static Map<String, dynamic> _generateTshirtMetadata(String id, String name) {
    return {
      "id": id,
      "name": name,
      "category": "tops",
      "gender": id.contains('men') ? "men" : "women",
      "subcategory": "casual",
      "description": "Comfortable cotton t-shirt for everyday wear.",
      "brand": "BasicWear",
      "price": 29.99,
      "available_sizes": ["XS", "S", "M", "L", "XL"],
      "materials": [
        {"material": "100% Cotton", "percentage": 100, "care": "Machine wash cold"}
      ],
      "3d_model": {
        "polygon_count": 25000,
        "texture_resolution": "2K",
        "animation_support": true
      },
      "fabric_properties": {
        "stiffness": 0.6,
        "stretch_factor": 1.1,
        "wrinkle_resistance": 0.7
      },
      "size_mb": 1.0,
      "vertices": 25000,
      "tags": ["casual", "cotton", "comfortable"]
    };
  }
  
  static Map<String, dynamic> _generateBlouseMetadata(String id, String name) {
    return {
      "id": id,
      "name": name,
      "category": "tops",
      "gender": "women",
      "subcategory": "formal",
      "description": "Elegant blouse perfect for professional and formal occasions.",
      "brand": "Professional",
      "price": 59.99,
      "available_sizes": ["XS", "S", "M", "L", "XL"],
      "materials": [
        {"material": "Silk Blend", "percentage": 70, "care": "Dry clean only"},
        {"material": "Cotton", "percentage": 30, "care": "Low heat iron"}
      ],
      "3d_model": {
        "polygon_count": 35000,
        "texture_resolution": "4K",
        "animation_support": true
      },
      "fabric_properties": {
        "stiffness": 0.4,
        "stretch_factor": 1.05,
        "wrinkle_resistance": 0.3
      },
      "size_mb": 1.4,
      "vertices": 35000,
      "tags": ["formal", "elegant", "professional"]
    };
  }
  
  static Map<String, dynamic> _generateDressMetadata(String id, String name) {
    return {
      "id": id,
      "name": name,
      "category": "dresses",
      "gender": "women",
      "subcategory": id.contains('formal') ? "formal" : "casual",
      "description": id.contains('formal') 
          ? "Elegant evening dress perfect for formal occasions."
          : "Flowing summer dress perfect for casual outings.",
      "brand": "Elegance",
      "price": id.contains('formal') ? 149.99 : 79.99,
      "available_sizes": ["XS", "S", "M", "L", "XL"],
      "materials": [
        {"material": "Polyester", "percentage": 60, "care": "Machine washable"},
        {"material": "Spandex", "percentage": 40, "care": "Low heat dry"}
      ],
      "3d_model": {
        "polygon_count": 55000,
        "texture_resolution": "2K",
        "animation_support": true,
        "optimizations": {"cloth_simulation": true}
      },
      "fabric_properties": {
        "stiffness": 0.3,
        "stretch_factor": 1.2,
        "wrinkle_resistance": 0.5,
        "drape_factor": 0.8
      },
      "size_mb": 1.9,
      "vertices": 55000,
      "tags": id.contains('formal') 
          ? ["formal", "elegant", "evening"]
          : ["casual", "flowing", "summer"]
    };
  }
  
  static Map<String, dynamic> _generateJeansMetadata(String id, String name) {
    return {
      "id": id,
      "name": name,
      "category": "pants",
      "gender": id.contains('men') ? "men" : "women",
      "subcategory": "casual",
      "description": "Classic denim jeans for everyday wear.",
      "brand": "DenimCo",
      "price": 79.99,
      "available_sizes": ["28", "30", "32", "34", "36"],
      "materials": [
        {"material": "Cotton", "percentage": 98, "care": "Machine wash"},
        {"material": "Elastane", "percentage": 2, "care": "Low heat dry"}
      ],
      "3d_model": {
        "polygon_count": 40000,
        "texture_resolution": "2K",
        "animation_support": true
      },
      "fabric_properties": {
        "stiffness": 0.7,
        "stretch_factor": 1.1,
        "wrinkle_resistance": 0.8
      },
      "size_mb": 1.3,
      "vertices": 40000,
      "tags": ["denim", "casual", "everyday"]
    };
  }
  
  static Map<String, dynamic> _generatePantsMetadata(String id, String name) {
    return {
      "id": id,
      "name": name,
      "category": "pants",
      "gender": "men",
      "subcategory": "formal",
      "description": "Professional dress pants for business occasions.",
      "brand": "Professional",
      "price": 89.99,
      "available_sizes": ["S", "M", "L", "XL"],
      "materials": [
        {"material": "Wool Blend", "percentage": 80, "care": "Dry clean"},
        {"material": "Polyester", "percentage": 20, "care": "Low heat iron"}
      ],
      "3d_model": {
        "polygon_count": 35000,
        "texture_resolution": "2K",
        "animation_support": true
      },
      "fabric_properties": {
        "stiffness": 0.8,
        "stretch_factor": 1.05,
        "wrinkle_resistance": 0.9
      },
      "size_mb": 1.2,
      "vertices": 35000,
      "tags": ["formal", "business", "professional"]
    };
  }
  
  static Map<String, dynamic> _generateShortsMetadata(String id, String name) {
    return {
      "id": id,
      "name": name,
      "category": "shorts",
      "gender": id.contains('men') ? "men" : "women",
      "subcategory": "casual",
      "description": id.contains('athletic') 
          ? "Athletic shorts for sports and exercise."
          : "Casual denim shorts for summer wear.",
      "brand": id.contains('athletic') ? "ActiveFit" : "DenimCo",
      "price": 39.99,
      "available_sizes": ["XS", "S", "M", "L", "XL"],
      "materials": id.contains('athletic')
          ? [
              {"material": "Polyester", "percentage": 90, "care": "Machine wash"},
              {"material": "Spandex", "percentage": 10, "care": "Air dry"}
            ]
          : [
              {"material": "Cotton", "percentage": 100, "care": "Machine wash"}
            ],
      "3d_model": {
        "polygon_count": 20000,
        "texture_resolution": "1K",
        "animation_support": true
      },
      "fabric_properties": {
        "stiffness": id.contains('athletic') ? 0.3 : 0.6,
        "stretch_factor": id.contains('athletic') ? 1.4 : 1.1,
        "wrinkle_resistance": 0.7
      },
      "size_mb": 0.8,
      "vertices": 20000,
      "tags": id.contains('athletic') 
          ? ["athletic", "sports", "moisture-wicking"]
          : ["casual", "summer", "denim"]
    };
  }
  
  static Map<String, dynamic> _generateJacketMetadata(String id, String name) {
    return {
      "id": id,
      "name": name,
      "category": "outerwear",
      "gender": id.contains('men') ? "men" : "women",
      "subcategory": id.contains('leather') ? "premium" : "casual",
      "description": id.contains('leather') 
          ? "Premium leather jacket with classic styling."
          : "Versatile denim jacket for casual wear.",
      "brand": id.contains('leather') ? "LeatherCraft" : "DenimCo",
      "price": id.contains('leather') ? 299.99 : 89.99,
      "available_sizes": ["S", "M", "L", "XL"],
      "materials": id.contains('leather')
          ? [
              {"material": "Genuine Leather", "percentage": 100, "care": "Professional cleaning"}
            ]
          : [
              {"material": "Denim", "percentage": 95, "care": "Machine wash"},
              {"material": "Cotton", "percentage": 5, "care": "Low heat iron"}
            ],
      "3d_model": {
        "polygon_count": 48000,
        "texture_resolution": id.contains('leather') ? "4K" : "2K",
        "animation_support": true
      },
      "fabric_properties": {
        "stiffness": id.contains('leather') ? 0.95 : 0.7,
        "stretch_factor": 1.02,
        "wrinkle_resistance": id.contains('leather') ? 1.0 : 0.8,
        "durability": 0.95
      },
      "size_mb": id.contains('leather') ? 2.2 : 1.5,
      "vertices": 48000,
      "tags": id.contains('leather') 
          ? ["leather", "premium", "classic"]
          : ["denim", "casual", "versatile"]
    };
  }
  
  static Map<String, dynamic> _generateCoatMetadata(String id, String name) {
    return {
      "id": id,
      "name": name,
      "category": "outerwear",
      "gender": "women",
      "subcategory": "winter",
      "description": "Warm and stylish winter coat for cold weather.",
      "brand": "WinterWear",
      "price": 199.99,
      "available_sizes": ["XS", "S", "M", "L", "XL"],
      "materials": [
        {"material": "Wool", "percentage": 70, "care": "Dry clean only"},
        {"material": "Polyester Lining", "percentage": 30, "care": "Machine wash"}
      ],
      "3d_model": {
        "polygon_count": 60000,
        "texture_resolution": "4K",
        "animation_support": true
      },
      "fabric_properties": {
        "stiffness": 0.8,
        "stretch_factor": 1.03,
        "wrinkle_resistance": 0.9,
        "warmth_factor": 0.95
      },
      "size_mb": 2.4,
      "vertices": 60000,
      "tags": ["winter", "warm", "cozy", "wool"]
    };
  }
  
  static Map<String, dynamic> _generateTankTopMetadata(String id, String name) {
    return {
      "id": id,
      "name": name,
      "category": "tops",
      "gender": "men",
      "subcategory": "athletic",
      "description": "Athletic tank top for workouts and exercise.",
      "brand": "ActiveFit",
      "price": 24.99,
      "available_sizes": ["S", "M", "L", "XL"],
      "materials": [
        {"material": "Polyester", "percentage": 90, "care": "Machine wash"},
        {"material": "Spandex", "percentage": 10, "care": "Air dry"}
      ],
      "3d_model": {
        "polygon_count": 22000,
        "texture_resolution": "1K",
        "animation_support": true
      },
      "fabric_properties": {
        "stiffness": 0.4,
        "stretch_factor": 1.3,
        "wrinkle_resistance": 0.9,
        "moisture_wicking": 0.9
      },
      "size_mb": 0.7,
      "vertices": 22000,
      "tags": ["athletic", "moisture-wicking", "stretch"]
    };
  }
  
  static Map<String, dynamic> _generateLeggingsMetadata(String id, String name) {
    return {
      "id": id,
      "name": name,
      "category": "activewear",
      "gender": "women",
      "subcategory": "athletic",
      "description": "High-performance leggings for workouts and yoga.",
      "brand": "ActiveFit",
      "price": 49.99,
      "available_sizes": ["XS", "S", "M", "L", "XL"],
      "materials": [
        {"material": "Polyester", "percentage": 85, "care": "Machine wash"},
        {"material": "Spandex", "percentage": 15, "care": "Air dry"}
      ],
      "3d_model": {
        "polygon_count": 30000,
        "texture_resolution": "2K",
        "animation_support": true
      },
      "fabric_properties": {
        "stiffness": 0.6,
        "stretch_factor": 1.5,
        "wrinkle_resistance": 1.0,
        "compression_factor": 0.9
      },
      "size_mb": 1.0,
      "vertices": 30000,
      "tags": ["athletic", "compression", "high-stretch", "yoga"]
    };
  }
  
  static Map<String, dynamic> _generateHoodieMetadata(String id, String name) {
    return {
      "id": id,
      "name": name,
      "category": "outerwear",
      "gender": "unisex",
      "subcategory": "casual",
      "description": "Comfortable hoodie for everyday wear.",
      "brand": "ComfortWear",
      "price": 69.99,
      "available_sizes": ["XS", "S", "M", "L", "XL", "XXL"],
      "materials": [
        {"material": "Cotton", "percentage": 80, "care": "Machine wash"},
        {"material": "Polyester", "percentage": 20, "care": "Low heat dry"}
      ],
      "3d_model": {
        "polygon_count": 38000,
        "texture_resolution": "2K",
        "animation_support": true
      },
      "fabric_properties": {
        "stiffness": 0.5,
        "stretch_factor": 1.2,
        "wrinkle_resistance": 0.8,
        "warmth_factor": 0.7
      },
      "size_mb": 1.4,
      "vertices": 38000,
      "tags": ["casual", "comfortable", "hoodie", "cozy"]
    };
  }
  
  static void _writeMetadataFile(Map<String, dynamic> metadata) {
    final directory = Directory('assets/products/3d/metadata');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    
    final file = File('${directory.path}/${metadata['id']}_metadata.json');
    final jsonString = JsonEncoder.withIndent('  ').convert(metadata);
    file.writeAsStringSync(jsonString);
  }
}

void main() {
  ProductMetadataGenerator.generateAllProductMetadata();
}