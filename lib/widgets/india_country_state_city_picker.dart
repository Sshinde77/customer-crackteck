import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class IndiaCountryStateCityPicker extends StatefulWidget {
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<String> onStateChanged;
  final ValueChanged<String> onCityChanged;

  final String? initialCountry;
  final String? initialState;
  final String? initialCity;

  final TextStyle? style;
  final Color? dropdownColor;

  const IndiaCountryStateCityPicker({
    super.key,
    required this.onCountryChanged,
    required this.onStateChanged,
    required this.onCityChanged,
    this.initialCountry,
    this.initialState,
    this.initialCity,
    this.style,
    this.dropdownColor,
  });

  @override
  State<IndiaCountryStateCityPicker> createState() => _IndiaCountryStateCityPickerState();
}

class _IndiaCountryStateCityPickerState extends State<IndiaCountryStateCityPicker> {
  static const String _dataAssetPath = 'packages/country_state_city_picker/lib/assets/country.json';

  bool _loading = true;
  List<_Country> _countries = const [];

  String? _country;
  String? _state;
  String? _city;

  List<String> get _stateItems {
    final selected = _countries.firstWhere(
      (c) => c.name == _country,
      orElse: () => const _Country(name: '', states: []),
    );
    return selected.states.map((s) => s.name).toList();
  }

  List<String> get _cityItems {
    final selectedCountry = _countries.firstWhere(
      (c) => c.name == _country,
      orElse: () => const _Country(name: '', states: []),
    );
    final selectedState = selectedCountry.states.firstWhere(
      (s) => s.name == _state,
      orElse: () => const _State(name: '', cities: []),
    );
    return selectedState.cities;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant IndiaCountryStateCityPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool initialChanged =
        oldWidget.initialCountry != widget.initialCountry ||
        oldWidget.initialState != widget.initialState ||
        oldWidget.initialCity != widget.initialCity;
    if (!initialChanged) return;
    if (_countries.isEmpty) return;
    _applyInitialSelection();
  }

  Future<void> _load() async {
    try {
      final jsonStr = await rootBundle.loadString(_dataAssetPath);
      final decoded = jsonDecode(jsonStr);
      final List<dynamic> list = decoded is List ? decoded : const [];
      final countries = list
          .whereType<Map<String, dynamic>>()
          .map(_Country.fromMap)
          .where((c) => c.name.trim().isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() {
        _countries = countries;
        _loading = false;
      });
      _applyInitialSelection();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _countries = const [];
        _loading = false;
      });
    }
  }

  void _applyInitialSelection() {
    final String desiredCountry = (widget.initialCountry ?? 'India').trim();
    final String? resolvedCountry = _countries.any((c) => c.name == desiredCountry)
        ? desiredCountry
        : (_countries.any((c) => c.name == 'India') ? 'India' : (_countries.isNotEmpty ? _countries.first.name : null));

    final List<String> possibleStates = resolvedCountry == null
        ? const []
        : _countries.firstWhere((c) => c.name == resolvedCountry).states.map((s) => s.name).toList();
    final String? desiredState = widget.initialState?.trim();
    final String? resolvedState = (desiredState != null && possibleStates.contains(desiredState)) ? desiredState : null;

    final List<String> possibleCities = (resolvedCountry != null && resolvedState != null)
        ? _countries
            .firstWhere((c) => c.name == resolvedCountry)
            .states
            .firstWhere((s) => s.name == resolvedState)
            .cities
        : const [];
    final String? desiredCity = widget.initialCity?.trim();
    final String? resolvedCity = (desiredCity != null && possibleCities.contains(desiredCity)) ? desiredCity : null;

    if (!mounted) return;
    setState(() {
      _country = resolvedCountry;
      _state = resolvedState;
      _city = resolvedCity;
    });

    if (resolvedCountry != null) widget.onCountryChanged(resolvedCountry);
    if (resolvedState != null) widget.onStateChanged(resolvedState);
    if (resolvedCity != null) widget.onCityChanged(resolvedCity);
  }

  void _setCountry(String? value) {
    if (value == null) return;
    setState(() {
      _country = value;
      _state = null;
      _city = null;
    });
    widget.onCountryChanged(value);
    widget.onStateChanged('');
    widget.onCityChanged('');
  }

  void _setState(String? value) {
    if (value == null) return;
    setState(() {
      _state = value;
      _city = null;
    });
    widget.onStateChanged(value);
    widget.onCityChanged('');
  }

  void _setCity(String? value) {
    if (value == null) return;
    setState(() => _city = value);
    widget.onCityChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    final countries = _countries.map((c) => c.name).toList();
    final states = _stateItems;
    final cities = _cityItems;

    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: _country,
          dropdownColor: widget.dropdownColor,
          isExpanded: true,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            hintText: 'Choose Country',
          ),
          items: countries
              .map(
                (name) => DropdownMenuItem<String>(
                  value: name,
                  child: Text(name, style: widget.style),
                ),
              )
              .toList(),
          onChanged: _setCountry,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _state,
          dropdownColor: widget.dropdownColor,
          isExpanded: true,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            hintText: 'Choose State',
          ),
          items: states
              .map(
                (name) => DropdownMenuItem<String>(
                  value: name,
                  child: Text(name, style: widget.style),
                ),
              )
              .toList(),
          onChanged: states.isEmpty ? null : _setState,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _city,
          dropdownColor: widget.dropdownColor,
          isExpanded: true,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            hintText: 'Choose City',
          ),
          items: cities
              .map(
                (name) => DropdownMenuItem<String>(
                  value: name,
                  child: Text(name, style: widget.style),
                ),
              )
              .toList(),
          onChanged: cities.isEmpty ? null : _setCity,
        ),
      ],
    );
  }
}

class _Country {
  final String name;
  final List<_State> states;

  const _Country({required this.name, required this.states});

  factory _Country.fromMap(Map<String, dynamic> map) {
    final name = (map['name'] ?? '').toString();
    final dynamic rawStates = map['state'];
    final List<_State> states = rawStates is List
        ? rawStates.whereType<Map<String, dynamic>>().map(_State.fromMap).where((s) => s.name.trim().isNotEmpty).toList()
        : const [];
    return _Country(name: name, states: states);
  }
}

class _State {
  final String name;
  final List<String> cities;

  const _State({required this.name, required this.cities});

  factory _State.fromMap(Map<String, dynamic> map) {
    final name = (map['name'] ?? '').toString();
    final dynamic rawCities = map['city'];
    final List<String> cities = rawCities is List
        ? rawCities.map((c) => (c is Map<String, dynamic> ? c['name'] : c).toString()).where((s) => s.trim().isNotEmpty).toList()
        : const [];
    return _State(name: name, cities: cities);
  }
}

