import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../constants/countries.dart';
import '../theme/web_theme.dart';

class CountrySelector extends StatefulWidget {
  final String? initialValue;
  final Function(String?) onCountrySelected;
  final String label;
  final String hint;

  const CountrySelector({
    super.key,
    this.initialValue,
    required this.onCountrySelected,
    this.label = 'Country',
    this.hint = 'Search for a country',
  });

  @override
  State<CountrySelector> createState() => _CountrySelectorState();
}

class _CountrySelectorState extends State<CountrySelector> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Country> _filteredCountries = Countries.all;
  Country? _selectedCountry;
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _selectedCountry = Countries.findByName(widget.initialValue!);
    }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredCountries = Countries.search(_searchController.text);
    });
  }

  void _toggleDropdown() {
    setState(() {
      _isDropdownOpen = !_isDropdownOpen;
      if (_isDropdownOpen) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _selectCountry(Country country) {
    setState(() {
      _selectedCountry = country;
      _isDropdownOpen = false;
      _searchController.clear();
      _filteredCountries = Countries.all;
    });
    widget.onCountrySelected(country.name);
  }

  void _clearSelection() {
    setState(() {
      _selectedCountry = null;
      _isDropdownOpen = false;
      _searchController.clear();
      _filteredCountries = Countries.all;
    });
    widget.onCountrySelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const Gap(8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _isDropdownOpen
                  ? WebTheme.primaryBlue
                  : Colors.grey.shade300,
              width: _isDropdownOpen ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Selected country display
              if (_selectedCountry != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        _selectedCountry!.flag,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Text(
                          _selectedCountry!.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _clearSelection,
                        icon: const Icon(Icons.clear, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

              // Search field and dropdown
              if (_isDropdownOpen || _selectedCountry == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: widget.hint,
                          prefixIcon: const Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onTap: () {
                          if (!_isDropdownOpen) {
                            setState(() {
                              _isDropdownOpen = true;
                            });
                          }
                        },
                      ),
                      if (_isDropdownOpen) ...[
                        const Gap(8),
                        const Divider(height: 1),
                        const Gap(8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredCountries.length,
                            itemBuilder: (context, index) {
                              final country = _filteredCountries[index];
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                leading: Text(
                                  country.flag,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                title: Text(
                                  country.name,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  country.code,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                onTap: () => _selectCountry(country),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // Dropdown toggle button
              if (_selectedCountry != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tap to change country',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      IconButton(
                        onPressed: _toggleDropdown,
                        icon: Icon(
                          _isDropdownOpen
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: WebTheme.primaryBlue,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

