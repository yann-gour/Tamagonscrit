import 'package:flutter/material.dart';

class ColorPickerDialog extends StatefulWidget {
  final String title;
  final Color initialColor;
  final List<Color> presetColors;

  const ColorPickerDialog({
    super.key,
    required this.title,
    required this.initialColor,
    required this.presetColors,
  });

  static Future<Color?> show({
    required BuildContext context,
    required String title,
    required Color initialColor,
    required List<Color> presetColors,
  }) {
    return showDialog<Color>(
      context: context,
      builder: (context) => ColorPickerDialog(
        title: title,
        initialColor: initialColor,
        presetColors: presetColors,
      ),
    );
  }

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> with SingleTickerProviderStateMixin {
  late Color _currentColor;
  late HSVColor _hsvColor;
  late TextEditingController _hexController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
    _hsvColor = HSVColor.fromColor(widget.initialColor);
    _hexController = TextEditingController(text: _colorToHex(_currentColor));
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _hexController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    final hexStr = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${hexStr.substring(2, 8).toUpperCase()}';
  }

  void _updateFromHsv(HSVColor newHsv) {
    setState(() {
      _hsvColor = newHsv;
      _currentColor = newHsv.toColor();
      _hexController.text = _colorToHex(_currentColor);
    });
  }

  void _updateFromColor(Color newColor) {
    setState(() {
      _currentColor = newColor;
      _hsvColor = HSVColor.fromColor(newColor);
      _hexController.text = _colorToHex(newColor);
    });
  }

  void _onHexSubmitted(String val) {
    var hex = val.trim().replaceAll('#', '');
    if (hex.length == 6) {
      try {
        final intHex = int.parse('FF$hex', radix: 16);
        _updateFromColor(Color(intHex));
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      title: Row(
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _currentColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black26, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'Recommandées'),
                Tab(text: 'Roue & Libres'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Onglet 1 : Présélections
                  SingleChildScrollView(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: widget.presetColors.map((color) {
                        final isSelected = color.toARGB32() == _currentColor.toARGB32();
                        return GestureDetector(
                          onTap: () => _updateFromColor(color),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                                width: isSelected ? 3.5 : 1.5,
                              ),
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    size: 22,
                                    color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Onglet 2 : Sélecteur HSV / Teinte / Hex
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Teinte (Arc-en-ciel)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF0000),
                                Color(0xFFFFFF00),
                                Color(0xFF00FF00),
                                Color(0xFF00FFFF),
                                Color(0xFF0000FF),
                                Color(0xFFFF00FF),
                                Color(0xFFFF0000),
                              ],
                            ),
                          ),
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                          ),
                          child: Slider(
                            value: _hsvColor.hue,
                            min: 0.0,
                            max: 360.0,
                            onChanged: (newHue) {
                              _updateFromHsv(_hsvColor.withHue(newHue));
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Saturation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  Slider(
                                    value: _hsvColor.saturation,
                                    min: 0.0,
                                    max: 1.0,
                                    onChanged: (s) => _updateFromHsv(_hsvColor.withSaturation(s)),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Luminosité', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  Slider(
                                    value: _hsvColor.value,
                                    min: 0.0,
                                    max: 1.0,
                                    onChanged: (v) => _updateFromHsv(_hsvColor.withValue(v)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Code Hex : ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _hexController,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                onChanged: _onHexSubmitted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_currentColor),
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
