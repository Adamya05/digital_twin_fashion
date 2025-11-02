import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../src/providers/closet_provider.dart';
import '../../src/models/closet_model.dart';

/// Advanced Filters and Sorting Screen for Closet Items
/// 
/// Provides comprehensive filtering options including:
/// - Category, brand, size, color filters
/// - Condition and favorite status filters
/// - Advanced sorting options
/// - Clear all filters functionality
class ClosetFiltersScreen extends ConsumerStatefulWidget {
  const ClosetFiltersScreen({super.key});

  @override
  ConsumerState<ClosetFiltersScreen> createState() => _ClosetFiltersScreenState();
}

class _ClosetFiltersScreenState extends ConsumerState<ClosetFiltersScreen> {
  // Local state for filters
  String _selectedCategory = '';
  String _selectedBrand = '';
  String _selectedSize = '';
  String _selectedColor = '';
  ItemCondition _selectedCondition = ItemCondition.newItem;
  bool _showOnlyFavorited = false;
  bool _showOnlyOnSale = false;
  bool _showOnlyInOutfits = false;
  String _sortBy = 'dateAdded';
  bool _sortAscending = false;

  // Filter options
  final List<String> _categories = [
    'All Categories',
    'Tops',
    'Bottoms',
    'Dresses',
    'Outerwear',
    'Shoes',
    'Accessories',
    'Activewear',
    'Formal Wear',
  ];

  final List<String> _brands = [
    'All Brands',
    'Zara',
    'H&M',
    'Uniqlo',
    'Mango',
    'Nike',
    'Adidas',
    'Levi\'s',
    'Gap',
    'Forever 21',
    'ASOS',
  ];

  final List<String> _sizes = [
    'All Sizes',
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
  ];

  final List<String> _colors = [
    'All Colors',
    'Black',
    'White',
    'Navy',
    'Blue',
    'Red',
    'Green',
    'Yellow',
    'Pink',
    'Purple',
    'Brown',
    'Gray',
    'Orange',
  ];

  final List<String> _sortOptions = [
    'dateAdded',
    'name',
    'price',
    'wearCount',
    'lastWorn',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentFilters();
  }

  void _loadCurrentFilters() {
    final closetProvider = ref.read(closetProvider);
    setState(() {
      _selectedCategory = closetProvider.selectedCategory;
      _selectedBrand = closetProvider.selectedBrand;
      _selectedSize = closetProvider.selectedSize;
      _selectedColor = closetProvider.selectedColor;
      _selectedCondition = closetProvider.selectedCondition;
      _showOnlyFavorited = closetProvider.showOnlyFavorited;
      _showOnlyOnSale = closetProvider.showOnlyOnSale;
      _showOnlyInOutfits = closetProvider.showOnlyInOutfits;
      _sortBy = closetProvider.sortBy;
      _sortAscending = closetProvider.sortAscending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter & Sort'),
        actions: [
          TextButton(
            onPressed: _clearAllFilters,
            child: const Text('Clear All'),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Column(
        children: [
          // Filter sections
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Filters Section
                  _buildSectionTitle('Basic Filters'),
                  const SizedBox(height: 16),
                  
                  _buildDropdownFilter(
                    'Category',
                    _selectedCategory,
                    _categories,
                    (value) {
                      setState(() {
                        _selectedCategory = value == 'All Categories' ? '' : value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildDropdownFilter(
                    'Brand',
                    _selectedBrand,
                    _brands,
                    (value) {
                      setState(() {
                        _selectedBrand = value == 'All Brands' ? '' : value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildDropdownFilter(
                    'Size',
                    _selectedSize,
                    _sizes,
                    (value) {
                      setState(() {
                        _selectedSize = value == 'All Sizes' ? '' : value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildDropdownFilter(
                    'Color',
                    _selectedColor,
                    _colors,
                    (value) {
                      setState(() {
                        _selectedColor = value == 'All Colors' ? '' : value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Item Status Filters
                  _buildSectionTitle('Item Status'),
                  const SizedBox(height: 16),
                  
                  _buildConditionFilter(),
                  
                  const SizedBox(height: 16),
                  
                  _buildCheckboxFilter('Show Only Favorited', _showOnlyFavorited, (value) {
                    setState(() {
                      _showOnlyFavorited = value;
                    });
                  }),
                  
                  const SizedBox(height: 8),
                  
                  _buildCheckboxFilter('Show Only On Sale', _showOnlyOnSale, (value) {
                    setState(() {
                      _showOnlyOnSale = value;
                    });
                  }),
                  
                  const SizedBox(height: 8),
                  
                  _buildCheckboxFilter('Show Only In Outfits', _showOnlyInOutfits, (value) {
                    setState(() {
                      _showOnlyInOutfits = value;
                    });
                  }),
                  
                  const SizedBox(height: 32),
                  
                  // Sorting Section
                  _buildSectionTitle('Sort By'),
                  const SizedBox(height: 16),
                  
                  _buildDropdownFilter(
                    'Sort Field',
                    _sortBy,
                    _sortOptions,
                    (value) {
                      setState(() {
                        _sortBy = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSortOrderSelector(),
                  
                  const SizedBox(height: 32),
                  
                  // Quick Filters
                  _buildSectionTitle('Quick Filters'),
                  const SizedBox(height: 16),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickFilterChip('Recently Added', Icons.new_releases, () {
                        _applyQuickFilter('recent');
                      }),
                      _buildQuickFilterChip('Most Worn', Icons.trending_up, () {
                        _applyQuickFilter('worn');
                      }),
                      _buildQuickFilterChip('Least Worn', Icons.trending_down, () {
                        _applyQuickFilter('least_worn');
                      }),
                      _buildQuickFilterChip('High Value', Icons.attach_money, () {
                        _applyQuickFilter('high_value');
                      }),
                      _buildQuickFilterChip('Old Items', Icons.history, () {
                        _applyQuickFilter('old');
                      }),
                      _buildQuickFilterChip('Favorites', Icons.favorite, () {
                        _applyQuickFilter('favorites');
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Apply/Cancel buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== UI BUILDERS ====================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDropdownFilter(
    String label,
    String currentValue,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          child: DropdownButtonFormField<String>(
            value: currentValue.isEmpty ? options.first : currentValue,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (value) => onChanged(value!),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item Condition',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ItemCondition.values.map((condition) {
            return FilterChip(
              label: Text(_getConditionLabel(condition)),
              selected: _selectedCondition == condition,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCondition = condition;
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCheckboxFilter(String label, bool value, Function(bool) onChanged) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: (newValue) => onChanged(newValue!),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSortOrderSelector() {
    return Row(
      children: [
        Text(
          'Sort Order',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Spacer(),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Desc')),
            ButtonSegment(value: true, label: Text('Asc')),
          ],
          selected: {_sortAscending},
          onSelectionChanged: (Set<bool> newSelection) {
            setState(() {
              _sortAscending = newSelection.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildQuickFilterChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
      onPressed: onTap,
    );
  }

  // ==================== FILTER HELPERS ====================

  String _getConditionLabel(ItemCondition condition) {
    switch (condition) {
      case ItemCondition.newItem:
        return 'New';
      case ItemCondition.excellent:
        return 'Excellent';
      case ItemCondition.good:
        return 'Good';
      case ItemCondition.fair:
        return 'Fair';
      case ItemCondition.poor:
        return 'Poor';
      case ItemCondition.wornOut:
        return 'Worn Out';
    }
  }

  void _applyQuickFilter(String filterType) {
    switch (filterType) {
      case 'recent':
        setState(() {
          _sortBy = 'dateAdded';
          _sortAscending = true;
          _showOnlyFavorited = false;
          _showOnlyOnSale = false;
          _showOnlyInOutfits = false;
        });
        break;
      case 'worn':
        setState(() {
          _sortBy = 'wearCount';
          _sortAscending = false;
        });
        break;
      case 'least_worn':
        setState(() {
          _sortBy = 'wearCount';
          _sortAscending = true;
        });
        break;
      case 'high_value':
        setState(() {
          _sortBy = 'price';
          _sortAscending = false;
        });
        break;
      case 'old':
        setState(() {
          _sortBy = 'dateAdded';
          _sortAscending = true;
        });
        break;
      case 'favorites':
        setState(() {
          _showOnlyFavorited = true;
        });
        break;
    }
  }

  void _applyFilters() {
    final closetProvider = ref.read(closetProvider.notifier);
    
    // Apply filters
    if (_selectedCategory.isNotEmpty) {
      closetProvider.setCategoryFilter(_selectedCategory);
    }
    
    if (_selectedBrand.isNotEmpty) {
      closetProvider.setBrandFilter(_selectedBrand);
    }
    
    if (_selectedSize.isNotEmpty) {
      // Size filter would need to be implemented in provider
    }
    
    if (_selectedColor.isNotEmpty) {
      // Color filter would need to be implemented in provider
    }
    
    closetProvider.setConditionFilter(_selectedCondition);
    
    if (_showOnlyFavorited) {
      closetProvider.toggleShowOnlyFavorited();
    }
    
    if (_showOnlyOnSale) {
      closetProvider.toggleShowOnlyOnSale();
    }
    
    if (_showOnlyInOutfits) {
      closetProvider.toggleShowOnlyInOutfits();
    }
    
    closetProvider.setSorting(_sortBy, _sortAscending);
    
    Navigator.pop(context);
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategory = '';
      _selectedBrand = '';
      _selectedSize = '';
      _selectedColor = '';
      _selectedCondition = ItemCondition.newItem;
      _showOnlyFavorited = false;
      _showOnlyOnSale = false;
      _showOnlyInOutfits = false;
      _sortBy = 'dateAdded';
      _sortAscending = false;
    });
  }
}